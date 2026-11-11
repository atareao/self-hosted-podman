# wordpress-wp2 — Sitio WordPress independiente 2

## Qué es
wordpress-wp2, docker.io/library/wordpress, 3 contenedores, red: wordpress-wp2.network, dominio: wp2.${FQDN}, puerto interno: 80

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/wordpress-wp2/wordpress-wp2.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/wordpress-wp2/wordpress-wp2-mariadb.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/wordpress-wp2/wordpress-wp2-redis.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/wordpress-wp2/wordpress-wp2-data.volume
- Volumen(es): N/A
- Config no secreta: N/A
- Secretos: wordpress_wp2_wordpress_db_password

## Cómo funciona
- Red: wordpress-wp2.network vinculada a los contenedores
- Volúmenes: wordpress-wp2-data.volume montado en /var/www/html
- Secretos: wordpress_wp2_wordpress_db_password inyecta WORDPRESS_DB_PASSWORD
- EnvironmentFile: N/A
- Socket del daemon: N/A
- Healthcheck: N/A
- Enrutado Traefik: Host wp2.${FQDN} apunta al servicio 80
- User/UserNS/NoNewPrivileges: N/A

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|-----|-------|-------|-------------|
| WORDPRESS_DB_HOST | wordpress-wp2.container | mariadb | |
| WORDPRESS_DB_USER | wordpress-wp2.container | wp2 | |
| WORDPRESS_DB_NAME | wordpress-wp2.container | wp2 | |
| WORDPRESS_DB_PASSWORD | wordpress-wp2.container | (secreto) | |
| WORDPRESS_DB_HOST | wordpress-wp2-mariadb.container | db | |
| WORDPRESS_DB_USER | wordpress-wp2-mariadb.container | wp2 | |
| WORDPRESS_DB_NAME | wordpress-wp2-mariadb.container | wp2 | |
| WORDPRESS_DB_PASSWORD | wordpress-wp2-mariadb.container | (secreto) | |
| MYSQL_DATABASE | wordpress-wp2-mariadb.container | wp2 | |
| MYSQL_USER | wordpress-wp2-mariadb.container | wp2 | |
| MYSQL_PASSWORD | wordpress-wp2-mariadb.container | (secreto) | |
| MARIADB_ROOT_PASSWORD | wordpress-wp2-mariadb.container | (secreto) | |
| MARIADB_ROOT_PASSWORD_FILE | wordpress-wp2-mariadb.container | /run/secrets/wordpress_wp2_mariadb_root_password | |
| MYSQL_PASSWORD | wordpress-wp2-mariadb.container | /run/secrets/wordpress_wp2_mysql_password | |

## Cómo habilitar / desplegar
1. Secretos: `printf '%s' '\u003cvalor\u003e' | podman secret create wordpress_wp2_wordpress_db_password -`
2. `cd .config/containers/available/wordpress-wp2 && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
