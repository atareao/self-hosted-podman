# wakapi — Plataforma de registro y análisis de actividad

## Qué es
Aplicación: Wakapi (registro de uso de apps)
Imagen: ghcr.io/muety/wakapi:latest
Número de contenedores: 2
Red: proxy.network, wakapi.network
Dominio: `wakapi.${FQDN}` (subdominio wakapi)
Puerto interno: 3000

## Ficheros
- Quadlet(s):
  - `/data/self-hosted-podman/.config/containers/available/wakapi/wakapi.container`
  - `/data/self-hosted-podman/.config/containers/available/wakapi/wakapi-postgresql.container`
- Volumen(es):
  - `/data/self-hosted-podman/.config/containers/available/wakapi/wakapi-wakapi.volume`
  - `/data/self-hosted-podman/.config/containers/available/wakapi/wakapi-pg_data.volume`
- Config no secreta: `/data/self-hosted-podman/.config/wakapi/wakapi.env`
- Secretos: `wakapi_db_password`, `wakapi_postgres_password`

## Cómo funciona
El contenedor `wakapi` se une a las redes `proxy.network` y `wakapi.network`, exponiendo el puerto 3000 a Traefik. El servicio PostgreSQL `wakapi-postgresql` está adjunto a la red `wakapi.network` solo para permitir la comunicación interna. Los volúmenes `wakapi-wakapi` y `wakapi-pg_data` persisten los datos de la aplicación y la base de datos respectivamente. Se inyectan los secretos `wakapi_db_password` y `wakapi_postgres_password` como variables de entorno. Traefik redirige las peticiones a `wakapi.${FQDN}`.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| WAKAPI_DB_TYPE | `Environment=` | postgres | Tipo de BD |
| WAKAPI_DB_HOST | `Environment=` | db | Host DB |
| WAKAPI_DB_PORT | `Environment=` | 5432 | Puerto DB |
| WAKAPI_ALLOW_SIGNUP | `Environment=` | False | Permitir registro propio |
| WAKAPI_DB_NAME | `/data/self-hosted-podman/.config/wakapi/wakapi.env` | wakapi | Nombre BD |
| WAKAPI_DB_USER | `/data/self-hosted-podman/.config/wakapi/wakapi.env` | wakapi | Usuario BD |
| POSTGRES_DB | `/data/self-hosted-podman/.config/wakapi/wakapi.env` | wakapi | BD PostgreSQL |
| POSTGRES_USER | `/data/self-hosted-podman/.config/wakapi/wakapi.env` | wakapi | Usuario PostgreSQL |

## Cómo habilitar / desplegar
1. `printf '%s' '<valor_wakapi_db_password>' | podman secret create wakapi_db_password -`
2. `printf '%s' '<valor_wakapi_postgres_password>' | podman secret create wakapi_postgres_password -`
3. `cd .config/containers/available/wakapi && qctl install`
4. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
