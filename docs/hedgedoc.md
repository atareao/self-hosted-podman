# hedgedoc — Wiki colaborativo de código abierto

## Qué es
Hedgedoc es una aplicación web de wiki colaborativa que utiliza la base de datos MariaDB. Se ejecuta con las imágenes `lscr.io/linuxserver/hedgedoc:latest` y `lscr.io/linuxserver/mariadb:latest`. La stack cuenta con 2 contenedores, se conecta a las redes `proxy.network` y `hedgedoc.network`, y expone el subdominio `doc.${FQDN}` con el puerto interno `3000` gestionado por Traefik.

## Ficheros
- Quadlet(s):
  - `hedgedoc.container`
  - `hedgedoc-mariadb.container`
- Volumen(es):
  - `hedgedoc-config.volume`
  - `hedgedoc-data.volume`
- Config no secreta: *(ninguno)*
- Secretos: `hedgedoc_db_pass`, `hedgedoc_mysql_root_password`, `hedgedoc_mysql_password`

## Cómo funciona
- Red: Conexión a `proxy.network` para acceso público y a `hedgedoc.network` para conexión interna entre la aplicación y la base de datos.
- Volúmenes: Persistencia de la configuración y los datos en los volumes `hedgedoc-config` y `hedgedoc-data`.
- Secrets: Contraseñas de la base de datos a través de los secretos `hedgedoc_db_pass`, `hedgedoc_mysql_root_password` y `hedgedoc_mysql_password`.
- `EnvironmentFile`: Ninguno.
- `podman.socket`: No expuesto.
- Healthcheck: No definido.
- User: Los contenedores corre como UID 1000 (grafo) y UID 1000 para la base de datos.
- NoNewPrivileges: No habilitado.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| DB_HOST | hedgedoc | mariadb | host de la BD |
| DB_USER | hedgedoc | hedgedoc | usuario BD |
| DB_NAME | hedgedoc | hedgedoc | nombre BD |
| DB_PORT | hedgedoc | 3306 | puerto BD |
| PGID | hedgedoc | 1000 | group ID |
| PUID | hedgedoc | 1000 | user ID |
| TZ | hedgedoc | Europe/Madrid | zona horaria |
| CMD_DOMAIN | hedgedoc | doc.${FQDN} | dominio interno |
| CMD_URL_ADDPORT | hedgedoc | false |
| CMD_PROTOCOL_USESSL | hedgedoc | true |
| CMD_PORT | hedgedoc | 3000 |
| MYSQL_DATABASE | hedgedoc-mariadb | hedgedoc |
| MYSQL_USER | hedgedoc-mariadb | hedgedoc |
| TZ | hedgedoc-mariadb | Europe/Madrid |

## Cómo habilitar / desplegar
1. Secretos (solo si existen):
   - `printf '%s' '<valor>' | podman secret create hedgedoc_db_pass -`
   - `printf '%s' '<valor>' | podman secret create hedgedoc_mysql_root_password -`
   - `printf '%s' '<valor>' | podman secret create hedgedoc_mysql_password -`
2. `cd .config/containers/available/hedgedoc && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
