# facturascripts — Sistema de facturación web

## Qué es
**Aplicación**: facturascripts (image: `docker.io/facturascripts/facturascripts:latest`)
**Número de contenedores**: 2
**Red**: `proxy.network` + `facturascripts.network` (app) y `facturascripts.network` (MariaDB)
**Dominio**: `fs.${FQDN}`
**Puerto interno**: `80`

## Ficheros
- Quadlet(s):
  - `/data/self-hosted-podman/.config/containers/available/facturascripts/facturascripts.container`
  - `/data/self-hosted-podman/.config/containers/available/facturascripts/facturascripts-mariadb.container`
- Volumen(es):
  - `/data/self-hosted-podman/.config/containers/available/facturascripts/facturascripts-data.volume` (`:U` → `/var/www/html`)
  - `/data/self-hosted-podman/.config/containers/available/facturascripts/facturascripts-mariadb.volume` (`:U` → `/var/lib/mysql`)
- Red(es):
  - `/data/self-hosted-podman/.config/containers/available/facturascripts/facturascripts.network`
- Config no secreta: — (todo por `Environment=`)
- Secretos: `facturascripts_mariadb_root_password`, `facturascripts_mysql_password`,
  `facturascripts_db_password`, `facturascripts_initial_password`

## Cómo funciona
- La app está en `proxy.network` **y** en `facturascripts.network`; MariaDB solo en `facturascripts.network`.
  La app declara `Requires=`/`After=` sobre `facturascripts-mariadb.service`.
- Volúmenes **nombrados** con `:U` (antes binds a `~/.config/facturascripts/*`, que no existían): datos web
  en `facturascripts-data.volume` y MariaDB en `facturascripts-mariadb.volume`.
- MariaDB: `MYSQL_DATABASE=facturascripts`, `MYSQL_USER=facturascripts` y secretos
  `facturascripts_mariadb_root_password` (`MARIADB_ROOT_PASSWORD`) + `facturascripts_mysql_password`
  (`MYSQL_PASSWORD`). Sin `MARIADB_ROOT_PASSWORD` no arranca; sin `MYSQL_DATABASE`/`MYSQL_USER`/`MYSQL_PASSWORD`
  no se crea la BD. Healthcheck `mariadb-admin ping`.
- La app no tenía **ninguna** `Environment`; ahora lleva `FS_DB_*` (`TYPE=mysql`, `HOST=mariadb`, `PORT=3306`,
  `NAME`/`USER=facturascripts`), `FS_INITIAL_USER=admin` y `FS_LANG=es_ES`. La contraseña de BD va por
  `Secret=facturascripts_db_password` → `FS_DB_PASS` (mismo valor que `facturascripts_mysql_password`) y la
  del admin por `Secret=facturascripts_initial_password` → `FS_INITIAL_PASS`.
- **Las env solo rellenan los *defaults* del instalador**: no sustituyen al POST de instalación.
- Healthcheck de la app: no. Enrutado Traefik: puerto `80`.
- User/UserNS/NoNewPrivileges: no especificado.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| FS_DB_TYPE | Environment | `mysql` | Motor de BD |
| FS_DB_HOST | Environment | `mariadb` | Host de MariaDB (alias interno) |
| FS_DB_PORT | Environment | `3306` | Puerto de MariaDB |
| FS_DB_NAME | Environment | `facturascripts` | Base de datos |
| FS_DB_USER | Environment | `facturascripts` | Usuario de BD |
| FS_DB_PASS | `Secret=facturascripts_db_password` | aleatorio | Contraseña del usuario de BD |
| FS_INITIAL_USER | Environment | `admin` | Usuario administrador inicial |
| FS_INITIAL_PASS | `Secret=facturascripts_initial_password` | aleatorio | Contraseña del administrador |
| FS_LANG | Environment | `es_ES` | Idioma del instalador |
| MYSQL_DATABASE / MYSQL_USER | Environment (MariaDB) | `facturascripts` | Base y usuario a crear |
| MYSQL_PASSWORD | `Secret=facturascripts_mysql_password` | aleatorio | Contraseña del usuario de BD |
| MARIADB_ROOT_PASSWORD | `Secret=facturascripts_mariadb_root_password` | aleatorio | Root de MariaDB |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA `crypta store`):
   ```bash
   DB_PASS="$(openssl rand -base64 24)"
   printf '%s' "$(openssl rand -base64 24)" | podman secret create facturascripts_mariadb_root_password -
   printf '%s' "$DB_PASS" | podman secret create facturascripts_mysql_password -
   printf '%s' "$DB_PASS" | podman secret create facturascripts_db_password -
   printf '%s' "$(openssl rand -base64 24)" | podman secret create facturascripts_initial_password -
   ```
2. `cd .config/containers/available/facturascripts && qctl install`
3. `systemctl --user daemon-reload`

### Instalación desatendida
Con los contenedores arriba, el instalador se completa con un **POST a `/`** (`application/x-www-form-urlencoded`):

```bash
curl -sS -o /dev/null -w '%{http_code}\n' -X POST "https://fs.${FQDN}/" \
  --data-urlencode "fs_db_type=mysql" \
  --data-urlencode "fs_db_host=mariadb" \
  --data-urlencode "fs_db_port=3306" \
  --data-urlencode "fs_db_name=facturascripts" \
  --data-urlencode "fs_db_user=facturascripts" \
  --data-urlencode "fs_db_pass=${DB_PASS}" \
  --data-urlencode "fs_initial_user=admin" \
  --data-urlencode "fs_initial_pass=${ADMIN_PASS}" \
  --data-urlencode "fs_lang=es_ES" \
  --data-urlencode "fs_timezone=Europe/Madrid" \
  --data-urlencode "fs_install=1"
```

Tras el POST, `/` responde **302** a `/login`. El POST crea `config.php` y las tablas.

## Verificación E2E (2026-11-13)

Verificado en producción (`new_atareao`, usuario `runner`) con certificado `letsencrypt-staging`
(purgado después):

1. Units `facturascripts` y `facturascripts-mariadb` → `active`.
2. Contenedores arrancados (`podman ps`).
3. Router `facturascripts` registrado en Traefik.
4. Certificado staging válido para `fs.servidorlinux.es`.
5. Instalación desatendida correcta: `config.php` creado, tablas `users`, `empresas`, `diarios`, `series`,
   `pages`, `settings` y `attached_files`; login → **200**.

Bugs corregidos para llegar hasta aquí:

- La app **no estaba en `facturascripts.network`** (no resolvía `mariadb`).
- MariaDB **sin** `MARIADB_ROOT_PASSWORD` no arranca, y sin `MYSQL_DATABASE`/`MYSQL_USER`/`MYSQL_PASSWORD`
  no había base de datos.
- La app no tenía **ninguna** `Environment`: se añadieron `FS_DB_*`, `FS_INITIAL_*` y `FS_LANG=es_ES`.
- Binds a rutas inexistentes → volúmenes nombrados con `:U`.

## Follow-ups
- `latest` + `AutoUpdate`: el core de FacturaScripts vive dentro del volumen (`/var/www/html`), así que una
  actualización de imagen no actualiza el core por sí sola; revisar el flujo de actualización antes de
  confiar en `AutoUpdate`.
