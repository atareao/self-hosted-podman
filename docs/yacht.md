# yacht — Dashboard de contenedores y gestión

## Qué es
yacht, docker.io/selfhostedpro/yacht, 1 contenedor, red: proxy.network, dominio: yacht.${FQDN}, puerto interno: 3000

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/yacht/yacht.container
- Volumen(es): N/A
- Config no secreta: N/A
- Secretos: N/A

## Cómo funciona
- Red: proxy.network vinculada al contenedor
- Volúmenes: se monta config en /config y el socket del daemon en /var/run/docker.sock (ro)
- Secretos: N/A
- EnvironmentFile: N/A
- Socket del daemon: se monta %t/podman/podman.sock en /var/run/docker.sock
- Healthcheck: N/A
- Enrutado Traefik: Host yacht.${FQDN} apunta al servicio 3000
- User/UserNS/NoNewPrivileges: N/A

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|-----|-------|-------|-------------|
| (ninguna) | (ninguna) | | |

## Cómo habilitar / desplegar
1. Secretos: N/A
2. `cd .config/containers/available/yacht && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
