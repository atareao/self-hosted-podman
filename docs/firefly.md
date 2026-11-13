# firefly — Firefly III es un gestor de finanzas personales

## Qué es
App: Firefly III (web), cron y MariaDB
Imagen(es):
- web: docker.io/fireflyiii/core:version-6.7.9
- croni: docker.io/atareao/croni:v1.1
- mariadb: docker.io/library/mariadb:11
Nº contenedores: 3
Red(s): proxy.network, firefly.network
Dominio: subdominio `firefly.${FQDN}`
Puerto interno: 8080 (web)

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/firefly/firefly.container
  - /data/self-hosted-podman/.config/containers/available/firefly/firefly-croni.container
  - /data/self-hosted-podman/.config/containers/available/firefly/firefly-mariadb.container
- Volumen(es):
  - firefly-mariadb.volume:/var/lib/mysql (datos de MariaDB)
  - Bind: %h/.config/firefly/firefly_upload:/var/www/html/storage/upload (web)
  - Bind: %h/.config/firefly/crontab:/crontab.txt (croni, solo lectura)
- Config no secreta: .config/firefly/crontab (placeholder de latido del sidecar croni)
- Secretos:
  - firefly_app_key (target: APP_KEY)
  - firefly_db_password (target: DB_PASSWORD en web, MARIADB_PASSWORD en MariaDB)
  - firefly_mariadb_root_password (target: MARIADB_ROOT_PASSWORD)

## Cómo funciona
Red proxy.network (proxy) y firefly.network (interno). En firefly.network la web expone el alias `fireflyiii` y MariaDB `db_for_firefly`. Volúmenes: volumen nombrado para los datos de MariaDB y binds a host para los uploads de la web y el crontab del sidecar. Socket del daemon (none). Healthcheck: la web (`curl http://127.0.0.1:8080/`) y MariaDB (`mariadb-admin ping`); croni no define ninguno. Enrutado Traefik a puerto 8080. La web corre con `TRUSTED_PROXIES=10.89.0.0/24` (subred de proxy.network). El cron real de Firefly III v6 lo ejecuta la propia app (`php artisan firefly-iii:cron`); el sidecar `firefly-croni` es un latido/placeholder. User/UserNS/NoNewPrivileges: none.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| APP_ENV | firefly.container | production | Entorno de la app |
| APP_URL | firefly.container | https://firefly.${FQDN} | URL pública |
| TRUSTED_PROXIES | firefly.container | 10.89.0.0/24 | Subred de confianza (proxy.network) |
| DB_CONNECTION | firefly.container | mysql | Driver de BD |
| DB_HOST | firefly.container | db_for_firefly | Alias de MariaDB en firefly.network |
| DB_PORT | firefly.container | 3306 | Puerto de BD |
| DB_DATABASE | firefly.container | firefly | Base de datos |
| DB_USERNAME | firefly.container | firefly | Usuario DB |
| TZ | firefly.container | Europe/Madrid | Zona horaria |
| MARIADB_USER | firefly-mariadb.container | firefly | Usuario DB |
| MARIADB_DATABASE | firefly-mariadb.container | firefly | Base de datos |
| LOGLEVEL | firefly-croni.container | info | Nivel de log del sidecar |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store):
   - `printf '%s' '<valor>' | podman secret create firefly_app_key -`
   - `printf '%s' '<valor>' | podman secret create firefly_db_password -`
   - `printf '%s' '<valor>' | podman secret create firefly_mariadb_root_password -`
2. `cd .config/containers/available/firefly && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)
