# gokapi — gokapi

## Qué es
- app: gokapi
- imagen: docker.io/f0rc3/gokapi:latest
- nº contenedores: 1
- red: proxy.network
- dominio: raíz ${FQDN}, subdominio gokapi.${FQDN}
- puerto interno: 8080

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/gokapi/gokapi.container
- Volumen(es):
  - /data/self-hosted-podman/.config/containers/available/gokapi/gokapi-config.volume
  - /data/self-hosted-podman/.config/containers/available/gokapi/gokapi-data.volume
- Config no secreta: /data/self-hosted-podman/.config/gokapi/gokapi.env
- Secretos: ninguno

## Cómo funciona
- red: proxy.network
- volúmenes: host paths %h/.config/gokapi/... dentro de la aplicación
- secretos: ninguno
- EnvironmentFile: %h/.config/gokapi/gokapi.env y .env.local (si existe)
- socket del daemon: ninguno
- healthcheck: ninguno
- Traefik enrutado: router "gokapi" sobre Host(`gokapi.${FQDN}`) con entrada websecure
- User/UserNS/NoNewPrivileges: no se especifica, se ejecuta como root

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| GOKAPI_PORT | EnvironmentFile | 8080 | |
| GOKAPI_EXTERNAL_URL | Environment= | https://gokapi.${FQDN} | |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store): `printf '%s' '<valor>' | podman secret create <nombre> -`
2. `cd /data/self-hosted-podman/.config/containers/available/gokapi && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)