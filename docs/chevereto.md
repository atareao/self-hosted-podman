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
- Config no secreta: /data/self-hosted-podman/.config/chevereto/chevereto.env (TZ)
- Secretos: chevereto_db_pass, chevereto_mariadb_root_password

## Cómo funciona
Red: proxy.network (chevereto) y chevereto.network (chevereto + mariadb).
Volúmenes: chevereto-data.volume -> /var/www/html/images, chevereto-mariadb.volume -> /var/lib/mysql.
Secretos: chevereto_db_pass (compartido por app y MariaDB), chevereto_mariadb_root_password.
Healthcheck: chevereto (`wget -q --spider http://127.0.0.1/`), MariaDB (`mariadb-admin ping -h 127.0.0.1`).
Enrutado Traefik: Host(`chevereto.${FQDN}`), puerto 80, middleware seguridadHeaders@file, compresionHeaders@file.
User/UserNS/NoNewPrivileges: N/A

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| TZ | EnvironmentFile | Europe/Madrid | Zona horaria (app y MariaDB).
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
1. Secretos (NUNCA crypta store):
   - `printf '%s' '<valor>' | podman secret create chevereto_db_pass -`
   - `printf '%s' '<valor>' | podman secret create chevereto_mariadb_root_password -`
2. `cd .config/containers/available/chevereto && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)