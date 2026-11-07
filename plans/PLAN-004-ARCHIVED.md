# PLAN-004 — Stack `alloy` (dashboard de gestión Docker/Podman)

## Objetivo
Migrar el `docker-compose.yml` de `alloy` a quadlets en este repo, respetando las convenciones (11 secciones canónicas, `EnvironmentFile` para config no secreta, `Secret=…,type=env,target=…`, labels Traefik normalizadas). Alloy se sirve en el dominio raíz `${FQDN}`.

## Contexto verificado
- Imagen `docker.io/atareao/alloy:latest`: dashboard de gestión de contenedores (Rust/Axum + React).
- Puerto `3066`. Usuario del contenedor: `app` (uid 1000, gid 1000).
- Autenticación OIDC **obligatoria** (`OIDC_ISSUER_URL`, `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`, `OIDC_REDIRECT_URL`).
- `/api/health` es público (no requiere auth) → sirve como healthcheck.
- Gestiona el daemon vía socket (`DOCKER_HOST`).

## Ficheros a crear
1. `.config/containers/available/alloy/alloy.container`
2. `.config/containers/available/alloy/alloy-data.volume`
3. `.config/alloy/alloy.env` (config no secreta)
4. `docs/alloy.md`
5. `plans/PLAN-004.md` (este fichero)

## Decisiones compose → quadlet
| compose | quadlet |
|---|---|
| `image: atareao/alloy` | `Image=docker.io/atareao/alloy:latest` |
| `init: true` | `PodmanArgs=--init` |
| `restart: unless-stopped` | `Restart=always` |
| `group_add: "999"` (docker gid) | descartado: `UserNS=keep-id` da acceso al socket podman (gid 1000) |
| app corre como no-root (uid 1000) | `UserNS=keep-id` (uid 1000 contenedor = uid 1000 host) |
| `TIMEZONE`, `DOCKER_HOST`, `OIDC_ISSUER_URL`, `OIDC_CLIENT_ID` | `.config/alloy/alloy.env` + `EnvironmentFile` |
| `OIDC_CLIENT_SECRET` | `Secret=alloy_oidc_client_secret,type=env,target=OIDC_CLIENT_SECRET` |
| `OIDC_REDIRECT_URL=https://${FQDN}/api/auth/callback` | `Environment=OIDC_REDIRECT_URL=https://${FQDN}/api/auth/callback` |
| `/var/run/docker.sock:/var/run/docker.sock` | `Volume=%t/podman/podman.sock:/var/run/docker.sock:ro` |
| `data:/app/data` | `Volume=alloy-data.volume:/app/data:Z` |
| `networks: proxy (external)` | `Network=proxy.network` |
| labels: entrypoints `https`, `Host(${FQDN})` | router `websecure` + `tls.certresolver=letsencrypt` + `middlewares=seguridadHeaders@file,compresionHeaders@file`, `Host(`${FQDN}`)` |
| healthcheck (nuevo) | `wget -q --spider http://localhost:3066/api/health || exit 1` (busybox) |

## Tareas
- [x] Crear `alloy.container` con las 11 secciones canónicas (`UserNS=keep-id`, socket podman, secret OIDC, labels normalizadas).
- [x] Crear `alloy-data.volume` (`VolumeName=alloy-data`).
- [x] Crear `.config/alloy/alloy.env` con config no secreta (TIMEZONE, DOCKER_HOST, OIDC_ISSUER_URL, OIDC_CLIENT_ID).
- [x] Validar render con `/usr/lib/podman/quadlet -user -dryrun`.
- [x] Crear `docs/alloy.md`.
- [x] Cerrar: renombrar a `plans/PLAN-004-ARCHIVED.md`.

## Follow-ups
- Crear el secreto ANTES de arrancar: `printf '%s' '<client-secret>' | podman secret create alloy_oidc_client_secret -` (NUNCA `crypta store`).
- Ajustar `OIDC_ISSUER_URL` / `OIDC_CLIENT_ID` reales en `alloy.env.local`.
- Habilitar: `cd .config/containers/available/alloy && qctl install` + `systemctl --user daemon-reload`.