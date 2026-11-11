# whisper — Servicio de reconocimiento de voz Whisper

## Qué es
whisper, docker.io/onerahmet/openai-whisper-asr-webservice:latest (variante CPU), 1 contenedor, sin red, sin dominio, 9001

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/whisper/whisper.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/whisper/whisper-data.volume
- Config no secreta: N/A
- Secretos: N/A

## Cómo funciona
- Red: N/A
- Volúmenes: whisper-data.volume está montado en /data/whisper
- Secretos: N/A
- EnvironmentFile: N/A
- Socket del daemon: N/A
- Healthcheck: N/A
- Enrutado Traefik: N/A
- User/UserNS/NoNewPrivileges: N/A

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|-----|-------|-------|-------------|
| ASR_MODEL | whisper.container | small | |
| ASR_ENGINE | whisper.container | faster_whisper | |
| ASR_MODEL_PATH | whisper.container | /data/whisper | |

## Cómo habilitar / desplegar
1. Secretos: N/A
2. `cd .config/containers/available/whisper && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- **Primer arranque ~200 s**: la imagen pesa 5,31 GB y su pull (más la carga del modelo) dominó el arranque verificado (con `PodmanArgs=--init`, en CPU y modelo `small`). Verificado que sirve: `curl http://127.0.0.1:9001/docs` → **200**.
- Imagen CPU (`:latest`): prod no tiene GPU NVIDIA, `:latest-gpu` exigiria el runtime NVIDIA. `faster_whisper` es dependencia base de la imagen, valida tambien en CPU.
- `ASR_MODEL=small` por defecto (verificacion); subir a `large-v3` cuando se quiera calidad, asumiendo la descarga de GB en el primer arranque.
- Host port 9001 (el 9000 lo publica authentik en `0.0.0.0:9000:9000`).
