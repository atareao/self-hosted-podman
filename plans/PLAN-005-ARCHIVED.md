# PLAN-005 — Stack `apimail` (puente IMAP/SMTP → webhook)

## Objetivo
Migrar el `docker-compose.yml` de `apimail` a quadlets en este repo, respetando las convenciones (11 secciones canónicas, `EnvironmentFile` para config no secreta, `Secret=…,type=env,target=…`, labels Traefik normalizadas). Se sirve en `apimail.${FQDN}`.

## Contexto verificado
- Imagen `ghcr.io/atareao/apimail:latest`: puente IMAP/SMTP → webhook (Rust, TLS con rustls/webpki-roots).
- Puerto `3000`. Usuario del contenedor: `apimail` (uid 1000, gid 1000). **NO** necesita socket del daemon.
- `wget` (busybox) disponible → sirve de healthcheck. `/api/health` es público.
- Arranque **fail-closed**: obligatorios `APIMAIL_API_KEY` y host+user+password de IMAP y SMTP.
- El compose traía el dominio hardcodeado (`apimail.territoriolinux.es`) → se normaliza a `apimail.${FQDN}`.

## Ficheros a crear
1. `.config/containers/available/apimail/apimail.container`
2. `.config/containers/available/apimail/apimail-data.volume`
3. `.config/apimail/apimail.env` (config no secreta)
4. `docs/apimail.md`
5. `plans/PLAN-005.md` (este fichero)

## Decisiones compose → quadlet
| compose | quadlet |
|---|---|
| `image: ghcr.io/atareao/apimail:latest` | `Image=ghcr.io/atareao/apimail:latest` |
| `init: true` | `PodmanArgs=--init` |
| `restart: unless-stopped` | `Restart=always` |
| `APIMAIL_API_KEY` | `Secret=apimail_api_key,type=env,target=APIMAIL_API_KEY` |
| `APIMAIL_IMAP_PASSWORD` | `Secret=apimail_imap_password,type=env,target=APIMAIL_IMAP_PASSWORD` |
| `APIMAIL_SMTP_PASSWORD` | `Secret=apimail_smtp_password,type=env,target=APIMAIL_SMTP_PASSWORD` |
| resto de `APIMAIL_*` (hosts, users, ports, TLS, límites, cola) | `.config/apimail/apimail.env` + `EnvironmentFile` |
| `apimail_data:/app/data` | `Volume=apimail-data.volume:/app/data:Z` |
| `networks: proxy (external)` | `Network=proxy.network` |
| labels: entrypoints `https`, `Host(apimail.territoriolinux.es)` | router `websecure` + `tls.certresolver=letsencrypt` + `middlewares=seguridadHeaders@file,compresionHeaders@file`, `Host(`apimail.${FQDN}`)` |
| healthcheck `wget -qO- …/api/health` | `HealthCmd=wget -qO- http://127.0.0.1:3000/api/health || exit 1` |

## Tareas
- [x] Crear `apimail.container` con las 11 secciones canónicas (3 secretos, EnvironmentFile, labels normalizadas).
- [x] Crear `apimail-data.volume` (`VolumeName=apimail-data`).
- [x] Crear `.config/apimail/apimail.env` con la config no secreta.
- [x] Validar render con `/usr/lib/podman/quadlet -user -dryrun`.
- [x] Crear `docs/apimail.md`.
- [x] Cerrar: renombrar a `plans/PLAN-005-ARCHIVED.md`.

## Follow-ups
- Crear los 3 secretos ANTES de arrancar (NUNCA `crypta store`): `printf '%s' '<valor>' | podman secret create apimail_api_key -` (idem `apimail_imap_password`, `apimail_sm9_password`).
- Rellenar hosts/usuarios IMAP y SMTP y `APIMAIL_WEBHOOK_URL` reales en `apimail.env.local`.
- Habilitar: `cd .config/containers/available/apimail && qctl install` + `systemctl --user daemon-reload`.