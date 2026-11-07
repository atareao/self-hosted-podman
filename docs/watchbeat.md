# watchbeat — monitor de uptime self-hosted

## Qué es

`watchbeat` (`atareao/watchbeat`) es un monitor de uptime self-hosted escrito en Rust/Axum con frontend React. Comprueba endpoints periódicamente, guarda el historial en SQLite y notifica caídas (Telegram, Matrix, ntfy, webhook, Slack, Discord, Email, Gotify, configurados desde la UI). Se despliega como un único contenedor tras Traefik en la red `proxy`, servido en el dominio raíz `${FQDN}` en el puerto `3055`. La autenticación OIDC es **obligatoria**.

## Ficheros

- Quadlet: `.config/containers/available/watchbeat/watchbeat.container`
- Volumen: `.config/containers/available/watchbeat/watchbeat-data.volume` (`VolumeName=watchbeat-data`)
- Config no secreta: `.config/watchbeat/watchbeat.env` (+ `.env.local` para ajustes máquina, gitignored)
- Secreto Podman: `watchbeat_oidc_client_secret` (inyectado como `OIDC_CLIENT_SECRET`)

## Cómo funciona

- **Acceso al daemon**: el contenedor no necesita socket externo; corre con `uid/gid 1000` de la imagen.
- **Persistencia**: el volumen nombrado `watchbeat-data` se monta en `/app/data:Z`; SQLite en `/app/data/watchbeat.db`.
- **Configuración**: recibe por `EnvironmentFile` los archivos `.env` versionados y de máquina local; el secreto `OIDC_CLIENT_SECRET` se inyecta con `Secret=…`; la variable `OIDC_REDIRECT_URL` se fija en el quadlet con `${FQDN}`.
- **Healthcheck**: `wget --no-verbose --tries=1 --spider http://localhost:3055/health || exit 1` (endpoint público, sin auth).
- **Enrutado**: router `watchbeat` con `Host(`${FQDN}`)`, `entrypoints=websecure`, `tls.certresolver=letsencrypt` y los middlewares `seguridadHeaders` y `compresionHeaders`. Arranque **fail‑closed**: hace discovery OIDC al inicio y no arranca si falla.

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `HOST` | `.config/watchbeat/watchbeat.env` | `0.0.0.0` | IP de escucha |
| `PORT` | `.config/watchbeat/watchbeat.env` | `3055` | Puerto HTTP |
| `DATA_DIR` | `.config/watchbeat/watchbeat.env` | `/app/data` | Directorio de datos |
| `DATABASE_URL` | `.config/watchbeat/watchbeat.env` | `/app/data/watchbeat.db` | Ruta a SQLite |
| `TIMEZONE` | `.config/watchbeat/watchbeat.env` | `Europe/Madrid` | Zona horaria |
| `RUST_LOG` | `.config/watchbeat/watchbeat.env` | `info` | Nivel de logs |
| `LOG_FORMAT` | `.config/watchbeat/watchbeat.env` | `pretty` | Formato de logs |
| `WATCHBEAT_RETENTION_DAYS` | `.config/watchbeat/watchbeat.env` | `30` | Retención de checkpoints |
| `OIDC_ISSUER_URL` | `.config/watchbeat/watchbeat.env` | `https://auth.example.com` | URL OIDC issuer |
| `OIDC_CLIENT_ID` | `.config/watchbeat/watchbeat.env` | `watchbeat` | Client ID OIDC |
| `OIDC_CLIENT_SECRET` | secreto Podman `watchbeat_oidc_client_secret` | — | Secreto OIDC |
| `OIDC_REDIRECT_URL` | fijo en el quadlet | `https://${FQDN}/auth/callback` | Callback OIDC |

## Habilitar / desplegar

```fish
# 1. Crear el secreto ANTES de arrancar (NUNCA con crypta store)
printf '%s' '<client-secret>' | podman secret create watchbeat_oidc_client_secret -

# 2. Ajustar OIDC_ISSUER_URL / OIDC_CLIENT_ID reales en .config/watchbeat/watchbeat.env.local

# 3. Enlazar y recargar
cd .config/containers/available/watchbeat
qctl install
systemctl --user daemon-reload
```

Verificar con `systemctl --user status watchbeat` o `journalctl --user -u watchbeat`.

## Decisiones de migración (compose → quadlet)

| Compose | Quadlet |
|---|---|
| `image: atareao/watchbeat` | `Image=docker.io/atareao/watchbeat:latest` |
| `init: true` | `PodmanArgs=--init` |
| `restart: unless-stopped` | `Restart=always` |
| `watchbeat_data:/app/data:Z` | `Volume=watchbeat-data.volume:/app/data:Z` |
| `secreto OIDC` | `Secret=watchbeat_oidc_client_secret,type=env,target=OIDC_CLIENT_SECRET` |
| Labels normalizados a websecure + certresolver + middlewares | `traefik.http.routers.watchbeat` etc. |
| Healthcheck con `wget --spider` | `HealthCmd=...` |
| No `ExecStartPost` por retraso en arranque | - |

## Follow-ups

- OIDC obligatorio debe estar disponible al arranque.
- Los noticadores se configuran en la UI, no con variables de entorno.
- No se utiliza `ExecStartPost` para evitar retraso en el inicio de la unidad.
