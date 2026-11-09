# Headplane (UI web de Headscale)

Headplane es la interfaz web de [Headscale](https://github.com/juanfont/headscale): permite
gestionar usuarios, nodos, preauthkeys, DNS y rutas del tailnet desde el navegador. En este repo
se despliega **como un componente más del stack `headscale`** (no como stack independiente),
expuesta en el **mismo dominio bajo `/admin`**.

## Ficheros implicados

Nuevos:
- `.config/containers/available/headscale/headscale-headplane.container` — quadlet del componente.
- `.config/containers/available/headscale/headscale-headplane-data.volume` — volumen de datos.
- `.config/headplane/config.yaml.jinja` — plantilla de config (se renderiza a `config.yaml`).
- `.config/headplane/.gitignore` — ignora el `config.yaml` renderizado.
- `.config/headplane/headplane.env` — config no secreta del stack (`TZ`).

Modificados:
- `.config/containers/available/headscale/headscale.container` — `NetworkAlias=headscale`, label
  `me.tale.headplane.target=headscale` y middleware CORS en el router de headscale.

## Cómo funciona

- **Mismo dominio, dos routers Traefik** sobre `headscale.<FQDN>`:
  - `headscale@docker` → `headscale:8080` (regla `Host(...)`), todo el resto.
  - `headplane@docker` → `headplane:3000` (regla `Host(...)&&PathPrefix(`/admin`)`, `priority=100`).
- **HTTP/1.1 forzado en ambos routers** con `TLSOption headscale-http1@file` (mismo motivo que en
  headscale: el upgrade custom `tailscale-control-protocol` no se reenvía sobre HTTP/2).
- **Integración completa con Podman**: se monta `%t/podman/podman.sock:/var/run/docker.sock:ro` y
  el `config.yaml` de headscale (rw). Headplane detecta el contenedor de headscale por la label
  `me.tale.headplane.target=headscale` y puede editar sus ajustes de red/DNS desde la UI.
- **Cookie secret** como secreto de Podman `headplane_cookie_secret` (32 caracteres exactos),
  inyectado por entorno con `Secret=headplane_cookie_secret,type=env,target=HEADPLANE_SERVER__COOKIE_SECRET`
  y `HEADPLANE_LOAD_ENV_OVERRIDES=true`.

## Variables / config

`.config/headplane/headplane.env` (versionado):
- `TZ=Europe/Madrid`

`.config/headplane/config.yaml.jinja` (renderizado a `config.yaml`, **gitignored**):
- `server.base_path: /admin`, `server.base_url: https://headscale.{{ env.FQDN }}`,
  `cookie_secure: true`, `data_path: /var/lib/headplane`.
- `headscale.url: http://headscale:8080`, `config_path: /etc/headscale/config.yaml`.
- `integration.docker.enabled: true`, `container_label: me.tale.headplane.target=headscale`.

Secretos (crear con `podman secret create`, NUNCA con `crypta store`):
- `headplane_cookie_secret` → `openssl rand -hex 16 | podman secret create headplane_cookie_secret -`

## Cómo habilitar y desplegar

1. En el servidor (`runner`), renderizar la plantilla y crear el secreto:
   ```bash
   yadm pull   # ejecuta unjinja → genera ~/.config/headplane/config.yaml
   openssl rand -hex 16 | podman secret create headplane_cookie_secret -
   ```
2. Instalar y arrancar desde el directorio del stack:
   ```bash
   cd ~/.config/containers/available/headscale
   qctl install
   systemctl --user daemon-reload
   systemctl --user restart headscale headscale-headplane
   ```
3. Verificar:
   ```bash
   curl -sS -o /dev/null -w '%{http_code}\n' https://headscale.<FQDN>/admin/   # → 200
   curl -sS https://headscale.<FQDN>/health                                     # → {"status":"pass"}
   ```

## Uso: login en el UI

Headplane se autentica contra Headscale con una **API key**. Crearla:
```bash
podman exec headscale headscale apikeys create --expiration 90d
```
Copiar la clave resultante en la pantalla de login de `https://headscale.<FQDN>/admin/`.

## Decisión crítica: healthcheck desactivado

La imagen `ghcr.io/tale/headplane` es **distroless (sin shell)** pero trae un `HEALTHCHECK`
`CMD-SHELL /bin/hp_healthcheck`. En Podman 5.7 el `--health-cmd` con un array JSON de **un solo
elemento** NO se parsea como exec-form y cae a `CMD-SHELL` → al no haber shell, el healthcheck
devuelve **exit 125** y el contenedor queda `starting` para siempre. **Traefik NO registra el router
de un contenedor no-healthy** → `/admin` devolvía 404.

Solución adoptada: `HealthCmd=none` (desactiva el healthcheck heredado de la imagen). El servicio
sigue siendo supervisable por systemd (`Restart=always`). Notas aprendidas:
- Podman 5.7 solo interpreta `--health-cmd` como exec-form si el array JSON tiene **≥2 elementos**.
- Alternativa válida si se quisiera healthcheck activo: `HealthCmd=["/bin/hp_healthcheck","health"]`
  (el binario ignora args extra y devuelve 0). Se prefirió `none` por simplicidad.

## Gotchas

1. **`&&` sin espacios en la regla Traefik.** systemd parte el valor del `Label` de `ExecStart` por
   los espacios, así que `Host(...) && PathPrefix(...)` se truncaba a `Host(...)` (¡matchearía todo
   el host!). Escribir siempre `Host(...)&&PathPrefix(...)`.
2. **`Config.yaml` renderizado y gitignored**: solo existe en el host tras `yadm pull`.
3. **Reiniciar headscale desde la UI** usa la API Docker de Podman sobre un unit gestionado por
   systemd; puede provocar drift del estado del servicio.

## Desplegado en producción

Estado: **activo** en `new_atareao` (usuario `runner`).
Verificado:
- `https://headscale.<FQDN>/admin/` → 302 → `/admin/login` → 200, título «Headplane».
- `/admin/healthz` → 200.
- Logs: «Connected to Headscale 0.29.7», integración Docker detecta el contenedor `/headscale`.
- `https://headscale.<FQDN>/health` sigue `{"status":"pass"}` y `POST /ts2021` alcanza la ruta Noise.
