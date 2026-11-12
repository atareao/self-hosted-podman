# chevereto — gestor de contenidos web en Docker y MariaDB

## Qué es
*Imagen*:
- chevereto: ghcr.io/chevereto/chevereto:latest
- chevereto-mariadb: docker.io/library/mariadb
*nº contenedores*: 2
*Red*: proxy.network, chevereto.network
*Dominio*: Host(`chevereto.${FQDN}`)
*Puerto interno*: 8080 (chevereto)

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
Healthcheck: chevereto (`curl -fsS -o /dev/null http://127.0.0.1:8080/`), MariaDB (`mariadb-admin ping -h 127.0.0.1`).
Enrutado Traefik: Host(`chevereto.${FQDN}`), puerto 8080, middleware seguridadHeaders@file, compresionHeaders@file.
User/UserNS/NoNewPrivileges: `User=0` (root dentro del contenedor); la imagen declara `USER www-data`, pero su Apache con módulo ssl intenta bindear 443 y no arranca como usuario no privilegiado.

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
- **`User=0`**: se ejecuta el contenedor como root porque la imagen (Apache + módulo ssl,
  `Listen 443`) no arranca como `www-data`. Alternativa más segura pendiente: montar un
  `ports.conf` propio sin el `Listen 443` para poder volver a `www-data`.
- **Licencia**: Chevereto V4 requiere clave de licencia para uso en producción; la verificación E2E
  solo comprobó que sirve el instalador.

## Verificación E2E (2026-11-12)

Verificado en producción (`new_atareao`, usuario `runner`) y después purgado:

1. Units `chevereto-mariadb` y `chevereto` → `active`.
2. Contenedores `chevereto` y `chevereto-mariadb` → `Up (healthy)`.
3. Router `chevereto@docker` registrado en Traefik (servicio → `8080`).
4. Certificado Let's Encrypt válido para `chevereto.${FQDN}`.
5. `https://chevereto.${FQDN}` → `302` (redirección a la instalación/`/install` de Chevereto).

Bugs latentes corregidos para llegar hasta aquí:

- El label de Traefik apuntaba al puerto **80**, pero el vhost de la imagen escucha en **8080**.
- La imagen declara `USER www-data`; su Apache (con módulo ssl, `Listen 443`) no puede bindear 443
  como no-root y el contenedor moría. Se ejecuta con `User=0`.
- El healthcheck usaba `wget`, que no existe en la imagen; se cambió a `curl` sobre el 8080.

Purga: `qctl purge --secrets --images` (sin `--data`, binds versionados).