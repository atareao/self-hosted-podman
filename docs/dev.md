# dev — entorno de desarrollo local

## Qué es
Entorno con bases de datos, administración y CMS.
- **App**: dev
- **Imagen**: N/A (varias imágenes)
- **Contenedores**: 4
- **Red**: dev.network, proxy.network (wordpress y phpmyadmin)
- **Dominio**: `dev.${FQDN}` (WordPress) y `dev-pma.${FQDN}` (phpMyAdmin)
- **Puerto interno**: 80 (WordPress y phpMyAdmin, tras Traefik)

## Ficheros
- **Quadlet(s)**:
  - /data/self-hosted-podman/.config/containers/available/dev/dev-mariadb.container
  - /data/self-hosted-podman/.config/containers/available/dev/dev-phpmyadmin.container
  - /data/self-hosted-podman/.config/containers/available/dev/dev-redis.container
  - /data/self-hosted-podman/.config/containers/available/dev/dev-wordpress.container
  - /data/self-hosted-podman/.config/containers/available/dev/dev.network
- **Volumen(es)**:
  - /data/self-hosted-podman/.config/containers/available/dev/dev-mariadb.volume
  - /data/self-hosted-podman/.config/containers/available/dev/dev-redis.volume
  - /data/self-hosted-podman/.config/containers/available/dev/dev-wordpress.volume
- **Config no secreta**: ninguna
- **Secretos**:
  - dev_wordpress_db_password (target: MARIADB_PASSWORD en MariaDB y WORDPRESS_DB_PASSWORD en WordPress)
  - dev_mariadb_root_password (target: MARIADB_ROOT_PASSWORD)

## Cómo funciona
- **Red**: dev.network para MariaDB, Redis, WordPress y phpMyAdmin; proxy.network además en phpMyAdmin y WordPress (para Traefik)
- **Volúmenes**: dev-mariadb (datos de MariaDB), dev-redis (datos de Redis) y dev-wordpress (`/var/www/html/wp-content`; no hay bind de `wp-config.php`)
- **EnvironmentFile**: ninguna
- **Socket del daemon**: ninguno
- **Healthcheck**: MariaDB (`mariadb-admin ping`), Redis (`redis-cli ping`) y WordPress (`curl http://localhost/wp-login.php`); phpMyAdmin no define ninguno
- **Enrutado Traefik**: WordPress en `dev.${FQDN}` (puerto 80) y phpMyAdmin en `dev-pma.${FQDN}` (puerto 80, middlewares `oidc-auth@file,seguridadHeaders@file,compresionHeaders@file`)
- **Dependencias**: WordPress arranca tras MariaDB y Redis (`After=`/`Requires=`); phpMyAdmin tras MariaDB
- **User/UserNS/NoNewPrivileges**: valores por defecto de container

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| MARIADB_DATABASE | Environment | dev | Nombre de la BD en MariaDB |
| MARIADB_USER | Environment | dev | Usuario de MariaDB |
| WORDPRESS_DB_HOST | Environment | mariadb | Host de la BD para WordPress |
| WORDPRESS_DB_USER | Environment | dev | Usuario de BD para WordPress |
| WORDPRESS_DB_NAME | Environment | dev | Nombre de BD para WordPress |
| WORDPRESS_CONFIG_EXTRA | Environment | WP_REDIS_HOST=redis + HTTPS tras proxy | Config extra de WordPress (Redis y SSL) |
| PMA_HOST | Environment | mariadb | Host de la BD para phpMyAdmin |
| PMA_PORT | Environment | 3306 | Puerto de la BD para phpMyAdmin |

## Cómo habilitar / desplegar
1. `printf '%s' '<valor>' | podman secret create dev_wordpress_db_password -`
2. `printf '%s' '<valor>' | podman secret create dev_mariadb_root_password -`
3. `cd .config/containers/available/dev && qctl install`
4. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)
