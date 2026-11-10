# authentik — plataforma de autenticación y autorización

## Qué es
- Aplicación: plataforma de autenticación y autorización
- Imagen: `ghcr.io/goauthentik/server:2022.10.0`
- Contenedores: 5 (authentik, authentik-postgresql, authentik-redis, authentik-geoipupdate, authentik-worker)
- Red: `authentik.network`
- Dominio: (ninguno – no se expone a Traefik)
- Puertos internos: 9000, 9443

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/authentik/authentik.container
  - /data/self-hosted-podman/.config/containers/available/authentik/authentik-postgresql.container
  - /data/self-hosted-podman/.config/containers/available/authentik/authentik-redis.container
  - /data/self-hosted-podman/.config/containers/available/authentik/authentik-geoipupdate.container
  - /data/self-hosted-podman/.config/containers/available/authentik/authentik-worker.container
- Volumen(es):
  - /data/self-hosted-podman/.config/containers/available/authentik/authentik-database.volume
  - /data/self-hosted-podman/.config/containers/available/authentik/authentik-redis.volume
  - /data/self-hosted-podman/.config/containers/available/authentik/authentik-geoip.volume
- Config no secreta: (ninguna)
- Secretos:
  - `authentik_postgresql__password`
  - `authentik_postgres_password`

## Cómo funciona
- Se conecta a la red `authentik.network` y, para el frontend, utiliza los puertos 9000 (HTTP) y 9443 (HTTPS).
- Base de datos PostgreSQL monta el volumen `authentik-database` en `/var/lib/postgresql/data`.
- Redis monta el volumen `authentik-redis` en `/data`.
- La actualización de GeoIP monta el volumen `authentik-geoip` en `/usr/share/GeoIP`.
- No se define Healthcheck en el quadlet.
- Los contenedores funcionan con su propio usuario/ID y no como root.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| AUTHENTIK_REDIS__HOST | Environment= | `redis` | Host de Redis |
| AUTHENTIK_POSTGRESQL__HOST | Environment= | `postgresql` | Host de PostgreSQL |
| AUTHENTIK_POSTGRESQL__USER | Environment= | `authentik` | Usuario de DB |
| AUTHENTIK_POSTGRESQL__NAME | Environment= | `authentik` | Nombre de DB |
| AUTHENTIK_REDIS__HOST | Environment= | `redis` | (repetido) |
| AUTHENTIK_POSTGRESQL__HOST | Environment= | `postgresql` | (repetido) |
| AUTHENTIK_POSTGRESQL__USER | Environment= | `authentik` | (repetido) |
| AUTHENTIK_POSTGRESQL__NAME | Environment= | `authentik` | (repetido) |
| (n/a) | | | |

## Cómo habilitar / desplegar
1. Secretos (si existen):
   - `printf '%s' '<valor>' | podman secret create authentik_postgresql__password -`
   - `printf '%s' '<valor>' | podman secret create authentik_postgres_password -`
2. `cd .config/containers/available/authentik && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- **Sin enrutado por diseño**: el stack no declara labels de Traefik (igual que en el repo origen `atareao/self-hosted`); si hay que exponerlo, se añaden labels `Host(`<subdominio>.${FQDN}`)` propias. Ver los invariantes de enrutado en `docs/traefik.md`.
