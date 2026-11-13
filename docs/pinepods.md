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
- Secretos: `pinepods_db_password` (único secreto de BD, compartido por app y PostgreSQL)

## Cómo funciona
Conecta a la red proxy.network y pinepods.network. Usa volúmenes para backups, downloads y datos de PostgreSQL. Declara `After=`/`Requires=` sobre `pinepods-postgresql.service` y `pinepods-valkey.service`, y comparte **un único** secreto de BD (`pinepods_db_password`) entre la app (target `DB_PASSWORD`) y PostgreSQL (target `POSTGRES_PASSWORD`). Healthchecks: `pg_isready` en PostgreSQL, `valkey-cli ping` en Valkey y `/api/health` en la app. Solo monta `/etc/localtime` (no `/etc/timezone`, que no existe en el host Arch). `HOSTNAME=https://podcasts.${FQDN}`. Traefik enruta a https://podcasts.${FQDN} con puerto 8040.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| SEARCH_API_URL | container | https://search.pinepods.online/api/search | URL del API de búsqueda. |
| PEOPLE_API_URL | container | https://people.pinepods.online | URL del API de personas. |
| HOSTNAME | container | https://podcasts.${FQDN} | Hostname del servicio. |
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
| DB_PASSWORD | pinepods (`Secret=pinepods_db_password`) | *(secreto)* | Contraseña de BD de la app. |
| POSTGRES_PASSWORD | pinepods-postgresql (`Secret=pinepods_db_password`) | *(secreto)* | Misma contraseña de BD en PostgreSQL (un único secreto compartido). |

## Cómo habilitar / desplegar
1. Secretos (NUNCA `crypta store`): un único secreto de BD, compartido por app y PostgreSQL.
   - `printf '%s' '<valor>' | podman secret create pinepods_db_password -`
2. `cd .config/containers/available/pinepods && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- **Cert LE**: `podcasts.servidorlinux.es` quedó pendiente del certificado de producción por el rate limit de Let's Encrypt (bloqueante externo; Traefik sirve su cert por defecto hasta el reset). Ver `docs/estado-verificacion-e2e.md`.