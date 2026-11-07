# cells — plataforma de colaboración y edición de archivos con Docker y MySQL

## Qué es
*Imagen*:
- cells: docker.io/pydio/cells:latest
- cells-mysql: docker.io/library/mysql:8
*nº contenedores*: 2
*Red*: proxy.network, cells.network
*Dominio*: Host(`cells.${FQDN}`)
*Puerto interno*: 8080 (cells)

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/cells/cells.container
  - /data/self-hosted-podman/.config/containers/available/cells/cells-mysql.container
- Volumen(es):
  - /data/self-hosted-podman/.config/containers/available/cells/cells-cellsdir.volume
  - /data/self-hosted-podman/.config/containers/available/cells/cells-data.volume
  - /data/self-hosted-podman/.config/containers/available/cells/cells-mysqldir.volume
- Config no secreta: N/A
- Secretos: cells_mysql_root_password, cells_mysql_password

## Cómo funciona
Red: usa proxy.network y internal cells.network.
Volúmenes: cells-cellsdir.volume -> /var/cells (contenedor cells), cells-data.volume -> /var/cells/data (contenedor cells), cells-mysqldir.volume -> /var/lib/mysql (contenedor mysql).
Secretos: cells_mysql_root_password, cells_mysql_password.
Healthcheck: N/A
Enrutado Traefik: Host(`cells.${FQDN}`), puerto 8080, middleware seguridadHeaders@file, compresionHeaders@file.
User/UserNS/NoNewPrivileges: N/A

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| CELLS_SITE_NO_TLS | Environment | 1 | Desactiva TLS dentro de la aplicación.
| CELLS_SITE_EXTERNAL | Environment | "https://cells.${FQDN}" | URL pública del sitio.
| MYSQL_DATABASE | Environment | $MYSQL_DATABASE | Nombre de la base de datos.
| MYSQL_USER | Environment | $MYSQL_USER | Usuario de la base de datos.

## Cómo habilitar / desplegar
1. `cd .config/containers/available/cells && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)