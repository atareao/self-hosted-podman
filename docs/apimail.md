# apimail — puente IMAP/SMTP → webhook

## Qué es

`apimail` (`ghcr.io/atareao/apimail`) es un contenedor que vigila un buzón IMAP con IDLE y notifica cada correo nuevo a un webhook HTTP. Además expone una API HTTP autenticada con `APIMAIL_API_KEY` para consultas internas. Se despliega tras Traefik en la red `proxy`, servido en el subdominio `apimail.${FQDN}` en el puerto `3000`.

## Ficheros

- Quadlet: `.config/containers/available/apimail/apimail.container`
- Volumen: `.config/containers/available/apimail/apimail-data.volume` (`VolumeName=apimail-data`)
- Config no secreta: `.config/apimail/apimail.env` (y `.env.local` para ajustes máquina‑específicos)
- Secretos Podman:
  - `apimail_api_key` → `APIMAIL_API_KEY`
  - `apimail_imap_password` → `APIMAIL_IMAP_PASSWORD`
  - `apimail_smtp_password` → `APIMAIL_SMTP_PASSWORD`

## Cómo funciona

- Un único contenedor sin necesidad de socket externo.
- Se monta el volumen **apimail-data** en `/app/data:Z`; la cola de envío de webhooks se persiste en `queue.jsonl` dentro de ese volumen.
- La configuración no secreta se carga con `EnvironmentFile` (`.env` + `.env.local`).
- Los secretos se inyectan mediante `Secret=`.
- Healthcheck: `wget -qO- http://127.0.0.1:3000/api/health || exit 1`.
- Traefik enruta con reglas `Host('apimail.${FQDN}')`, websecure, certresolver `letsencrypt` y middlewares `seguridadHeaders@file` y `compresionHeaders@file`.

## Variables y configuración

| Variable | Valor (ejemplo) | Descripción |
|---|---|---|
| `APIMAIL_HOST` | `0.0.0.0` | Destino de escucha | 
| `APIMAIL_PORT` | `3000` | Puerto de la API |
| `APIMAIL_IMAP_HOST` | `imap.example.com` | Host del buzón IMAP |
| `APIMAIL_IMAP_USER` | `user@example.com` | Usuario IMAP |
| `APIMAIL_IMAP_TLS` | `implicit` | Modo TLS (`implicit` o `starttls`) |
| `APIMAIL_IMAP_TIMEOUT_SECS` | `30` | Timeout IMAP |
| `APIMAIL_SMTP_HOST` | `smtp.example.com` | Host SMTP |
| `APIMAIL_SMTP_USER` | `user@example.com` | Usuario SMTP |
| `APIMAIL_SMTP_TLS` | `implicit` | Modo TLS SMTP |
| `APIMAIL_MAX_ATTACHMENT_BYTES` | `10485760` | Límite en bytes para archivos adjuntos |
| `APIMAIL_MAX_MESSAGE_BYTES` | `26214400` | Límite en bytes para mensajes |
| `APIMAIL_IDLE_MAILBOX` | `INBOX` | Buzón de escucha |
| `APIMAIL_WEBHOOK_TIMEOUT_SECS` | `10` | Timeout de webhook |
| `APIMAIL_QUEUE_PATH` | `/app/data/queue.jsonl` | Ruta de la cola durable |
| `APIMAIL_QUEUE_MAX_ITEMS` | `1000` | Máximo de ítems en cola |
| `APIMAIL_QUEUE_MAX_BYTES` | `67108864` | Máximo de bytes en cola |
| `APIMAIL_API_KEY` | *secreto* | Clave de autenticación de API |
| `APIMAIL_IMAP_PASSWORD` | *secreto* | Contraseña IMAP |
| `APIMAIL_SMTP_PASSWORD` | *secreto* | Contraseña SMTP |

## Cómo habilitar / desplegar

1. Crear los secretos antes de arrancar (NUNCA con `crypta store`):
   ```bash
   printf '%s' "tu_api_key" | podman secret create apimail_api_key -
   printf '%s' "imap_password" | podman secret create apimail_imap_password -
   printf '%s' "smtp_password" | podman secret create apimail_smtp_password -
   ```
2. Ajustar las configuraciones de IMAP, SMTP y `APIMAIL_WEBHOOK_URL` en `.config/apimail/apimail.env.local`.
3. Instalar la stack y recargar el daemon de systemd:
   ```bash
   cd .config/containers/available/apimail
   qctl install
   systemctl --user daemon-reload
   ```

## Decisiones de migración (compose → quadlet)

| Compose (ejemplo) | Quadlet |
|---|---|
| `image: ghcr.io/atareao/apimail:latest` | `Image=ghcr.io/atareao/apimail:latest` |
| `init: true` | `PodmanArgs=--init` |
| `restart: unless-stopped` | `Restart=always` |
| `volumes: apimail_data:/app/data:Z` | `Volume=apimail-data.volume:/app/data:Z` |
| `networks: proxy (external)` | `Network=proxy.network` |
| `labels:` con `traefik.enable=true`, `traefik.http.services.*`, etc. | Mantenido tal cual, con rutas `Host('apimail.${FQDN}')` |
| `depends_on` / `restart` | gestionados por `After`/`Requires` y `Restart` |
| secretos | Migrados a `Secret=` con `type=env,target=…` |
| healthcheck | Se añadió `HealthCmd`, `HealthInterval`, `HealthRetries`, `HealthTimeout`, `HealthStartPeriod` |

## Follow‑ups

- El contenedor requiere que la API key y contraseñas IMAP/SMTP sean válidos; de lo contrario no arranca.
- Los secretos están gestionados por `podman secret create` y no por `crypta store`.
- Si el dominio cambia, solo modificar la variable `${FQDN}` que se expande en `systemd` y en el router de Traefik.
