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
  - .config/containers/available/open-webui/open-webui-open-webui.volume
  - .config/containers/available/open-webui/open-webui-ollama.volume
- Config no secreta: ninguno
- Secretos: ninguno

## Cómo funciona
- **Red:** `open-webui.network` conecta los dos contenedores y permite la comunicación interna entre la UI y el modelo LLM.
- **Volumes:** persistencia de la base de datos de la UI y el modelo de lenguaje.
- **Healthcheck:** no definido.
- **Traefik:** no se configuran etiquetas, por lo que el servicio debe exponerse de forma manual o mediante otra capa de reverse proxy.
- **User:** ninguno especificado.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| OLLAMA_BASE_URL | open-webui.container | http://ollama:11434 | URL del backend de ollama |
| WEBUI_SECRET_KEY | open-webui.container | (vacío) | Clave de seguridad de la UI |

## Cómo habilitar / desplegar
1. Secretos: ninguno que crear.
2. `cd .config/containers/available/open-webui && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
