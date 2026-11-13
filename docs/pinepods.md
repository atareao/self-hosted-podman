# pinepods — 

## Qué es
- app: pinepods
- Image(s): pinepods: docker.io/madeofpendletonwool/pinepods:latest, pinepods-postgresql: docker.io/library/postgres:17, pinepods-valkey: docker.io/valkey/valkey:8-alpine
- nº contenedores: 3
- red: proxy.network, pinepods.network
- dominio: subdominio podcasts.${FQDN} (root ${FQDN})
- puerto interno: 8040

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/pinepods/pinepods.container
  - /data/self-hosted-podman/.config/containers/available/pinepods/pinepods-postgresql.container
  - /data/self-hosted-podman/.config/containers/available/pinepods/pinepods-valkey.container
- Volumen(es):
  - /data/self-hosted-podman/.config/containers/available/pinepods/pinepods-backups.volume
  - /data/self-hosted-podman/.config/containers/available/pinepods/pinepods-downloads.volume
  - /data/self-hosted-podman/.config/containers/available/pinepods/pinepods-pgdata.volume
- Config no secreta: none
- Secretos: pinepods_db_password

## Cómo funciona
Conecta a la red proxy.network y pinepods.network. Usa volúmenes para backups, downloads y datos de PostgreSQL. Inyecta credenciales DB y valkey. No dispone de sockets del daemon ni healthcheck. Traefik enruta a https://podcasts.${FQDN} con puerto 8040.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| SEARCH_API_URL | container | https://search.pinepods.online/api/search | URL del API de búsqueda. |
| PEOPLE_API_URL | container | https://people.pinepods.online | URL del API de personas. |
| HOSTNAME | container | https://${FQDN} | Hostname del servicio. |
| DB_TYPE | container | postgresql | Tipo de BD. |
| DB_HOST | container | pinepods_db | Host de BD. |
| DB_PORT | container | 5432 | Puerto de BD. |
| DB_USER | container | postgres | Usuario de BD. |
| DB_NAME | container | pinepods_database | Nombre de BD. |
| VALKEY_HOST | container | pinepods_valkey | Host de Valkey. |
| VALKEY_PORT | container | 6379 | Puerto de Valkey. |
| DEBUG_MODE | container | False | Modo de depuración. |
| PUID | container | 911 | UID del usuario. |
| PGID | container | 911 | GID del usuario. |
| TZ | container | Europe/Madrid | Zona horaria. |
| DB_PASSWORD | container | (secreto) | Contraseña de BD (injectado como secret). |
| POSTGRES_PASSWORD | container | (secreto) | Contraseña de Postgres (injectado como secret). |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store):
   - `printf '%s' '\u003cvalor\u003e' | podman secret create pinepods_db_password -`
2. `cd .config/containers/available/pinepods && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)