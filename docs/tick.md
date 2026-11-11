# tick — Stack de monitorización (Grafana + InfluxDB + Telegraf)

## Qué es

Stack TICK para monitorización: visualización (Grafana), almacenamiento de series temporales (InfluxDB) y recolección de métricas (Telegraf). Son **3 contenedores** que comparten la red interna `tick.network`:

| Contenedor (`ContainerName=`) | Imagen (`Image=`) | Rol |
|---|---|---|
| `tick-grafana` | `docker.io/grafana/grafana` | Visualización; punto de entrada vía Traefik |
| `tick-influxdb` | `docker.io/library/influxdb:latest` | Base de datos de series temporales |
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
- Config no secreta: no existe `.env` de stack (no hay `.config/tick/`).
- Fichero de config montado: `%h/.config/tick/telegraf.conf` → `/etc/telegraf/telegraf.conf` (bind mount, `:ro`).
- Secretos: ninguno (`Secret=` no declarado en ningún contenedor).

## Cómo funciona

- **Redes:** `tick.network` aísla la comunicación interna (Telegraf → InfluxDB → Grafana). `tick-grafana` e `tick-influxdb` añaden `proxy.network` para que Traefik los alcance; `tick-telegraf` se queda solo en `tick.network` (no se publica).
- **Enrutado Traefik:** cada servicio web expone su router en su propio host:
  - `tick-grafana`: servicio `tick-grafana` puerto `3000`, router `tick-grafana` → `Host(\`tick.${FQDN}\`)`, `websecure`, `letsencrypt`, middlewares `seguridadHeaders@file,compresionHeaders@file`.
  - `tick-influxdb`: servicio `tick-influxdb` puerto `8086`, router `tick-influxdb` → `Host(\`influxdb.${FQDN}\`)`, mismos entrypoint/TLS/middlewares.
- **Volúmenes:** `tick-grafana.volume` → `/var/lib/grafana` (dashboards, BD interna, plugins) y `tick-influxdb.volume` → `/var/lib/influxdb` (datos de series temporales).
- **Volúmenes de Telegraf (bind mounts de solo lectura):** `%h/.config/tick/telegraf.conf` → `/etc/telegraf/telegraf.conf`; `%t/podman/podman.sock` → `/var/run/docker.sock`; `/sys` → `/host/sys`; `/proc` → `/host/proc`; `/etc` → `/host/etc`. El socket de Podman permite a Telegraf recoger métricas de contenedores; los directorios del host (con `HOST_PROC`/`HOST_SYS`/`HOST_ETC`) permiten métricas del sistema anfitrión.
- **Secretos / EnvironmentFile:** no hay `Secret=` ni `EnvironmentFile`; la config no secreta de cada contenedor va como `Environment=` y la de Telegraf vive en el `telegraf.conf` montado.
- **Healthcheck:** ninguno de los tres define `Health*`.
- **Hardening:** solo `tick-grafana` declara `User=1000:1000`. InfluxDB y Telegraf no tienen `Hardening` (Telegraf corre además con acceso a socket y rutas del host).
- **AutoUpdate:** los tres usan `AutoUpdate=registry`.
- **Arranque:** `tick-grafana` y `tick-influxdb` con `After=network-online.target traefik.service`; `tick-telegraf` solo con `After=network-online.target`. Los tres: `Restart=always`, `RestartSec=10s`, `StartLimitIntervalSec=300`, `StartLimitBurst=3`, `TimeoutStartSec=60`, `WantedBy=default.target`. Ninguno usa `PodmanArgs=--init`.

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `HOST_PROC` | `tick-telegraf.container` (`Environment=`) | `/host/proc` | Ruta del `/proc` del host dentro del contenedor |
| `HOST_SYS` | `tick-telegraf.container` (`Environment=`) | `/host/sys` | Ruta del `/sys` del host dentro del contenedor |
| `HOST_ETC` | `tick-telegraf.container` (`Environment=`) | `/host/etc` | Ruta del `/etc` del host dentro del contenedor |
| `FQDN` | `tick-grafana.container` / `tick-influxdb.container` (labels de router) | *(inyectada por systemd desde `~/.config/environment.d/fqdn.conf`)* | Dominio base; `tick-grafana` usa `tick.${FQDN}` y `tick-influxdb` usa `influxdb.${FQDN}` |

No hay `.env` de stack para este servicio.

## Cómo habilitar / desplegar

1. No requiere secretos (no hay `Secret=`); sí requiere que exista el fichero de config de Telegraf en `~/.config/tick/telegraf.conf`.
2. `cd .config/containers/available/tick && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups

- Colisión de routers resuelta en PLAN-023: routers/servicios renombrados a `tick-grafana`/`tick-influxdb` (evita el nombre global `grafana` compartido con `grafana-influx-telegraf`) e InfluxDB movido a `influxdb.${FQDN}`.
- Telegraf monta `podman.sock` y rutas del host (`/proc`, `/sys`, `/etc`) en solo lectura; es funcionalmente necesario pero amplía la superficie de exposición. No tiene `NoNewPrivileges` ni `User`.
- `tick-influxdb` monta `/var/lib/influxdb` (ruta de InfluxDB 1.x); confirmar que la imagen `latest` (2.x) usa ese path.
- Sin healthchecks en ninguno de los tres contenedores.
- `tick-telegraf` no declara `After=`/`Requires=` sobre `tick-influxdb` ni `tick-grafana`: puede arrancar antes que el destino de sus métricas.
