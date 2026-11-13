# wordpress — Plataforma de blogs y CMS

## Qué es
wordpress, docker.io/library/wordpress:latest, 3 contenedores, red: wordpress.network + proxy.network (wordpress), dominio: blog.${FQDN}, puerto interno: 80

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/wordpress/wordpress.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/wordpress/wordpress-mariadb.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/wordpress/wordpress-valkey.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/wordpress/wordpress-data.volume
- Volumen(es): /data/self-hosted-podman/.config/containers/available/wordpress/wordpress-mariadb.volume
- Red: /data/self-hosted-podman/.config/containers/available/wordpress/wordpress.network
- Config no secreta: N/A
- Secretos: wordpress_db_password, mariadb_root_password

## Cómo funciona
- Red: wordpress.network (wordpress + mariadb + valkey) y proxy.network (wordpress, para Traefik)
- Volúmenes: wordpress-data.volume montado en `/var/www/html/wp-content` (NO en `/var/www/html`), wordpress-mariadb.volume montado en /var/lib/mysql
- Secretos: wordpress_db_password inyecta WORDPRESS_DB_PASSWORD y MARIADB_PASSWORD (`type=env`), mariadb_root_password inyecta MARIADB_ROOT_PASSWORD (`type=env`)
- Socket del daemon: N/A
- `Requires=`/`After=`: `wordpress-mariadb.service` y `wordpress-valkey.service` (nombres reales de las units)
- Healthcheck: wordpress `curl -f http://localhost/wp-login.php`, MariaDB `mariadb-admin ping` con `$MARIADB_ROOT_PASSWORD`, valkey `valkey-cli ping`
- Enrutado Traefik: router/servicio `wordpress`, Host(`blog.${FQDN}`) → puerto 80
- `[Service]`: `TimeoutStartSec=300` (el primer arranque crea la BD) y `PodmanArgs=--init`
- User/UserNS/NoNewPrivileges: N/A

`wp-config.php` **no** se bindea: lo genera el entrypoint a partir de las variables `WORDPRESS_DB_*`. En `wordpress-wp1`/`wordpress-wp2` un bind a un fichero inexistente haría que Podman creara un **directorio** en su lugar.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|-----|-------|-------|-------------|
| WORDPRESS_DB_HOST | wordpress.container | mariadb | host de la BD (alias en wordpress.network) |
| WORDPRESS_DB_USER | wordpress.container | wp_user | usuario de la BD |
| WORDPRESS_DB_NAME | wordpress.container | wordpress | nombre de la BD |
| WORDPRESS_DB_PASSWORD | wordpress.container | secreto `wordpress_db_password` (`type=env`) | contraseña de la BD |
| WORDPRESS_CONFIG_EXTRA | wordpress.container | una sola línea: `WP_REDIS_HOST` + HTTPS detrás de Traefik + `FORCE_SSL_ADMIN` | extras de `wp-config.php` |
| MARIADB_ROOT_PASSWORD | wordpress-mariadb.container | secreto `mariadb_root_password` (`type=env`) | root de MariaDB |
| MARIADB_PASSWORD | wordpress-mariadb.container | secreto `wordpress_db_password` (`type=env`) | contraseña del usuario de la BD |
| MARIADB_DATABASE | wordpress-mariadb.container | wordpress | base de datos |
| MARIADB_USER | wordpress-mariadb.container | wp_user | usuario de la BD |

## Cómo habilitar / desplegar
1. Secretos (NUNCA crypta store):
   `openssl rand -base64 32 | podman secret create wordpress_db_password -`
   `openssl rand -base64 32 | podman secret create mariadb_root_password -`
2. `cd .config/containers/available/wordpress && qctl install`
3. `systemctl --user daemon-reload`

## Verificación E2E (2026-11-13)

Verificado en producción (`new_atareao`, usuario `runner`) y después purgado:

1. Units `wordpress`, `wordpress-mariadb` y `wordpress-valkey` → `active`.
2. Los 3 contenedores → `Up (healthy)`.
3. Router `wordpress@docker` registrado en Traefik (servicio → `80`).
4. Certificado válido con el resolver `letsencrypt-staging`.
5. `https://blog.${FQDN}/` → `302` a `/wp-admin/install.php`; `/wp-login.php` → `200`. Conexión a BD verificada (`DB OK`).

Bugs latentes corregidos para llegar hasta aquí:

- **Bloqueante**: `Requires=mariadb.service valkey.service` apuntaba a unidades **inexistentes** (las reales son `wordpress-mariadb.service` / `wordpress-valkey.service`); systemd fallaba el arranque en seco.
- Faltaba `traefik.http.services.wordpress.loadbalancer.server.port=80` y el router se llamaba `wp` (renombrado a `wordpress`).
- Secreto migrado del estilo mount (`/run/secrets/...` + `*_FILE`) a `type=env,target=WORDPRESS_DB_PASSWORD`.
- Los dos `WORDPRESS_CONFIG_EXTRA` fusionados en una sola línea (Redis + HTTPS detrás de Traefik + `FORCE_SSL_ADMIN`).
- Añadidos `TimeoutStartSec=300` y `PodmanArgs=--init`; completado el `HealthTimeout`.
- Saneados también `wordpress-mariadb.container` (secretos `type=env`, `After=`, healthcheck con `$MARIADB_ROOT_PASSWORD`) y `wordpress-valkey.container` (`[Unit]` y `[Service]` completos, `valkey-cli ping`, intervalos de healthcheck).
- **Ojo al purgar**: `qctl purge --secrets` borró `wordpress_db_password` y `mariadb_root_password` (existían de un despliegue previo). Hay que recrearlos antes de volver a desplegar.

Purga: `qctl purge --secrets --images`.

## Follow-ups
- **`wordpress-valkey.container`**: `Exec=valkey-server --save "" --appendonly no …`; el generador de quadlets trunca en `--save` y pierde `--appendonly`/`--maxmemory`. Mover la config a un `valkey.conf` o revisar el quoting.
- `wordpress` es la **plantilla** de `wordpress-wp1`/`wordpress-wp2` (lote 9): al clonarla, cambiar `ContainerName`, nombres de router/servicio, dominio, volúmenes y secretos.
