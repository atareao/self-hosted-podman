# chevereto — gestor de contenidos web en Docker y MariaDB

## Qué es
*Imagen*:
- chevereto: ghcr.io/chevereto/chevereto:latest
- chevereto-mariadb: docker.io/library/mariadb
*nº contenedores*: 2
*Red*: proxy.network, chevereto.network
*Dominio*: Host(`chevereto.${FQDN}`)
*Puerto interno*: 80 (chevereto)

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/chevereto/chevereto.container
  - /data/self-hosted-podman/.config/containers/available/chevereto/chevereto-mariadb.container
- Volumen(es):
  - /data/self-hosted-podman/.config/containers/available/chevereto/chevereto-data.volume
  - /data/self-hosted-podman/.config/containers/available/chevereto/chevereto-mariadb.volume
- Config no secreta: N/A
- Secretos: chevereto_db_pass, chevereto_mysql_password, chevereto_mariadb_root_password

## Cómo funciona
Red: proxy.network y internal chevereto.network.
Volúmenes: chevereto-data.volume -> /var/www/html/images, chevereto-mariadb.volume -> /var/lib/mysql.
Secretos: chevereto_db_pass, chevereto_mysql_password, chevereto_mariadb_root_password.
Healthcheck: N/A
Enrutado Traefik: Host(`chevereto.${FQDN}`), puerto 80, middleware seguridadHeaders@file, compresionHeaders@file.
User/UserNS/NoNewPrivileges: N/A

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| CHEVERETO_DB_HOST | Environment | mariadb | Host de la BD.
| CHEVERETO_DB_USER | Environment | chevereto_user | Usuario de la BD.
| CHEVERETO_DB_PORT | Environment | 3306 | Puerto de la BD.
| CHEVERETO_DB_NAME | Environment | cheveretor | Nombre de la BD.
| CHEVERETO_ASSET_STORAGE_TYPE | Environment | local | Tipo de storage.
| CHEVERETO_ASSET_STORAGE_URL | Environment | /images/_assets | URL para assets.
| CHEVERETO_ASSET_STORAGE_BUCKET | Environment | /var/www/html/images/_assets | Bucket de almacenamiento.
| MYSQL_DATABASE | Environment | cheveretor | Nombre de BD en MariaDB.
| MYSQL_USER | Environment | chevereto_user | Usuario en MariaDB.

## Cómo habilitar / desplegar
1. `pd install`? Wait missing secrets.
1. Secretos: `printf '%s' '<valor>' | podman secret create chevereto_db_pass -`
2. `printf '%s' '<valor>' | podman secret create chevereto_mysql_password -`
3. `printf '%s' '<valor>' | podman secret create chevereto_mariadb_root_password -`
4. `cd .config/containers/available/chevereto && qctl install`
5. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)