# tick — Stack de monitorización (Grafana + InfluxDB + Telegraf)

## Qué es

Stack TICK para monitorización: visualización (Grafana), almacenamiento de series temporales (InfluxDB) y recolección de métricas (Telegraf). Son **3 contenedores** que comparten la red interna `tick.network`:

| Contenedor (`ContainerName=`) | Imagen (`Image=`) | Rol |
|---|---|---|
| `tick-grafana` | `docker.io/grafana/grafana` | Visualización; punto de entrada vía Traefik |
| `tick-influxdb` | `docker.io/library/influxdb:2.7` | Base de datos de series temporales (2.x) |
| `tick-telegraf` | `docker.io/library/telegraf:latest` | Recolector de métricas (host + socket de Podman) |

- **Red(es):** `tick.network` (interna del stack, `NetworkName=tick`) para los tres contenedores; `tick-grafana` e `tick-influxdb` se unen además a `proxy.network`.
- **Dominios:** `tick.${FQDN}` (Grafana) e `influxdb.${FQDN}` (InfluxDB). Routers `tick-grafana` y `tick-influxdb`.
- **Puertos internos (Traefik):** `3000` (`traefik.http.services.tick-grafana.loadbalancer.server.port=3000`) e `8086` (`traefik.http.services.tick-influxdb.loadbalancer.server.port=8086`).
- No hay `PublishPort`: el acceso es solo vía Traefik.

## Ficheros

- Quadlet(s):
  - `.config/containers/available/tick/tick-grafana.container`
  - `.config/containers/available/tick/tick-influxdb.container`
  - `.config/containers/available/tick/tick-telegraf.container`
- Volumen(es):
  - `.config/containers/available/tick/tick-grafana.volume`
  - `.config/containers/available/tick/tick-influxdb.volume`
- Red(es): `.config/containers/available/tick/tick.network` (+ `proxy.network`, definida en el stack `traefik`)
- Config no secreta: `.config/tick/tick.env` (versionada) + `.config/tick/tick.env.local` (gitignored, la crea el hook `post_pull`).
- Fichero de config montado: `%h/.config/tick/telegraf.conf` → `/etc/telegraf/telegraf.conf` (bind mount, `:ro,Z`).
- Secretos: `influxdb_admin_password`, `influxdb_admin_token`.

## Cómo funciona

- **Redes:** `tick.network` aísla la comunicación interna (Telegraf → InfluxDB → Grafana). `tick-grafana` e `tick-influxdb` añaden `proxy.network` para que Traefik los alcance; `tick-telegraf` se queda solo en `tick.network` (no se publica).
- **Enrutado Traefik:** cada servicio web expone su router en su propio host:
  - `tick-grafana`: servicio `tick-grafana` puerto `3000`, router `tick-grafana` → `Host(\`tick.${FQDN}\`)`, `websecure`, `letsencrypt`, middlewares `seguridadHeaders@file,compresionHeaders@file`.
  - `tick-influxdb`: servicio `tick-influxdb` puerto `8086`, router `tick-influxdb` → `Host(\`influxdb.${FQDN}\`)`, mismos entrypoint/TLS/middlewares.
- **Volúmenes:** `tick-grafana.volume` → `/var/lib/grafana` (dashboards, BD interna, plugins) y `tick-influxdb.volume` → `/var/lib/influxdb2` (datos de series temporales; ruta de InfluxDB 2.x).
- **Setup inicial de InfluxDB 2.x:** `DOCKER_INFLUXDB_INIT_MODE=setup` crea organización, bucket, usuario admin y token en el primer arranque. Los valores de `ORG`/`BUCKET`/`USERNAME` vienen de `tick.env`; `PASSWORD` y `ADMIN_TOKEN` se inyectan con `Secret=influxdb_admin_password` / `influxdb_admin_token`. Una vez creado el volumen, cambiar ORG/BUCKET **no** tiene efecto: hay que recrear el volumen.
- **Volúmenes de Telegraf (bind mounts de solo lectura):** `%h/.config/tick/telegraf.conf` → `/etc/telegraf/telegraf.conf`; `%t/podman/podman.sock` → `/var/run/docker.sock`; `/sys` → `/host/sys`; `/proc` → `/host/proc`; `/etc` → `/host/etc`. El socket de Podman permite a Telegraf recoger métricas de contenedores; los directorios del host (con `HOST_PROC`/`HOST_SYS`/`HOST_ETC`) permiten métricas del sistema anfitrión.
- **Interpolación de `telegraf.conf`:** Telegraf sustituye `${VAR}` desde el entorno del contenedor: `DOCKER_INFLUXDB_INIT_ORG`/`_BUCKET` desde `tick.env` y `DOCKER_INFLUXDB_INIT_ADMIN_TOKEN` desde el secreto. El token nunca se escribe en el fichero.
- **EnvironmentFile:** los tres units cargan `tick.env` y después `tick.env.local` (el segundo sobreescribe al primero).
- **Healthchecks:** `tick-grafana` → `wget --spider http://127.0.0.1:3000/api/health`; `tick-influxdb` → `influx ping --host http://127.0.0.1:8086`; `tick-telegraf` → `pgrep -x telegraf`.
- **Hardening:** solo `tick-grafana` declara `User=1000:1000`. InfluxDB y Telegraf no tienen `Hardening` (Telegraf corre además con acceso a socket y rutas del host).
- **AutoUpdate:** los tres usan `AutoUpdate=registry`.
- **Arranque:** `tick-grafana` y `tick-influxdb` con `After=network-online.target traefik.service`; `tick-telegraf` con `After=network-online.target tick-influxdb.service` y `Requires=tick-influxdb.service`. Los tres: `Restart=always`, `RestartSec=10s`, `StartLimitIntervalSec=300` y `StartLimitBurst=3` (van en `[Unit]`), `TimeoutStartSec=60`, `WantedBy=default.target`, `PodmanArgs=--init` (ninguna imagen es LinuxServer).

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `DOCKER_INFLUXDB_INIT_MODE` | `tick-influxdb.container` (`Environment=`) | `setup` | Ejecuta el bootstrap de InfluxDB 2.x en el primer arranque |
| `DOCKER_INFLUXDB_INIT_RETENTION` | `tick-influxdb.container` (`Environment=`) | `30d` | Retención del bucket inicial |
| `DOCKER_INFLUXDB_INIT_USERNAME` | `.config/tick/tick.env` | `admin` | Usuario admin inicial |
| `DOCKER_INFLUXDB_INIT_ORG` | `.config/tick/tick.env` | `atareao` | Organización inicial (inmutable tras el setup) |
| `DOCKER_INFLUXDB_INIT_BUCKET` | `.config/tick/tick.env` | `telegraf` | Bucket inicial (inmutable tras el setup) |
| `DOCKER_INFLUXDB_INIT_PASSWORD` | `tick-influxdb.container` (`Secret=influxdb_admin_password`) | *(secreto)* | Password del admin inicial |
| `DOCKER_INFLUXDB_INIT_ADMIN_TOKEN` | `tick-influxdb.container` y `tick-telegraf.container` (`Secret=influxdb_admin_token`) | *(secreto)* | Token de API (mismo secreto para escritura de Telegraf) |
| `HOST_PROC` | `tick-telegraf.container` (`Environment=`) | `/host/proc` | Ruta del `/proc` del host dentro del contenedor |
| `HOST_SYS` | `tick-telegraf.container` (`Environment=`) | `/host/sys` | Ruta del `/sys` del host dentro del contenedor |
| `HOST_ETC` | `tick-telegraf.container` (`Environment=`) | `/host/etc` | Ruta del `/etc` del host dentro del contenedor |
| `FQDN` | `tick-grafana.container` / `tick-influxdb.container` (labels de router) | *(inyectada por systemd desde `~/.config/environment.d/fqdn.conf`)* | Dominio base; `tick-grafana` usa `tick.${FQDN}` y `tick-influxdb` usa `influxdb.${FQDN}` |

## Cómo habilitar / desplegar

1. Crear los secretos (NUNCA `crypta store`):
   ```bash
   openssl rand -base64 24 | tr -d '\n' | podman secret create influxdb_admin_password -
   openssl rand -hex 32 | podman secret create influxdb_admin_token -
   ```
   El token generado es el que usará Telegraf: no hay que copiarlo a ningún `.env`.
2. Comprobar que existe `~/.config/tick/tick.env.local` (lo crea `post_pull`; si no, `touch ~/.config/tick/tick.env.local`).
3. `cd .config/containers/available/tick && qctl install`
4. `systemctl --user daemon-reload`
5. `systemctl --user start tick-influxdb tick-telegraf tick-grafana` (o `systemctl --user start tick.target` si se usa).

## Follow-ups

- Colisión de routers resuelta en PLAN-023: routers/servicios renombrados a `tick-grafana`/`tick-influxdb` (evita el nombre global `grafana` compartido con `grafana-influx-telegraf`) e InfluxDB movido a `influxdb.${FQDN}`.
- Telegraf monta `podman.sock` y rutas del host (`/proc`, `/sys`, `/etc`) en solo lectura; es funcionalmente necesario pero amplía la superficie de exposición. No tiene `NoNewPrivileges` ni `User`.
- **Grafana sin credenciales configuradas:** el `tick.env` original traía `GF_SECURITY_ADMIN_USER`/`GF_SECURITY_ADMIN_PASSWORD`, que no se migraron (no son config pública). Grafana arranca con `admin/admin`; pendiente crear `Secret=grafana_admin_password,type=env,target=GF_SECURITY_ADMIN_PASSWORD`.
- **`User=1000:1000` en `tick-grafana`:** riesgo conocido. El volumen `tick-grafana.volume` se crea como root y Grafana corre como uid 1000; en rootless el mapeo suele funcionar, pero si aparecen errores de permisos en `/var/lib/grafana` hay que revisar el propietario del volumen (no se ha cambiado).
- `tick-telegraf` usa `telegraf:latest` sin pin de versión (solo InfluxDB se ha fijado a `2.7`).
- **`tick-telegraf` corre con `User=telegraf` + `PodmanArgs=--init --group-add keep-groups`:** con `User=telegraf` el entrypoint de `telegraf:latest` (1.40.3) hace `if [ $EUID -ne 0 ]; then exec "$@"; fi`, así que no ejecuta `setcap` ni `setpriv` (y por eso ya no hacen falta `cap_net_raw` ni `cap_net_bind_service`). `--group-add keep-groups` hace que el proceso conserve los grupos suplementarios del host y pueda leer el socket de Podman (`%t/podman/podman.sock`, propiedad de `runner`); sin `keep-groups` el input `docker` falla con `permission denied`. El healthcheck usa `pgrep -x telegraf` (busybox de la imagen).
