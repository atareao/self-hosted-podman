# dev — entorno de desarrollo local

## Qué es
Entorno con bases de datos, administración y CMS.
- **App**: dev
- **Imagen**: N/A (varias imágenes)
- **Contenedores**: 4
- **Red**: dev.network, proxy.network (phpmyadmin y wordpress)
- **Dominio**: ninguno definido por Traefik
- **Puerto interno**: ninguno expuesto a Traefik

## Ficheros
- **Quadlet(s)**:
  - /data/self-hosted-podman/.config/containers/available/dev/dev-mariadb.container
  - /data/self-hosted-podman/.config/containers/available/dev/dev-phpmyadmin.container
  - /data/self-hosted-podman/.config/containers/available/dev/dev-redis.container
  - /data/self-hosted-podman/.config/containers/available/dev/dev-wordpress.container
- **Volumen(es)**:
  - /data/self-hosted-podman/.config/containers/available/dev/dev-mariadb.volume
  - /data/self-hosted-podman/.config/containers/available/dev/dev-redis.volume
  - /data/self-hosted-podman/.config/containers/available/dev/dev-wordpress.volume
- **Config no secreta**: ninguna
- **Secretos**:
  - dev_mysql_password (target: MYSQL_PASSWORD)
  - dev_mariadb_root_password (target: MARIADB_ROOT_PASSWORD)
  - dev_wordpress_db_password (target: WORDPRESS_DB_PASSWORD)

## Cómo funciona
- **Red**: dev.network para MariaDB y Redis; proxy.network para phpMyAdmin y WordPress
- **Volúmenes**: datos persistentes de base de datos y de CMS
- **EnvironmentFile**: ninguna
- **Socket del daemon**: ninguno
- **Healthcheck**: ninguno
- **Enrutado Traefik**: ninguno
- **User/UserNS/NoNewPrivileges**: valores por defecto de container

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| MYSQL_DATABASE | Environment | dev | Nombre de la BD en MariaDB |
| MYSQL_USER | Environment | dev | Usuario de MariaDB |
| WORDPRESS_DB_HOST | Environment | mariadb | Host de la BD para WordPress |
| WORDPRESS_DB_USER | Environment | dev | Usuario de BD para WordPress |
| WORDPRESS_DB_NAME | Environment | dev | Nombre de BD para WordPress |

## Cómo habilitar / desplegar
1. `printf '%s' '<valor>' | podman secret create dev_mysql_password -`
2. `printf '%s' '<valor>' | podman secret create dev_mariadb_root_password -`
3. `printf '%s' '<valor>' | podman secret create dev_wordpress_db_password -`
4. `cd .config/containers/available/dev && qctl install`
5. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)
