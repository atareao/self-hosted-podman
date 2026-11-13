# wordpress-wp1 — Sitio WordPress independiente 1

## Qué es
wordpress-wp1, docker.io/library/wordpress:latest, 3 contenedores, red: wordpress-wp1.network + proxy.network (app), dominio: wp1.${FQDN}, puerto interno: 80

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/wordpress-wp1/wordpress-wp1.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/wordpress-wp1/wordpress-wp1-mariadb.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/wordpress-wp1/wordpress-wp1-redis.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/wordpress-wp1/wordpress-wp1-data.volume
- Volumen(es): /data/self-hosted-podman/.config/containers/available/wordpress-wp1/wordpress-wp1-mariadb.volume
- Volumen(es): /data/self-hosted-podman/.config/containers/available/wordpress-wp1/wordpress-wp1-redis.volume
- Red: /data/self-hosted-podman/.config/containers/available/wordpress-wp1/wordpress-wp1.network
- Config no secreta: N/A
- Secretos: wordpress_wp1_wordpress_db_password, wordpress_wp1_mariadb_root_password

## Cómo funciona
- Red: wordpress-wp1.network (app + mariadb + redis) y proxy.network (app, para Traefik)
- Volúmenes: wordpress-wp1-data.volume montado en `/var/www/html/wp-content` (NO en `/var/www/html`), wordpress-wp1-mariadb.volume montado en /var/lib/mysql, wordpress-wp1-redis.volume montado en /data
- Secretos: wordpress_wp1_wordpress_db_password inyecta WORDPRESS_DB_PASSWORD (app) y MARIADB_PASSWORD (BD, el mismo valor) (`type=env`), wordpress_wp1_mariadb_root_password inyecta MARIADB_ROOT_PASSWORD (`type=env`)
- Socket del daemon: N/A
- `Requires=`: `wordpress-wp1-mariadb.service` y `wordpress-wp1-redis.service`; `After=` además `network-online.target` y `traefik.service` (nombres reales de las units)
- Healthcheck: app `curl -f http://localhost/wp-login.php`, MariaDB `mariadb-admin ping --user=root --password="$MARIADB_ROOT_PASSWORD" --silent`, redis `redis-cli ping | grep PONG`
- Enrutado Traefik: router/servicio `wordpress-wp1`, Host(`wp1.${FQDN}`) → puerto 80
- `[Service]`: `TimeoutStartSec=300` (el primer arranque crea la BD) y `PodmanArgs=--init`
- User/UserNS/NoNewPrivileges: N/A

`wp-config.php` **no** se bindea: lo genera el entrypoint a partir de las variables `WORDPRESS_DB_*`. Un bind a un fichero inexistente haría que Podman creara un **directorio** en su lugar. `WORDPRESS_CONFIG_EXTRA` (una sola línea) define `WP_REDIS_HOST=redis`, `$_SERVER['HTTPS']=on` tras Traefik y `FORCE_SSL_ADMIN`. En la caché, `Exec=redis-server --save "" --appendonly no --maxmemory 128mb --maxmemory-policy allkeys-lru`.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|-----|-------|-------|-------------|
| WORDPRESS_DB_HOST | wordpress-wp1.container | mariadb | host de la BD (alias en wordpress-wp1.network) |
| WORDPRESS_DB_USER | wordpress-wp1.container | wp1 | usuario de la BD |
| WORDPRESS_DB_NAME | wordpress-wp1.container | wp1 | nombre de la BD |
| WORDPRESS_DB_PASSWORD | wordpress-wp1.container | secreto `wordpress_wp1_wordpress_db_password` (`type=env`) | contraseña de la BD |
| WORDPRESS_CONFIG_EXTRA | wordpress-wp1.container | una sola línea: `WP_REDIS_HOST` + HTTPS detrás de Traefik + `FORCE_SSL_ADMIN` | extras de `wp-config.php` |
| MARIADB_DATABASE | wordpress-wp1-mariadb.container | wp1 | base de datos |
| MARIADB_USER | wordpress-wp1-mariadb.container | wp1 | usuario de la BD |
| MARIADB_ROOT_PASSWORD | wordpress-wp1-mariadb.container | secreto `wordpress_wp1_mariadb_root_password` (`type=env`) | root de MariaDB |
| MARIADB_PASSWORD | wordpress-wp1-mariadb.container | secreto `wordpress_wp1_wordpress_db_password` (`type=env`) | contraseña del usuario de la BD (mismo valor que la app) |

## Cómo habilitar / desplegar
1. Secretos (NUNCA crypta store):
   `openssl rand -base64 32 | podman secret create wordpress_wp1_wordpress_db_password -`
   `openssl rand -base64 32 | podman secret create wordpress_wp1_mariadb_root_password -`
2. `cd .config/containers/available/wordpress-wp1 && qctl install`
3. `systemctl --user daemon-reload`

## Verificación E2E (2026-11-13)

Verificado en producción (`new_atareao`, usuario `runner`) y después purgado:

1. Units `wordpress-wp1`, `wordpress-wp1-mariadb` y `wordpress-wp1-redis` → `active`.
2. Los 3 contenedores → `Up (healthy)`.
3. Router `wordpress-wp1@docker` registrado en Traefik (servicio → `80`).
4. Certificado Let's Encrypt válido (`CN=wp1.<fqdn>`).
5. `https://wp1.${FQDN}/` → `302` a `/wp-admin/install.php`, que responde `200`.

Bugs latentes corregidos para llegar hasta aquí:

- Bind de `wp-config.php` a un fichero inexistente (Podman creaba un **directorio** en su lugar) → eliminado; además el volumen estaba en `/var/www/html` en vez de `/var/www/html/wp-content`.
- **Secreto de BD partido en dos** (`wordpress_wp1_mysql_password` vs `wordpress_wp1_wordpress_db_password`): app y BD usaban contraseñas distintas → unificado en `wordpress_wp1_wordpress_db_password`.
- Faltaban `Requires=`/`After=` hacia MariaDB y redis, healthchecks y `PodmanArgs=--init`.
- MariaDB sin pinnear (`mariadb` → `mariadb:11`, sin `AutoUpdate`), secretos `MYSQL_*` → `MARIADB_*`.

Purga: `qctl purge --secrets --images` (borra los secretos declarados; recrearlos antes de volver a desplegar).

## Follow-ups
- Ninguno.
