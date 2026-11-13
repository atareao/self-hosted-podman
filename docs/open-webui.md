# open-webui — Interfaz web para ChatGPT y LLMs en tu servidor

## Qué es
- **App:** Open WebUI
- **Imagen:** ghcr.io/open-webui/open-webui:main (webui) + docker.io/ollama/ollama (ollama)
- **Número de contenedores:** 2 (open-webui, open-webui-ollama)
- **Red(es):** open-webui.network
- **Dominio:** ninguno explícito en etiquetas (se espera en configuración externa); la exposición típica sería a través de la red interna.
- **Puerto interno:** 8080 (webui) y 11434 (ollama)

## Ficheros
- Quadlet(s):
  - .config/containers/available/open-webui/open-webui.container
  - .config/containers/available/open-webui/open-webui-ollama.container
- Volumen(es):
  - .config/containers/available/open-webui/open-webui-data.volume
  - .config/containers/available/open-webui/open-webui-ollama.volume
- Config no secreta: ninguno
- Secretos: `open_webui_secret_key` (tipo env; target `WEBUI_SECRET_KEY`)

## Cómo funciona
- **Red:** `open-webui.network` conecta los dos contenedores y permite la comunicación interna entre la UI y el modelo LLM.
- **Dependencias:** `After=open-webui-ollama.service` + `Requires=open-webui-ollama.service` — la UI espera a que arranque el contenedor de Ollama.
- **Volumes:** persistencia de la base de datos de la UI y el modelo de lenguaje.
- **Secreto:** `open_webui_secret_key` → `WEBUI_SECRET_KEY` (creado con `podman secret create`; antes era una variable vacía).
- **Healthcheck:** `curl -fsS http://127.0.0.1:8080/health` (30 s, 5 reintentos, `HealthStartPeriod=30s`).
- **Traefik:** **sin labels por diseño** (igual que el repo origen `atareao/self-hosted`); no se publica por Traefik. Para exponerlo habría que añadir labels propias.
- **User:** ninguno especificado.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| OLLAMA_BASE_URL | open-webui.container | http://ollama:11434 | URL del backend de ollama |
| WEBUI_SECRET_KEY | open-webui.container (`Secret=open_webui_secret_key`) | *(secreto)* | Clave de seguridad de la UI (antes vacía) |

## Cómo habilitar / desplegar
1. Secretos (NUNCA `crypta store`): `printf '%s' '<valor>' | podman secret create open_webui_secret_key -`
2. `cd .config/containers/available/open-webui && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- **Sin enrutado por diseño**: el stack no declara labels de Traefik (igual que en el repo origen `atareao/self-hosted`); si hay que exponerlo, se añaden labels `Host(`<subdominio>.${FQDN}`)` propias. Ver los invariantes de enrutado en `docs/traefik.md`.
