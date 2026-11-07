# wger — Servidor de gimnasio de código abierto (backend + celery + nginx)

## Qué es
Aplicación: wger
Imagen: docker.io/wger/server:latest (celery beat, worker, api) + docker.io/library/nginx:stable (nginx) + docker.io/library/postgres:15-alpine + docker.io/library/redis (redis)
Número de contenedores: 6
Red: wger.network y proxy.network (nginx)
Dominio: `wger.${FQDN}` (subdominio wger)
Puerto interno: 80 (nginx)

## Ficheros
- Quadlet(s):
  - `/data/self-hosted-podman/.config/containers/available/wger/wger-celery-beat.container`
  - `/data/self-hosted-podman/.config/containers/available/wger/wger-celery-worker.container`
  - `/data/self-hosted-podman/.config/containers/available/wger/wger.container`
  - `/data/self-hosted-podman/.config/containers/available/wger/wger-nginx.container`
  - `/data/self-hosted-podman/.config/containers/available/wger/wger-postgresql.container`
  - `/data/self-hosted-podman/.config/containers/available/wger/wger-redis.container`
- Volumen(es):
  - `/data/self-hosted-podman/.config/containers/available/wger/wger-celery-beat.volume`
  - `/data/self-hosted-podman/.config/containers/available/wger/wger-media.volume`
  - `/data/self-hosted-podman/.config/containers/available/wger/wger-static.volume`
  - `/data/self-hosted-podman/.config/containers/available/wger/wger-postgres-data.volume`
- Config no secreta: ninguno
- Secretos: `wger_postgres_password`

## Cómo funciona
Los contenedores de la API y Celery se unen a la red `wger.network` para comunicarse internamente con PostgreSQL y Redis. El contenedor `wger-nginx` se une a `proxy.network` y actúa como proxy inverso para `wger.${FQDN}`. Se inyecta el secreto `wger_postgres_password` como variable de entorno en los contenedores que requieren acceso a la base de datos. Los volúmenes persisten los datos de la aplicación, media y la base de datos PostgreSQL.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| POSTGRES_USER | `/data/self-hosted-podman/.config/containers/available/wger/wger-postgresql.container` | wger | Usuario PostgreSQL |
| POSTGRES_DB | `/data/self-hosted-podman/.config/containers/available/wger/wger-postgresql.container` | wger | BD PostgreSQL |

## Cómo habilitar / desplegar
1. `printf '%s' '<valor_wger_postgres_password>' | podman secret create wger_postgres_password -`
2. `cd .config/containers/available/wger && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
