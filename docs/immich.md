# immich — Servidor de fotos y videos

## Qué es
- Imágenes: docker.io/altran1502/immich-proxy, docker.io/altran1502/immich-web, docker.io/altran1502/immich-machine-learning, docker.io/altran1502/immich-server, docker.io/altran1502/immich-microservices, docker.io/library/postgres:14, docker.io/library/redis:6.2
- Nº contenedores: 7
- Red principal: immich.network (con el proxy conectado a proxy.network)
- Dominio: Host(`immich.${FQDN}`) (router *immich*)
- Puerto interno: 8080 (servicio *immich*)

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/immich/immich-proxy.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/immich/immich-web.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/immich/immich-machine-learning.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/immich/immich-server.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/immich/immich-microservices.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/immich/immich-postgresql.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/immich/immich-redis.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/immich/immich-pgdata.volume
- Config no secreta: NINGUNO
- Secretos: immich_postgres_password

## Cómo funciona
- Red: immich.network (proxy con proxy.network)
- Volúmenes: immich-pgdata
- Secretos: immich_postgres_password
- EnvironmentFile: ninguno
- Socket del daemon: no
- Healthcheck: ninguno
- Enrutado Traefik: router *immich*
- User: ninguno (root)
- NoNewPrivileges: habilitado por defecto

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| POSTGRES_USER | immich-postgresql | postgres | usuario de la BD |
| POSTGRES_DB | immich-postgresql | immich | base de datos |
| PG_DATA | immich-postgresql | /var/lib/postgresql/data | ruta de datos |

## Cómo habilitar / desplegar
1. `cd .config/containers/available/immich && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)