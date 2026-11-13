# postgres — Base de datos PostgreSQL y pgAdmin para administración

## Qué es
Base de datos PostgreSQL y pgAdmin, basado en las imágenes `docker.io/library/postgres:17-alpine` y
`docker.io/dpage/pgadmin4`. Número de contenedores: 2 (postgres-postgres y postgres-pgadmin).
Red(es): `postgres.network` para ambos; pgAdmin además en `proxy.network` para su exposición.
Dominio(s): `pgadmin.${FQDN}` subdominio (label `traefik.http.routers.pgadmin.rule`). Puerto interno de
pgAdmin: 80 (label `traefik.http.services.pgadmin.loadbalancer.server.port`). Puerto interno de PostgreSQL:
5432 (puerto por defecto; no expuesto por Traefik).

## Ficheros
- Quadlet(s):
  - `/data/self-hosted-podman/.config/containers/available/postgres/postgres-postgres.container`
  - `/data/self-hosted-podman/.config/containers/available/postgres/postgres-pgadmin.container`
- Volumen(es):
  - `/data/self-hosted-podman/.config/containers/available/postgres/postgres-data.volume` → `/var/lib/postgresql/data`
  - `/data/self-hosted-podman/.config/containers/available/postgres/postgres-pgadmin.volume` → `/var/lib/pgadmin`
- Red(es):
  - `/data/self-hosted-podman/.config/containers/available/postgres/postgres.network`
- Config no secreta: (no dispone de .env)
- Secretos:
  - postgres_password
  - postgres_pgadmin_default_password

## Cómo funciona
El contenedor `postgres-postgres` (`postgres:17-alpine`, **pinned**, sin `AutoUpdate`) expone la base de
datos PostgreSQL y persiste los datos en `postgres-data.volume` montado en `/var/lib/postgresql/data`.
Healthcheck: `pg_isready -U root -d test_db`.

El contenedor `postgres-pgadmin` ofrece la interfaz web, está en `postgres.network` (para alcanzar la BD)
y en `proxy.network` (para Traefik). Los secretos `postgres_password` y
`postgres_pgadmin_default_password` suministran la contraseña de la base de datos y del administrador.
Traefik enruta el tráfico a través del puerto interno 80 de pgAdmin.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| POSTGRES_USER | Environment | `root` | Usuario de PostgreSQL |
| POSTGRES_DB | Environment | `test_db` | Base de datos inicial |
| POSTGRES_PASSWORD | `Secret=postgres_password` | aleatorio | Contraseña de PostgreSQL |
| PGADMIN_DEFAULT_EMAIL | Environment | `admin@admin.es` | Correo del administrador de pgAdmin |
| PGADMIN_DEFAULT_PASSWORD | `Secret=postgres_pgadmin_default_password` | aleatorio | Contraseña de pgAdmin |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA `crypta store`):
   ```bash
   printf '%s' '<valor>' | podman secret create postgres_password -
   printf '%s' '<valor>' | podman secret create postgres_pgadmin_default_password -
   ```
2. `cd .config/containers/available/postgres && qctl install`
3. `systemctl --user daemon-reload`

## Verificación E2E (2026-11-13)

Verificado en producción (`new_atareao`, usuario `runner`) con certificado `letsencrypt-staging`
(purgado después):

1. Unit `postgres-postgres` → `active`; `postgres-pgadmin` → `active`.
2. Contenedor PostgreSQL → `healthy` (`pg_isready`).
3. Router `pgadmin` registrado en Traefik (PostgreSQL no tiene router HTTP propio).
4. Certificado staging válido para `pgadmin.servidorlinux.es`.
5. `https://pgadmin.servidorlinux.es` → **302** a `/login`; desde pgAdmin se alcanza **TCP `postgres:5432`**.

Bugs corregidos para llegar hasta aquí:

- pgAdmin estaba solo en `proxy.network`, así que no veía la BD → añadida `postgres.network`.
- **Pérdida de datos:** con `postgres:latest` (= 18.x) el `VOLUME` de la imagen es `/var/lib/postgresql`,
  pero el volumen estaba en `/var/lib/postgresql/data` → quedaba **sin usar** (datos en la capa del
  contenedor, se pierden al recrear). Se pinnea `postgres:17-alpine` y se mantiene `/var/lib/postgresql/data`.
- Se quitó `AutoUpdate` de una BD: un salto de major rompe el datadir.

## Follow-ups
- Si algún día se quiere PostgreSQL 18+, montar el volumen en `/var/lib/postgresql` y **migrar el datadir**
  antes de cambiar la imagen.
