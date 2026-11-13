---
# PLAN-036 — Ronda E2E lote 8: codimd, huginn, planka, facturascripts, postgres

- **Issue:** #31
- **Fecha:** 2026-11-13
- **Estado:** PENDIENTE

## Objetivo

Continuar las rondas de verificación E2E en producción (`new_atareao`, usuario `runner`, rootless
Podman) con el lote 8: revisar estáticamente los 5 stacks candidatos, corregir los bugs latentes
detectados (dos de ellos con riesgo real de pérdida de datos), desplegar, verificar los puntos E2E
y purgar (unit, volúmenes, binds, secretos e imágenes) cada stack, dejando `docs/` y
`docs/estado-verificacion-e2e.md` actualizados.

## Contexto

- Repo de dotfiles (yadm), no aplicación: sin build/test/lint ni código de aplicación. Queda fuera
  del flujo OpenSpec/TDD global; el equivalente a verificación es la comprobación E2E por CLI,
  como en los lotes 1–7.
- Inventario de partida: 127 stacks = 92 verificados + 4 en producción + 3 bloqueados/hallazgos +
  28 sin verificar. Al cerrar este lote, si los 5 pasan: **127 = 97 + 4 + 3 + 23**
  (comprobación: 92+5=97; 28−5=23; 97+4+3+23=127).
- Flujo de despliegue/purga: `docs/gestion-stacks-qctl.md`. Invariantes de enrutado:
  `docs/traefik.md`. IP real tras el proxy: `docs/trusted-proxy.md`.
- Producción **solo** como `runner` vía wrapper `rr` desde `lorenzo`. Secretos con
  `podman secret create`, **nunca** `crypta store`. TLS con el resolver `letsencrypt-staging`
  durante la verificación y revertir antes del `yadm pull`.
- Un stack que no se resuelva en tiempo razonable se documenta, se purga y queda como bloqueado;
  el lote no se bloquea por él.

## Alcance

| Stack | Por qué entra en el lote |
|---|---|
| `codimd` | Red propia sin declarar (solo `proxy.network`), sin orden frente a Postgres, imagen de BD `postgres:11.6-alpine` (EOL) y bind `data":Z` con comilla huérfana. |
| `huginn` | Web y worker sin BD configurada (`mysql2`/host/puerto) ni dependencia de MariaDB; `APP_SECRET_TOKEN` sin secreto. |
| `planka` | Red propia sin declarar en el `[Container]` y `TRUST_PROXY=0`, que rompe la IP real detrás de Traefik. |
| `facturascripts` | App sin red propia ni dependencias, BD por variables sin secretos, binds de datos en lugar de volúmenes. |
| `postgres` | **Pérdida de datos**: `postgres:latest` (18.x) mueve el `VOLUME` a `/var/lib/postgresql`, así que el volumen en `/var/lib/postgresql/data` no se usa. |

**Aplazado:** `grafana-influx-telegraf` **no entra** en este lote. Solapa funcionalmente con
`openobserve` + `vector` + `alloy` (métricas, logs y dashboards ya cubiertos) y la decisión de
consolidar o retirar esa pila se toma en un plan propio.

## Criterio de «verificado E2E»

1. El unit systemd queda `active`.
2. El contenedor arranca (`podman ps`, estado `healthy`).
3. Traefik registra el router (`traefik.enable=true`, router visible en el API/dashboard).
4. El certificado sirve el dominio con cadena válida (CA staging de Let's Encrypt).
5. La URL responde con el HTTP esperado.

Excepción documentada: `postgres` no tiene router HTTP propio; se verifica por el estado `healthy`
del unit y por conectividad `TCP 5432` desde `pgadmin`. `pgadmin` sí se verifica por HTTP.

## Correcciones a aplicar

### `codimd/codimd.container`

- `Networks`: añadir la red propia del stack manteniendo la de Traefik:
  - `Network=codimd.network`
  - `NetworkAlias=codimd`
- `[Unit]`: `After=network-online.target codimd-postgresql.service traefik.service` y
  `Requires=codimd-postgresql.service` (hoy solo `network-online.target traefik.service`).
- `Environment`:
  - `Environment=CMD_DOMAIN=codimd.${FQDN}`
  - `Environment=CMD_PROTOCOL_USESSL=true`
  - `Environment=CMD_URL_ADDPORT=false`
- `Secrets`:
  - `Secret=codimd_db_url,type=env,target=CMD_DB_URL` (URL completa, ver más abajo)
  - `Secret=codimd_session_secret,type=env,target=CMD_SESSION_SECRET`
- `Volumes`: el bind de uploads pasa a **volumen nombrado** con `:U` (evita chowns manuales en
  rootless): `Volume=codimd-uploads.volume:/home/hackmd/app/public/uploads:U`.

### `codimd/codimd-postgresql.container`

- `Image`: `postgres:11.6-alpine` → **`postgres:17-alpine`**. La 11 está EOL y el datadir está
  vacío, así que no hay migración de datos que hacer.
- `Environment`: `POSTGRES_USER=codimd`, `POSTGRES_DB=codimd`; la contraseña va por secreto
  (`Secret=codimd_postgres_password,type=env,target=POSTGRES_PASSWORD`).
- `Volumes`: corregir la comilla huérfana `data":Z` → `data:Z` y sustituir el bind
  `%h/.config/codimd/codimddb` por el **volumen nombrado** `codimd-postgresql.volume` con `:U`.
- `Healthcheck`: `pg_isready -U codimd -d codimd` (HealthInterval 30s, Retries 5, Timeout 5s,
  StartPeriod 20s) para que el `Requires=`/`After=` del app tenga sentido.
- `[Unit]`: `Description` correcto del rol (PostgreSQL de CodiMD).

### `huginn/huginn.container` (web)

- `Networks`: añadir `Network=huginn.network` (hoy solo `proxy.network`) + `NetworkAlias=mariadb`
  **no** aquí, sino en el unit de MariaDB; el web conserva su alias actual.
- `[Unit]`: `After=network-online.target huginn-mariadb.service traefik.service` y
  `Requires=huginn-mariadb.service`.
- `Environment` (BD):
  - `Environment=DATABASE_ADAPTER=mysql2`
  - `Environment=DATABASE_HOST=mariadb`
  - `Environment=DATABASE_PORT=3306`
- `Secrets`: `Secret=huginn_app_secret_token,type=env,target=APP_SECRET_TOKEN`.

### `huginn/huginn-threaded.container` (worker)

- Mismas tres variables de BD que el web (`DATABASE_ADAPTER=mysql2`, `DATABASE_HOST=mariadb`,
  `DATABASE_PORT=3306`) y `Secret=huginn_app_secret_token,type=env,target=APP_SECRET_TOKEN`.
- `[Unit]`: `After=network-online.target huginn-mariadb.service` y
  `Requires=huginn-mariadb.service`.
- `Network=huginn.network` (coherente con el web).

### `huginn/huginn-mariadb.container`

- `[Unit] / Description`: corregir el texto actual (describía el stack web, no la BD).
- Mantener `Network=huginn.network` + `NetworkAlias=mariadb` (el host `mariadb` que usan web y
  worker resuelve por ahí).
- Variables `MARIADB_*`/`MYSQL_*` con sus secretos (`huginn_database_password`,
  `huginn_mysql_password` con **el mismo valor**, `huginn_mariadb_root_password`).

### `planka/planka.container`

- `Networks`: añadir `Network=planka.network` (hoy solo `proxy.network`), con su `NetworkAlias`.
- `Environment`:
  - `Environment=BASE_URL=https://planka.${FQDN}` (sin comillas; hoy van entrecomillado).
  - `Environment=TRUST_PROXY=true` (hoy `0`, lo que rompe la IP real detrás de Traefik).
- `Secrets`: `Secret=planka_secret_key,type=env,target=SECRET_KEY`.

### `facturascripts/facturascripts.container`

- `Networks`: añadir `Network=facturascripts.network`.
- `[Unit]`: `After=network-online.target facturascripts-mariadb.service traefik.service` y
  `Requires=facturascripts-mariadb.service`.
- `Environment`:
  - `Environment=FS_DB_TYPE=mysql`
  - `Environment=FS_DB_HOST=mariadb`
  - `Environment=FS_DB_PORT=3306`
  - `Environment=FS_DB_NAME=facturascripts`
  - `Environment=FS_DB_USER=facturascripts`
  - `Environment=FS_INITIAL_USER=admin`
  - `Environment=FS_LANG=es_ES`
- `Secrets`:
  - `Secret=facturascripts_db_password,type=env,target=FS_DB_PASS`
  - `Secret=facturascripts_db_password,type=env,target=FS_INITIAL_PASS`
  (mismo valor, dos targets distintos.)
- `Volumes`: el bind `%h/.config/facturascripts/facturascripts` pasa a **volumen nombrado**
  `facturascripts-data.volume` con `:U`.

### `facturascripts/facturascripts-mariadb.container`

- `Environment`:
  - `Environment=MYSQL_DATABASE=facturascripts`
  - `Environment=MYSQL_USER=facturascripts`
- `Secrets`:
  - `Secret=facturascripts_mariadb_root_password,type=env,target=MARIADB_ROOT_PASSWORD`
  - `Secret=facturascripts_mysql_password,type=env,target=MYSQL_PASSWORD`
- `Volumes`: el bind `%h/.config/facturascripts/mariadb` pasa a **volumen nombrado**
  `facturascripts-mariadb.volume` con `:U`.
- `[Unit] / Description`: corregir el texto (describía la app, no la BD).
- `Network=facturascripts.network` + `NetworkAlias=mariadb` (host usado por la app).

### `postgres/postgres-postgres.container`

- **Bug de pérdida de datos**: con `postgres:latest` (serie 18.x) la imagen declara `VOLUME
  /var/lib/postgresql` y guarda el cluster en `/var/lib/postgresql/18/docker`, mientras el quadlet
  monta `postgres-data.volume` en `/var/lib/postgresql/data`: **el volumen no se usa** y cada
  recreación arranca de cero. Fix: pinnear **`postgres:17-alpine`** y mantener el montaje en
  `/var/lib/postgresql/data`.
- `Image`: **quitar `AutoUpdate=registry`** en una BD: los saltos de major rompen el datadir.
- `Healthcheck`: añadir `HealthCmd=pg_isready -U root -d test_db` (HealthInterval 30s, Retries 5,
  Timeout 5s, StartPeriod 20s); el `ExecStartPost` y el criterio E2E lo necesitan.

### `postgres/postgres-pgadmin.container`

- `Networks`: añadir `Network=postgres.network` (hoy solo `proxy.network`), con su
  `NetworkAlias`; sin esto pgadmin no resuelve el host `postgres`.
- `Secrets`: `Secret=postgres_pgadmin_default_password,type=env,target=PGADMIN_DEFAULT_PASSWORD`
  junto a las credenciales de login de pgadmin.

## Secretos a crear

Todos nuevos (ninguno existe hoy). Ejecutar como `runner` (vía `rr`) **antes** de `qctl install`:

```bash
openssl rand -base64 32 | podman secret create codimd_postgres_password -
openssl rand -base64 32 | podman secret create codimd_session_secret -
openssl rand -base64 32 | podman secret create huginn_app_secret_token -
openssl rand -base64 32 | podman secret create huginn_database_password -
openssl rand -base64 32 | podman secret create huginn_mariadb_root_password -
openssl rand -base64 32 | podman secret create planka_secret_key -
openssl rand -base64 32 | podman secret create facturascripts_db_password -
openssl rand -base64 32 | podman secret create facturascripts_mariadb_root_password -
openssl rand -base64 32 | podman secret create postgres_password -
openssl rand -base64 32 | podman secret create postgres_pgadmin_default_password -
```

- `codimd_db_url`: URL completa construida **con el mismo password** de
  `codimd_postgres_password`:
  ```bash
  PW=$(podman secret inspect codimd_postgres_password --showsecret --format '{{.SecretData}}' 2>/dev/null || true)
  # si no se puede leer, generar una sola vez y usar el mismo valor en ambos secretos:
  PW=$(openssl rand -base64 32 | tr -d '\n')
  printf 'postgres://codimd:%s@codimd-postgresql:5432/codimd' "$PW" | podman secret create codimd_db_url -
  printf '%s' "$PW" | podman secret create codimd_postgres_password -
  ```
- `huginn_mysql_password`: **mismo valor** que `huginn_database_password` (es el password del
  usuario de la app visto por MariaDB).
- `facturascripts_mysql_password`: **mismo valor** que `facturascripts_db_password`.
- Recordatorio: **nunca** `crypta store` para estos nombres; el driver `shell` resuelve por ID
  del secreto.

## Despliegue E2E

Todo con `rr "<comando>"`. Antes de empezar, bajar el resolver a `letsencrypt-staging` en los
`.container` implicados y verificar `podman secret ls`.

1. Renderizar plantillas si hiciera falta (`unjinja`) para que existan los units/volúmenes reales
   en `available/<stack>/` antes de enlazar.
2. Por stack, desde su directorio:
   ```bash
   cd ~/.config/containers/available/<stack> && qctl install
   ```
3. `systemctl --user daemon-reload` y `qctl status` en cada stack.
4. Seguir el arranque: `journalctl --user -u <unit> -f` (`jcu`/`jcf`) hasta `healthy`.
5. Verificación de los 5 puntos:
   ```bash
   systemctl --user is-active <unit>
   podman ps --filter name=<container>
   curl -sS -o /dev/null -w '%{http_code}\n' https://<host>/
   echo | openssl s_client -connect <host>:443 -servername <host> 2>/dev/null | openssl x509 -noout -dates -issuer
   ```
   (el emisor debe ser la CA *staging* de Let's Encrypt).
6. Si tras recrear el contenedor no enruta, `systemctl --user restart traefik` y reintentar.
7. Orden recomendado dentro del lote: primero las BD (`codimd`, `huginn`, `facturascripts`,
   `postgres`), luego las apps; `postgres` al final por su comprobación de conectividad desde
   `pgadmin`.

## Verificación específica por stack

- **codimd** (`https://codimd.<fqdn>/`): `HTTP 200/302` en `/`; `/new` responde y la sesión de
  edición se crea sin error de BD (`podman logs codimd-postgresql` sin `authentication failed`);
  comprobar que `CMD_DOMAIN`/`CMD_PROTOCOL_USESSL` están en `podman inspect`.
- **huginn** (`https://huginn.<fqdn>/`): 200 y **registro/login** de un usuario nuevo; el worker
  (`huginn-threaded`) arranca sin `Access denied for user` contra `mariadb`.
- **planka** (`https://planka.<fqdn>/`): 200 y **login** con el usuario sembrado; comprobar que
  `TRUST_PROXY=true` y `BASE_URL` sin comillas en `podman inspect`.
- **facturascripts** (`https://fs.<fqdn>/`): 200 en el asistente y **instalación desatendida** por
  POST con las credenciales de los secretos, seguida de login:
  ```bash
  # el formulario del instalador acepta los parámetros por POST (mismos valores que el quadlet)
  curl -sS -X POST https://fs.<fqdn>/install.php \
    --data-urlencode 'fs_db_type=mysql' \
    --data-urlencode 'fs_db_host=mariadb' \
    --data-urlencode 'fs_db_port=3306' \
    --data-urlencode 'fs_db_name=facturascripts' \
    --data-urlencode 'fs_db_user=facturascripts' \
    --data-urlencode "fs_db_pass=$(podman secret inspect facturascripts_db_password --showsecret --format '{{.SecretData}}')" \
    --data-urlencode 'fs_lang=es_ES' \
    --data-urlencode 'fs_initial_user=admin' \
    --data-urlencode "fs_initial_pass=$(podman secret inspect facturascripts_db_password --showsecret --format '{{.SecretData}}')" \
    -o /tmp/fs-install.html -w '%{http_code}\n'
  # luego: login en https://fs.<fqdn>/ con admin / <secreto> y comprobar el dashboard
  ```
  Si la versión del instalador no admite POST directo, completar el asistente por UI y **anotar en
  `docs/facturascripts.md`** el método real usado.
- **postgres**: unit `postgres-postgres.service` `active` y contenedor `healthy`
  (`pg_isready -U root -d test_db`); desde dentro de `pgadmin` verificar `TCP 5432` contra el host
  `postgres` (`python3 -c "import socket;socket.create_connection(('postgres',5432),5)"` o
  `psql -h postgres -U root -d test_db -c 'select 1'` según lo que traiga la imagen); UI de
  pgadmin en `https://pgadmin.<fqdn>/` con login.

## Purga y cierre

1. Por stack, desde su directorio: `qctl purge --secrets --images` (**sin** `--data`: no se borran
   los binds de usuario, solo unit, volúmenes nombrados, secretos e imágenes).
2. Comprobar el estado limpio:
   ```bash
   podman ps -a --filter name=<stack>        # 0 contenedores
   podman volume ls | grep <stack>           # 0 volúmenes
   podman secret ls | grep -E 'codimd_|huginn_|planka_secret_key|facturascripts_|postgres_password|postgres_pgadmin'
   ls -l ~/.config/containers/systemd/ | grep <stack>   # 0 symlinks
   ```
   Documentar qué binds de usuario (`~/.config/<stack>/…`) quedan huérfanos tras migrar a
   volúmenes nombrados y si se borran a mano o se conservan.
3. Revertir el resolver `letsencrypt-staging` → `letsencrypt` en los quadlets y `daemon-reload`.
4. Actualizar `docs/estado-verificacion-e2e.md`:
   - Añadir las 5 filas a «Verificados E2E».
   - Quitar los 5 nombres de «Sin verificar E2E».
   - Ajustar el resumen a **127 = 97 verificados + 4 en producción + 3 bloqueados + 23 sin
     verificar** (aritmética comprobada: 92+5=97; 28−5=23; 97+4+3+23=127).
   - Añadir la entrada de PLAN-036 en «Notas» con los bugs corregidos, incluida la pérdida de
     datos de `postgres` y el aplazamiento de `grafana-influx-telegraf`.
5. Actualizar `docs/codimd.md`, `docs/huginn.md`, `docs/planka.md`, `docs/facturascripts.md` y
   `docs/postgres.md` con los hallazgos (bugs corregidos, valores finales, método de instalación
   desatendida, follow-ups abiertos).
6. Renombrar este plan a `plans/PLAN-036-ARCHIVED.md` y marcar todas las tareas.

## Riesgos conocidos

- **`postgres` es el riesgo alto del lote**: el volumen actual nunca se usó (imagen 18.x), así que
  no hay datos que perder, pero cualquier intento de "arreglarlo" arrancando la 18 sobre
  `/var/lib/postgresql/data` crearía un cluster nuevo y confuso. Pinnear 17-alpine **antes** de
  desplegar.
- `codimd` cambia de `postgres:11.6-alpine` a 17: al estar el datadir vacío no hay `pg_upgrade`,
  pero si apareciera contenido inesperado, abortar y documentar antes de tocar el volumen.
- `huginn` depende de que el password del usuario MySQL coincida con el de la app
  (`huginn_database_password` = `huginn_mysql_password`). Si se generan por separado, el worker
  falla en bucle con `Access denied`.
- `facturascripts` puede no aceptar la instalación desatendida por POST según versión: el plan
  prevé el fallback por UI y la documentación del método real.
- `TRUST_PROXY=true` en `planka` asume que la única entrada es Traefik (`10.89.0.0/24`); si en el
  futuro se publica el puerto, habría que pasar a lista de CIDR de confianza.
- Migrar binds a volúmenes nombrados con `:U` cambia la propiedad de los ficheros: verificar que
  no queda ningún otro unit apuntando a esos paths.
- El driver de secretos `crypta` exige `SOPS_AGE_KEY_FILE` y `~/.local/bin` en el entorno del
  systemd user manager para los healthchecks (ver `docs/secrets-healthcheck.md`).
- `grafana-influx-telegraf` queda fuera: no tocar sus units en este lote para no mezclar
  decisiones de consolidación con la verificación.

## Tareas

- [ ] Comprobar estado de partida: `podman secret ls`, resolver actual de los 5 stacks,
      inventario de `docs/estado-verificacion-e2e.md` y confirmar que `grafana-influx-telegraf`
      queda fuera del lote.
- [ ] Corregir `codimd.container` (red propia, `[Unit]`, `CMD_DOMAIN`/`PROTOCOL_USESSL`/
      `URL_ADDPORT`, secretos, uploads a volumen).
- [ ] Corregir `codimd-postgresql.container` (17-alpine, usuario/BD, secreto, `data":Z` →
      `data:Z`, volumen nombrado con `:U`, healthcheck, `Description`).
- [ ] Corregir `huginn.container` (red propia, `[Unit]`, `mysql2`/host/puerto, `APP_SECRET_TOKEN`).
- [ ] Corregir `huginn-threaded.container` (mismas env, `Requires=`/`After=`, red).
- [ ] Corregir `huginn-mariadb.container` (`Description`, alias `mariadb`, secretos).
- [ ] Corregir `planka.container` (`Network=planka.network`, `BASE_URL` sin comillas,
      `TRUST_PROXY=true`, `SECRET_KEY`).
- [ ] Corregir `facturascripts.container` (red, `[Unit]`, `FS_*`, secretos, volumen `:U`).
- [ ] Corregir `facturascripts-mariadb.container` (`MYSQL_*`, secretos, volumen `:U`,
      `Description`, alias `mariadb`).
- [ ] Corregir `postgres-postgres.container` (pin 17-alpine, sin `AutoUpdate`, healthcheck).
- [ ] Corregir `postgres-pgadmin.container` (`Network=postgres.network`, secreto de admin).
- [ ] Crear los 13 secretos listados (con los valores compartidos: `codimd_db_url` ↔
      `codimd_postgres_password`, `huginn_mysql_password` ↔ `huginn_database_password`,
      `facturascripts_mysql_password` ↔ `facturascripts_db_password`).
- [ ] Desplegar los 5 stacks (`qctl install` + `daemon-reload` + `qctl status`).
- [ ] Verificar los 5 puntos E2E por stack + verificación específica (codimd 200/302, huginn
      registro/login, planka login, facturascripts instalación desatendida + login, postgres
      `healthy` + TCP 5432 desde pgadmin + UI).
- [ ] Purgar los 5 stacks (`qctl purge --secrets --images`) y comprobar 0 contenedores/
      volúmenes/symlinks.
- [ ] Revertir `letsencrypt-staging` y `daemon-reload`.
- [ ] Actualizar `docs/estado-verificacion-e2e.md` (97 / 4 / 3 / 23) y los 5 `docs/<stack>.md`.
- [ ] Renombrar a `plans/PLAN-036-ARCHIVED.md`.
