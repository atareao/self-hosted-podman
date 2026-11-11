# atuin — Gestor de historial de terminal

## Qué es
- Aplicación: gestor de historial de terminal
- Imagen: `docker.io/ellieh/atuin:latest`
- Contenedores: 2 (atuin + postgresql)
- Red: `proxy.network`
- Dominio: `atuin.${FQDN}`
- Puerto interno: 8888

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/atuin/atuin.container
  - /data/self-hosted-podman/.config/containers/available/atuin/atuin-postgresql.container
- Volumen(es):
  - /data/self-hosted-podman/.config/containers/available/atuin/atuin-data.volume
- Config no secreta: (ninguna)
- Secretos:
  - `atuin_db_uri`
  - `atuin_postgres_password`

## Cómo funciona
- Se conecta a la red `proxy.network` y es accesible vía Traefik en `atuin.${FQDN}`.
- El contenedor atuin se une a `proxy.network` (Traefik) y a `atuin.network` para alcanzar `postgres_for_atuin:5432`.
- Se almacena el historial en el volumen `atuin-data` montado en `/var/lib/postgresql` dentro del contenedor de PostgreSQL.
- Variables de entorno de la aplicación se provienen de la configuración de la red y la base de datos.
- Healthcheck no está definido en el quadlet.
- El contenedor no corre como root; usa UID/GID no privilegiados.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| ATUIN_HOST | Environment= | 0.0.0.0 | Dirección de escucha |
| ATUIN_PORT | Environment= | 8888 | Puerto de la aplicación |
| ATUIN_OPEN_REGISTRATION | Environment= | true | Permitir registro abierto |
| ATUIN_DB_URI | Secret=atuin_db_uri,type=env | postgresql://atuin:<password>@postgres_for_atuin:5432/atuin | URI completa de conexión (se guarda entera como secreto) |

- PostgreSQL usa la imagen `postgres:18-alpine`; desde la 18 el volumen se monta en `/var/lib/postgresql` (directorio padre), no en `/var/lib/postgresql/data`.

## Cómo habilitar / desplegar
1. Secretos (si existen): `printf '%s' '<valor>' | podman secret create atuin_db_uri -`
2. `cd .config/containers/available/atuin && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- `atuin_postgres_password` y el password embebido en `atuin_db_uri` deben coincidir.
