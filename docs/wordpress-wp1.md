# wordpress-wp1 — Sitio WordPress independiente 1

## Qué es
wordpress-wp1, docker.io/library/wordpress, 3 contenedores, red: wordpress-wp1.network, dominio: wp1.${FQDN}, puerto interno: 80

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/wordpress-wp1/wordpress-wp1.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/wordpress-wp1/wordpress-wp1-mariadb.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/wordpress-wp1/wordpress-wp1-redis.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/wordpress-wp1/wordpress-wp1-data.volume
- Volumen(es): N/A
- Config no secreta: N/A
- Secretos: wordpress_wp1_wordpress_db_password

## Cómo funciona
- Red: wordpress-wp1.network vinculada a los contenedores
- Volúmenes: wordpress-wp1-data.volume montado en /var/www/html
- Secretos: wordpress_wp1_wordpress_db_password inyecta WORDPRESS_DB_PASSWORD
- EnvironmentFile: N/A
- Socket del daemon: N/A
- Healthcheck: N/A
- Enrutado Traefik: Host wp1.${FQDN} apunta al servicio 80
- User/UserNS/NoNewPrivileges: N/A

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|-----|-------|-------|-------------|
| WORDPRESS_DB_HOST | wordpress-wp1.container | mariadb | |
| WORDPRESS_DB_USER | wordpress-wp1.container | wp1 | |
| WORDPRESS_DB_NAME | wordpress-wp1.container | wp1 | |
| WORDPRESS_DB_PASSWORD | wordpress-wp1.container | (secreto) | |
| WORDPRESS_DB_HOST | wordpress-wp1-mariadb.container | db | |
| WORDPRESS_DB_USER | wordpress-wp1-mariadb.container | wp1 | |
| WORDPRESS_DB_NAME | wordpress-wp1-mariadb.container | wp1 | |
| WORDPRESS_DB_PASSWORD | wordpress-wp1-mariadb.container | (secreto) | |
| MYSQL_DATABASE | wordpress-wp1-mariadb.container | wp1 | |
| MYSQL_USER | wordpress-wp1-mariadb.container | wp1 | |
| MYSQL_PASSWORD | wordpress-wp1-mariadb.container | (secreto) | |
| MARIADB_ROOT_PASSWORD | wordpress-wp1-mariadb.container | (secreto) | |
| MARIADB_ROOT_PASSWORD_FILE | wordpress-wp1-mariadb.container | /run/secrets/wordpress_wp1_mariadb_root_password | |
| MYSQL_PASSWORD | wordpress-wp1-mariadb.container | /run/secrets/wordpress_wp1_mysql_password | |

## Cómo habilitar / desplegar
1. Secretos: `printf '%s' '\u003cvalor\u003e' | podman secret create wordpress_wp1_wordpress_db_password -`
2. `cd .config/containers/available/wordpress-wp1 && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
