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
  - /data/self-hosted-podman/.config/containers/available/cells/cells-app.volume
  - /data/self-hosted-podman/.config/containers/available/cells/cells-data.volume
  - /data/self-hosted-podman/.config/containers/available/cells/cells-mysql.volume
- Config no secreta: /data/self-hosted-podman/.config/cells/cells.env (MYSQL_DATABASE, MYSQL_USER)
- Secretos: cells_mysql_root_password, cells_mysql_password

## Cómo funciona
Red: usa proxy.network y internal cells.network.
Volúmenes: cells-app.volume -> /var/cells (contenedor cells), cells-data.volume -> /var/cells/data (contenedor cells), cells-mysql.volume -> /var/lib/mysql (contenedor mysql).
Secretos: cells_mysql_root_password, cells_mysql_password.
Healthcheck: cells (`wget -q --spider http://127.0.0.1:8080/`), MySQL (`mysqladmin ping -h 127.0.0.1`).
Enrutado Traefik: Host(`cells.${FQDN}`), puerto 8080, middleware seguridadHeaders@file, compresionHeaders@file.
User/UserNS/NoNewPrivileges: N/A

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| CELLS_SITE_NO_TLS | Environment | 1 | Desactiva TLS dentro de la aplicación.
| CELLS_SITE_EXTERNAL | Environment | "https://cells.${FQDN}" | URL pública del sitio.
| MYSQL_DATABASE | EnvironmentFile | cells | Nombre de la base de datos.
| MYSQL_USER | EnvironmentFile | pydio | Usuario de la base de datos.

## Cómo habilitar / desplegar
1. Secretos (NUNCA crypta store):
   - `printf '%s' '<valor>' | podman secret create cells_mysql_root_password -`
   - `printf '%s' '<valor>' | podman secret create cells_mysql_password -`
2. `cd .config/containers/available/cells && qctl install`
3. `systemctl --user daemon-reload`

## Verificación E2E (2026-11-12)

Verificado en producción (`new_atareao`, usuario `runner`) y después purgado:

1. Units `cells-mysql` y `cells` → `active`.
2. Contenedores `cells-mysql` y `cells` → `Up (healthy)`.
3. Router `cells` registrado en Traefik.
4. Certificado Let's Encrypt válido para `cells.${FQDN}`.
5. `https://cells.${FQDN}` → `200` (interfaz de Pydio Cells).

Bugs latentes corregidos para llegar hasta aquí:

- `MYSQL_DATABASE`/`MYSQL_USER` se definían como `$MYSQL_DATABASE`/`$MYSQL_USER` sin origen: se movieron a `cells.env` y se cargan con `EnvironmentFile`.
- Faltaba la dependencia `Requires=`/`After=` de `cells` hacia `cells-mysql`.
- No había healthchecks en ninguno de los dos contenedores.

Purga: `qctl purge --secrets --images`. Sin restos.

## Follow-ups
- (ninguno)