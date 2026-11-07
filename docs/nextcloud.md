# nextcloud — Plataforma de colaboración

## Qué es
- Imágenes: docker.io/library/nextcloud:fpm-alpine, docker.io/library/postgres:alpine, docker.io/library/redis:alpine, docker.io/library/nginx:alpine
- Nº contenedores: 5
- Redes: nextcloud.network y proxy.network (para el nginx con Traefik)
- Dominio: Host(`nextcloud.${FQDN}`) (router *nextcloud*)
- Puerto interno: 80 (para el nginx)

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/nextcloud/nextcloud-app.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/nextcloud/nextcloud-postgresql.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/nextcloud/nextcloud-redis.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/nextcloud/nextcloud-cron.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/nextcloud/nextcloud.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/nextcloud/nextcloud.network
- Config no secreta: NINGUNO
- Secretos: NINGUNO

## Cómo funciona
- Red: nextcloud.network (nginx también usa proxy.network)
- Volúmenes: nextcloud-app usa /config/nextcloud/nextcloud ; nginx comparte los mismos, redis y postgres usan sus propias volúmenes
- Secretos: ninguno
- EnvironmentFile: ninguno
- Socket del daemon: no
- Healthcheck: ninguno
- Enrutado Traefik: router *nextcloud*
- User: ninguno (root)
- NoNewPrivileges: habilitado

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| POSTGRES_HOST | nextcloud-app | db | host de la BD |
| REDIS_HOST | nextcloud-app | redis | host del key‑value |
| POSTGRES_USER | nextcloud-postgresql | postgres | usuario BD |
| POSTGRES_DB | nextcloud-postgresql | nextcloud | nombre BD |
| PG_DATA | nextcloud-postgresql | /var/lib/postgresql/data | ruta datos |

## Cómo habilitar / desplegar
1. `cd .config/containers/available/nextcloud && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)