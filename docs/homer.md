# homer — Servidor de información y dashboards

## Qué es
Aplica la imagen: docker.io/b4bz/homer, 1 contenedor, red: proxy.network, dominio: Host(`homer.${FQDN}`), puerto interno: 8080

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/homer/homer.container
- Volumen(es): NINGUNO
- Config no secreta: NINGUNO
- Secretos: NINGUNO

## Cómo funciona
Red proxy.network; volúmenes: assets bind; secretos: ninguno; EnvironmentFile: ninguno; socket del daemon: no; healthcheck: ninguno; enrutado Traefik: router *homer*. User 1000; NoNewPrivileges: habilitado.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| (ninguno) | | | |

## Cómo habilitar / desplegar
1. `cd .config/containers/available/homer && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)