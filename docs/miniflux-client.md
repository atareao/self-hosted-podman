# miniflux-client — Bot de noticias de Miniflux

## Qué es
- **Aplicación:** miniflux-client
- **Imagen:** docker.io/atareao/miniflux-client:latest
- **Consola contenedores:** 1
- **Redes:** (none explícitas; usa red del host)
- **Dominio:** (no expone Traefik; se comunica internamente)
- **Puerto interno:** (no expuesto)

## Ficheros
- **Quadlet(s):** .config/containers/available/miniflux-client/miniflux-client.container
- **Volumen(es):** (none)
- **Config no secreta:** .config/miniflux-client/miniflux-client.env
- **Secretos:** miniflux_client_matrix_token, miniflux_client_miniflux_token, miniflux_client_model_api_key, miniflux_client_telegram_token

## Cómo funciona
- **Redes:** conecta a red interna de Miniflux a través de variables y env
- **Secretos:** se inyectan como variables de entorno (`MATRIX_TOKEN`, `MINIFLUX_TOKEN`, `MODEL_API_KEY`, `TELEGRAM_TOKEN`)
- **EnvironmentFile:** carga configuración desde `.config/miniflux-client/miniflux-client.env` y local
- **Healthcheck:** (no definido)
- **Traefik:** (no expuesto a Traefik)
- **User:** no especificado (ejecuta como root por defecto)

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| MATRIX_URL | Environment | "matrix.${FQDN}" | URL de Matrix
| MINIFLUX_CATEGORIES | Environment | Linux | Categorías a seguir
| MINIFLUX_URL | Environment | "miniflux.${FQDN}" | URL de Miniflux
| MODEL_NAME | Environment | gpt-4.1-nano | Modelo de IA
| MODEL_URL | Environment | https://api.openai.com | URL API OpenAI
| RUST_LOG | Environment | DEBUG | Nivel de log
| MODEL_DESCRIPTION | Environment | "Eres un asistente especializado en noticias internacionales" | Descripción del modelo
| MODEL_PROMPT | Environment | "Analiza todas las noticias ..." | Prompt del modelo
| MATRIX_ROOM | .config/miniflux-client/miniflux-client.env | placeholder | Salón Matrix
| MAX_ENTRIES | .config/miniflux-client/miniflux-client.env | 10 | Máx entradas
| SLEEP_TIME | .config/miniflux-client/miniflux-client.env | 3600 | Intervalo de sueño
| TELEGRAM_CHAT_ID | .config/miniflux-client/miniflux-client.env |  | ID de chat
| TELEGRAM_THREAD_ID | .config/miniflux-client/miniflux-client.env |  | Thread ID

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store):
   - `printf '%s' '\u003cvalor\u003e' | podman secret create miniflux_client_matrix_token -`
   - `printf '%s' '\u003cvalor\u003e' | podman secret create miniflux_client_miniflux_token -`
   - `printf '%s' '\u003cvalor\u003e' | podman secret create miniflux_client_model_api_key -`
   - `printf '%s' '\u003cvalor\u003e' | podman secret create miniflux_client_telegram_token -`
2. `cd .config/containers/available/miniflux-client && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
