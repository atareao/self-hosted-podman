# whisper — Servicio de reconocimiento de voz Whisper

## Qué es
whisper, docker.io/onerahmet/openai-whisper-asr-webservice:latest-gpu, 1 contenedor, sin red, sin dominio, 9000

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
| ASR_MODEL | whisper.container | large-v1 | |
| ASR_ENGINE | whisper.container | faster_whisper | |
| ASR_MODEL_PATH | whisper.container | /data/whisper | |

## Cómo habilitar / desplegar
1. Secretos: N/A
2. `cd .config/containers/available/whisper && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
