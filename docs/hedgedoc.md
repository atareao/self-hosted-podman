# hedgedoc — Wiki colaborativo de código abierto

## Qué es
Hedgedoc es una aplicación web de wiki colaborativa que utiliza la base de datos MariaDB. Se ejecuta con las imágenes `lscr.io/linuxserver/hedgedoc:latest` y `lscr.io/linuxserver/mariadb:latest`. La stack cuenta con 2 contenedores, se conecta a las redes `proxy.network` y `hedgedoc.network`, y expone el subdominio `doc.${FQDN}` con el puerto interno `3000` gestionado por Traefik.

## Ficheros
- Quadlet(s):
  - `hedgedoc.container`
  - `hedgedoc-mariadb.container`
- Volumen(es):
  - `hedgedoc-config.volume` → `VolumeName=hedgedoc-config`
  - `hedgedoc-data.volume` → `VolumeName=hedgedoc-data`
  - ⚠️ **Los nombres están invertidos respecto a lo que sugerirían**: `hedgedoc-data` es el que monta **MariaDB** en `/config` (guarda la **base de datos**), mientras que `hedgedoc-config` es el que monta la **app** Hedgedoc en `/config` (guarda la **configuración de la aplicación**). Se mantienen así por compatibilidad; **no renombrar**.
- Config no secreta: *(ninguno)*
- Secretos: `hedgedoc_db_pass`, `hedgedoc_mysql_root_password`, `hedgedoc_mysql_password`

## Cómo funciona
- Red: Conexión a `proxy.network` para acceso público y a `hedgedoc.network` para conexión interna entre la aplicación y la base de datos.
- Orden de arranque: `hedgedoc` declara `After=... hedgedoc-mariadb.service` + `Requires=hedgedoc-mariadb.service` (además de `traefik.service`); `hedgedoc-mariadb` solo `After=network-online.target`.
- Volúmenes (**nombres invertidos, no renombrar**):
  - `hedgedoc-data.volume` → montado por `hedgedoc-mariadb` en `/config` → contiene la **base de datos MariaDB**.
  - `hedgedoc-config.volume` → montado por `hedgedoc` en `/config` → contiene la **configuración de la app Hedgedoc**.
- Secrets: Contraseñas de la base de datos a través de los secretos `hedgedoc_db_pass`, `hedgedoc_mysql_root_password` y `hedgedoc_mysql_password`.
- `EnvironmentFile`: Ninguno.
- `podman.socket`: No expuesto.
- Healthcheck: No definido.
- User: Los contenedores corre como UID 1000 (grafo) y UID 1000 para la base de datos.
- NoNewPrivileges: No habilitado.
- **Sin `PodmanArgs=--init`**: las imágenes LinuxServer.io usan s6-overlay y exigen ser PID 1 (`s6-overlay-suexec: fatal: can only run as pid 1`); se omitió `--init` en ambos contenedores (verificado 2026-11-11).
- `AutoUpdate=registry` en ambos contenedores (tags `:latest`).

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
- ⚠️ Nombres de volumen **invertidos** (`hedgedoc-data` = BD de MariaDB; `hedgedoc-config` = config de la app). Documentado y **no se renombra** para no romper datos existentes.
- La app Hedgedoc usa el secreto `hedgedoc_db_pass` (`DB_PASS`) y MariaDB usa `hedgedoc_mysql_password` (`MYSQL_PASSWORD`); deben contener **el mismo valor** aunque sean secretos distintos. No se han unificado en este cambio.
- **Verificado E2E el 2026-11-11 (PLAN-031 / issue #26)**: HTTP final 200 (`https://doc.${FQDN}`); **purgado** tras la verificación.
