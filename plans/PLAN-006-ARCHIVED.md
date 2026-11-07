# PLAN-006 — Stack `zennotes` (notas Markdown self-hosted)

## Objetivo
Migrar el `docker-compose.yml` de `zennotes` a quadlets en este repo, respetando las convenciones (11 secciones canónicas, `EnvironmentFile` para config no secreta, `Secret=…,type=env,target=…`, labels Traefik normalizadas). Se sirve en el dominio raíz `${FQDN}`.

## Contexto verificado
- Imagen `adibhanna/zennotes:latest` (ZenNotes: notas Markdown en ficheros `.md`, servidor Go; imagen **scratch**).
- Puerto `7878`. Usuario por defecto de la imagen `65532:65532`; el compose lo sobreescribe a `1000:1000 `.
- La imagen declara volúmenes `/workspace` y `/data` (no existen en el filesystem) → se usan volúmenes nombrados.
- La imagen publicada **NO** trae HEALTHCHECK (aunque el Dockerfile de `main` sí) → se define uno explícito en **exec-form** `/zennotes-server healthcheck` (la imagen scratch no tiene shell). Verificado: queda `healthy `.
- Token obligatorio (`ZENNOTES_AUTH_TOKEN`): el servidor bindea `0.0.0.0` y no arranca sin token.

## Ficheros a crear
1. `.config/containers/available/zennotes/zennotes.container`
2. `.config/containers/available/zennotes/zennotes-vault.volume`
3. `.config/containers/available/zennotes/zennotes-data.volume`
4. `.config/zennotes/zennotes.env`
5. `docs/zennotes.md`
6. `plans/PLAN-006.md` (este fichero)

## Decisiones compose → quadlet
| compose | quadlet |
|---|---|
| `image: adibhanna/zennotes:latest` | `Image=docker.io/adibhanna/zennotes:latest` |
| `init: true` | `PodmanArgs=--init` |
| `restart: unless-stopped` | `Restart=always` |
| `user: 1000:1000` | `User=1000:1000` (sección Hardening) |
| `ZENNOTES_AUTH_TOKEN` | `Secret=zennotes_auth_token,type=env,target=ZENNOTES_AUTH_TOKEN` |
| `ZENNOTES_VAULT_PATH/CONFIG_PATH/BEHIND_TLS/PERSIST_SESSIONS` | `.config/zennotes/zennotes.env` + `EnvironmentFile` |
| `vault:/workspace` | `Volume=zennotes-vault.volume:/workspace:Z` |
| `data:/data` | `Volume=zennotes-data.volume:/data:Z` |
| `networks: proxy (external)` | `Network=proxy.network` |
| labels: entrypoints `https`, `Host(${FQDN})` | router `websecure` + `tls.certresolver=letsencrypt` + `middlewares=seguridadHeaders@file,compresionHeaders@file`, `Host(`${FQDN}`)` |
| healthcheck (la imagen no publica) | `HealthCmd=["/zennotes-server","healthcheck"]` (exec-form) |

## Tareas
- [x] Crear `zennotes.container` con las 11 secciones canónicas (secret, EnvironmentFile, labels normalizadas, `User=1000:1000`).
- [x] Crear `zennotes-vault.volume` y `zennotes-data.volume`.
- [x] Crear `.config/zennotes/zennotes.env`.
- [x] Validar render con `/usr/lib/podman/quadlet -user -dryrun `.
- [x] Crear `docs/zennotes.md`.
- [x] Cerrar: renombrar a `plans/PLAN-006-ARCHIVED.md `.

## Follow-ups
- Crear el secreto ANTES de arrancar (NUNCA `crypta store`): `printf '%s' "$(openssl rand -hex 32)" | podman secret create zennotes_auth_token - `.
- Habilitar: `cd .config/containers/available/zennotes && qctl install` + `systemctl --user daemon-reload `.
- `ZENNOTES_PERSIST_SESSIONS` viene del compose; si el binario no lo lee, es inocuo.