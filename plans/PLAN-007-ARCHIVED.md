# PLAN-007 — Stack `watchbeat` (monitor de uptime self-hosted)

## Objetivo
Migrar el `docker-compose.yml` de `watchbeat` a quadlets en este repo, respetando las convenciones (11 secciones canónicas, `EnvironmentFile` para config no secreta, `Secret=…,type=env,target=…`, labels Traefik normalizadas). Se sirve en el dominio raíz `${FQDN}`.

## Contexto verificado
- Imagen `atareao/watchbeat:latest`: monitor de uptime self-hosted (Rust/Axum + React; runtime alpine). Puerto `3055`.
- Usuario del contenedor `app` (uid/gid 1000). SQLite en `/app/data/watchbeat.db`. **NO** necesita socket del daemon.
- `/health` es **público** (sin OIDC) → sirve de healthcheck (`wget --spider`).
- Arranque **fail-closed**: hace el discovery OIDC al inicio; si falla, el proceso NO arranca.
- Verificado en local: el volumen nombrado se escribe bien sin override de usuario (la imagen corre como `app`, uid 1000; el volumen vacío se chown-ea solo).

## Ficheros a crear
1. `.config/containers/available/watchbeat/watchbeat.container`
2. `.config/containers/available/watchbeat/watchbeat-data.volume`
3. `.config/watchbeat/watchbeat.env`
4. `docs/watchbeat.md`
5. `plans/PLAN-007.md` (este fichero)

## Decisiones compose → quadlet
| compose | quadlet |
|---|---|
| `image: atareao/watchbeat:latest` | `Image=docker.io/atareao/watchbeat:latest` |
| `init: true` | `PodmanArgs=--init` |
| `restart: unless-stopped` | `Restart=always` |
| `OIDC_CLIENT_SECRET` | `Secret=watchbeat_oidc_client_secret,type=env,target=OIDC_CLIENT_SECRET` |
| `HOST/PORT/DATA_DIR/DATABASE_URL/TIMEZONE/RUST_LOG/LOG_FORMAT/OIDC_ISSUER_URL/OIDC_CLIENT_ID` | `.config/watchbeat/watchbeat.env` + `EnvironmentFile` |
| `OIDC_REDIRECT_URL` | `Environment=OIDC_REDIRECT_URL=https://${FQDN}/auth/callback` |
| `watchbeat_data:/app/data` | `Volume=watchbeat-data.volume:/app/data:Z` |
| `networks: proxy (external)` | `Network=proxy.network` |
| labels `entrypoints https` + `Host(${FQDN})` (+ `app`/`description`/`maintainer`) | router `websecure` + `tls.certresolver=letsencrypt` + `middlewares=seguridadHeaders@file,compresionHeaders@file`, `Host(`${FQDN}`)`. Se DESCARTAN las labels decorativas `app`/`description`/`maintainer` (el repo solo usa labels de Traefik). |
| healthcheck `wget … --spider /health` | `HealthCmd=wget --no-verbose --tries=1 --spider http://localhost:3055/health || exit 1` (interval 300s) |

## Tareas
- [x] Crear `watchbeat.container` con las 11 secciones canónicas (secret OIDC, EnvironmentFile, labels normalizadas).
- [x] Crear `watchbeat-data.volume` (`VolumeName=watchbeat-data`).
- [x] Crear `.config/watchbeat/watchbeat.env`.
- [x] Validar render con `/usr/lib/podman/quadlet -user -dryrun`.
- [x] Crear `docs/watchbeat.md`.
- [x] Cerrar: renombrar a `plans/PLAN-007-ARCHIVED.md`.

## Follow-ups
- Crear el secreto ANTES de arrancar (NUNCA `crypta store`): `printf '%s' '<client-secret>' | podman secret create watchbeat_oidc_client_secret -`.
- Ajustar `OIDC_ISSUER_URL` / `OIDC_CLIENT_ID` reales en `watchbeat.env.local`; registrar en el proveedor OIDC la redirect URI exacta `https://<FQDN>/auth/callback`.
- Habilitar: `cd .config/containers/available/watchbeat && qctl install` + `systemctl --user daemon-reload`.
- Sin `ExecStartPost`: con `interval=300s` el primer healthcheck tarda 5 min y bloquearía el arranque.