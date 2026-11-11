# postgres — Base de datos PostgreSQL y pgAdmin para administración

## Qué es
Base de datos PostgreSQL y pgAdmin, basado en las imágenes `docker.io/library/postgres:latest` y `docker.io/dpage/pgadmin4`. Número de contenedores: 2 (postgres-postgres y postgres-pgadmin). Red(es): `postgres.network`, `proxy.network` para pgAdmin. Dominio(s): `pgadmin.${FQDN}` subdominio (label `traefik.http.routers.pgadmin.rule`). Puerto interno de pgAdmin: 80 (label `traefik.http.services.pgadmin.loadbalancer.server.port`). Puerto interno de PostgreSQL: 5432 (puerto por defecto; no expuesto por Traefik).

## Ficheros
- Quadlet(s):
  - `/data/self-hosted-podman/postgres-postgres.container`
  - `/data/self-hosted-podman/postgres-pgadmin.container`
- Volumen(es):
  - `/data/self-hosted-podman/postgres-data.volume`
  - `/data/self-hosted-podman/postgres-pgadmin.volume`
- Config no secreta: (no dispone de .env)
- Secretos:
  - postgres_password
  - postgres_pgadmin_default_password

## Cómo funciona
El contenedor `postgres-postgres` expone la base de datos PostgreSQL y persiste los datos en `postgres-data.volume`. El contenedor `postgres-pgadmin` ofrece una interfaz web para administrar la base de datos y utiliza la red `proxy.network` para su exposición a Traefik. Los secretos `postgres_password` y `postgres_pgadmin_default_password` suministran la contraseña de la base de datos y del administrador respectivamente. La unidad se ejecuta con `Restart=always`. Traefik enruta el tráfico a través del puerto interno 80 de pgAdmin.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| POSTGRES_USER | Environment | `root` | Usuario de PostgreSQL |
| POSTGRES_DB | Environment | `test_db` | Base de datos inicial |
| PGADMIN_DEFAULT_EMAIL | Environment | `admin@admin.es` | Correo del administrador de pgAdmin |

## Cómo habilitar / desplegar
1. Secretos (solo si existen):
   ```bash
   printf '%s' '<valor>' | podman secret create postgres_password -
   printf '%s' '<valor>' | podman secret create postgres_pgadmin_default_password -
   ```
2. `cd .config/containers/available/postgres && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
