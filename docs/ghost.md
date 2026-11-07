# ghost — ghost

## Qué es
- app: ghost
- imagen: docker.io/library/ghost:4-alpine
- nº contenedores: 1
- red: proxy.network
- dominio: raíz ${FQDN}, subdominio ghost.${FQDN}
- puerto interno: 2368

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/ghost/ghost.container
- Volumen(es): ninguno
- Config no secreta: ninguno
- Secretos: ninguno

## Cómo funciona
- red proxy.network
- volúmenes: (host path %h/.config/ghost/blog, no volumenes de disco)
- secretos: ninguno
- EnvironmentFile: ninguno
- socket del daemon: ninguno
- healthcheck: ninguno
- Traefik enrutado: router "ghost" sobre Host(`ghost.${FQDN}`) con entrada websecure
- User/UserNS/NoNewPrivileges: no se especifica, se ejecuta como root

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| url | Environment= | ghost.${FQDN} | |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store): `printf '%s' '<valor>' | podman secret create <nombre> -`
2. `cd /data/self-hosted-podman/.config/containers/available/ghost && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)