# wordpress — Plataforma de blogs y CMS

## Qué es
wordpress, docker.io/library/wordpress:latest, 3 contenedores, red: wordpress.network, dominio: blog.${FQDN}, puerto interno: 80

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/wordpress/wordpress.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/wordpress/wordpress-mariadb.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/wordpress/wordpress-valkey.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/wordpress/wordpress.volume
- Volumen(es): /data/self-hosted-podman/.config/containers/available/wordpress/wordpress-mariadb.volume
- Config no secreta: N/A
- Secretos: wordpress_db_password, mariadb_root_password

## Cómo funciona
- Red: wordpress.network vinculada a los contenedores
- Volúmenes: wordpress.volume montado en /var/www/html, wordpress-mariadb.volume montado en /var/lib/mysql
- Secretos: wordpress_db_password inyecta WORDPRESS_DB_PASSWORD, mariadb_root_password inyecta MARIADB_ROOT_PASSWORD_FILE
- EnvironmentFile: N/A
- Socket del daemon: N/A
- Healthcheck: WordPress healthcheck con curl a /wp-login.php
- Enrutado Traefik: Host blog.${FQDN} apunta al servicio 80
- User/UserNS/NoNewPrivileges: N/A

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|-----|-------|-------|-------------|
| WORDPRESS_DB_HOST | wordpress.container | mariadb | |
| WORDPRESS_DB_USER | wordpress.container | wp_user | |
| WORDPRESS_DB_NAME | wordpress.container | wordpress | |
| WORDPRESS_DB_PASSWORD_FILE | wordpress.container | /run/secrets/wordpress_db_password | |
| WORDPRESS_CONFIG_EXTRA | wordpress.container | define('WP_REDIS_HOST', 'valkey'); | |
| WORDPRESS_DB_HOST | wordpress-mariadb.container | db | |
| WORDPRESS_DB_USER | wordpress-mariadb.container | wp_user | |
| WORDPRESS_DB_NAME | wordpress-mariadb.container | wordpress | |
| WORDPRESS_DB_PASSWORD_FILE | wordpress-mariadb.container | /run/secrets/wordpress_db_password | |
| MARIADB_ROOT_PASSWORD_FILE | wordpress-mariadb.container | /run/secrets/mariadb_root_password | |
| MARIADB_PASSWORD_FILE | wordpress-mariadb.container | /run/secrets/wordpress_db_password | |
| MARIADB_DATABASE | wordpress-mariadb.container | wordpress | |
| MARIADB_USER | wordpress-mariadb.container | wp_user | |

## Cómo habilitar / desplegar
1. Secretos: `printf '%s' '\u003cvalor\u003e' | podman secret create wordpress_db_password -`
`printf '%s' '\u003cvalor\u003e' | podman secret create mariadb_root_password -`
2. `cd .config/containers/available/wordpress && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
