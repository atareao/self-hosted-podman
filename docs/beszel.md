# beszel — monitor de sistemas y agentes

## Qué es
- Aplicación: monitor de sistemas y agentes
- Imagen: `docker.io/henrygd/beszel:latest`
- Contenedores: 2 (beszel + beszel-agent)
- Red(es): `beszel.network`, `proxy.network`
- Dominio: `beszel.${FQDN}`
- Puerto interno: 8090

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/beszel/beszel.container
  - /data/self-hosted-podman/.config/containers/available/beszel/beszel-agent.container
- Volumen(es):
  - /data/self-hosted-podman/.config/containers/available/beszel/beszel-data.volume
  - /data/self-hosted-podman/.config/containers/available/beszel/beszel-socket.volume
  - /data/self-hosted-podman/.config/containers/available/beszel/beszel-agent-data.volume
- Config no secreta: (ninguna)
- Secretos:
  - `beszel_key`
  - `beszel_token`

## Cómo funciona
- El servicio principal se conecta a la red `proxy.network` y se expone vía Traefik en `beszel.${FQDN}`.
- El agente monta los volúmenes de datos, socket y credenciales, y se comunica con el servidor Beszel a través de `/beszel_socket/beszel.sock`.
- El agente se ejecuta como root (`User=root`).
- No se define Healthcheck en los quadlets.
- El contenedor principal no corre como root; utiliza UID/GID no privilegiado.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| LISTEN | Environment= | `/beszel_socket/beszel.sock` | Puerto de escucha del agente |
| HUB_URL | Environment= | `http://beszel:8090` | URL del servidor Beszel |

## Cómo habilitar / desplegar
1. Secretos (si existen):
   - `printf '%s' '\u003cvalor\u003e' | podman secret create beszel_key -`
   - `printf '%s' '\u003cvalor\u003e' | podman secret create beszel_token -`
2. `cd .config/containers/available/beszel && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
