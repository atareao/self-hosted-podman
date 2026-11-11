# umami — Analítica web autoalojada (Umami + PostgreSQL)

## Qué es

Umami Analytics: plataforma de analítica web ligera y respetuosa con la privacidad. Dos contenedores: `umami` (imagen `ghcr.io/umami-software/umami:postgresql-latest`) y `umami-postgresql` (imagen `docker.io/library/postgres:18-alpine`). Red: `umami.network` (interna) + `proxy.network` para el front. Dominio: `umami.${FQDN}` (subdominio). Puerto interno expuesto a Traefik: `3000`.

## Ficheros

- Quadlet(s): `.config/containers/available/umami/umami.container`, `.config/containers/available/umami/umami-postgresql.container`
- Volumen(es): `.config/containers/available/umami/umami-data.volume`
- Config no secreta: — (no existe `.env` de stack)
- Secretos: `umami_app_secret`, `umami_database_url`, `umamidb_password`

## Cómo funciona

`umami` se une a dos redes: `umami.network` (donde habla con la base de datos) y `proxy.network` (para que Traefik lo publique). `umami-postgresql` solo está en `umami.network` con `NetworkAlias=umamidb`, para que la app lo resuelva por ese nombre. La base persiste en el volumen `umami-data.volume` montado en `/var/lib/postgresql`. Las credenciales se inyectan con Podman secrets como variables de entorno: `umami_app_secret`→`APP_SECRET`, `umami_database_url`→`DATABASE_URL` (en `umami`), y `umamidb_password`→`POSTGRES_PASSWORD` (en `umami-postgresql`). `umami` depende de la base vía `After=umami-postgresql.service`/`Requires=umami-postgresql.service` (el nombre `umamidb` es solo el `NetworkAlias` del contenedor de BD, **no** una unit de systemd; `After=proxy.network` era inválido y se eliminó — el orden con la red lo genera el propio quadlet como `proxy-network.service`). Ambos tienen healthcheck (`curl .../api/heartbeat` y `pg_isready`); el `umami` además ejecuta `ExecStartPost` esperando a `healthy`. Enrutado Traefik con router `umami` (entrypoint `websecure`, TLS `letsencrypt`, middlewares `seguridadHeaders@file,compresionHeaders@file`). No aplica hardening (`ReadOnly`, `NoNewPrivileges`, `User`).

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `DATABASE_TYPE` | `umami.container` (`Environment=`) | `postgresql` | Motor de base de datos de Umami |
| `TZ` | `umami.container` (`Environment=`) | `Europe/Madrid` | Zona horaria |
| `POSTGRES_DB` | `umami-postgresql.container` (`Environment=`) | `umami` | Nombre de la base de datos |
| `POSTGRES_USER` | `umami-postgresql.container` (`Environment=`) | `umami` | Usuario de PostgreSQL |
| `TZ` | `umami-postgresql.container` (`Environment=`) | `Europe/Madrid` | Zona horaria |
| `APP_SECRET` | `umami.container` (`Secret=umami_app_secret`) | *(secreto)* | Secreto de sesión/firma de Umami |
| `DATABASE_URL` | `umami.container` (`Secret=umami_database_url`) | *(secreto)* | Cadena de conexión completa a PostgreSQL |
| `POSTGRES_PASSWORD` | `umami-postgresql.container` (`Secret=umamidb_password`) | *(secreto)* | Contraseña del usuario `umami` |
| `FQDN` | entorno systemd (`~/.config/environment.d/fqdn.conf`) | `<tu-dominio>` | Dominio base; el router usa `umami.${FQDN}` |

## Cómo habilitar / desplegar

1. Crear los secretos (NUNCA `crypta store`):
   - `printf '%s' '<app-secret>' | podman secret create umami_app_secret -`
   - `printf '%s' '<postgres-password>' | podman secret create umamidb_password -`
   - `printf '%s' 'postgresql://umami:<postgres-password>@umamidb:5432/umami' | podman secret create umami_database_url -`
2. `cd .config/containers/available/umami && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups

- `umamidb_password` y `umami_database_url` deben coincidir (misma contraseña embebida en la URL).
- No aplica hardening (`ReadOnly`, `NoNewPrivileges`, `User`/`Group`); evaluar añadirlo.
- Servido en subdominio propio desde PLAN-023 (antes reclamaba el apex `${FQDN}`, compartido con otros 3 stacks).
- **Verificado E2E el 2026-11-11 (PLAN-031 / issue #26)**: HTTP final 200 en `/` y `/login` (`https://umami.${FQDN}`); **purgado** tras la verificación.
