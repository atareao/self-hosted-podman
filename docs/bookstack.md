# bookstack — documentación Markdown alojada

## Qué es

- Aplicación: documentación/wiki Markdown autoalojada (BookStack)
- Imágenes: `lscr.io/linuxserver/bookstack:latest` y `lscr.io/linuxserver/mariadb:latest`
- Contenedores: 2 (`bookstack` app + `bookstack-mariadb` BD)
- Redes: `bookstack.network` (interna app↔BD) y `proxy.network` (front, solo la app)
- Dominio: `bookstack.${FQDN}`
- Puerto interno: 80 (app, expuesto a Traefik)

## Ficheros

- Quadlet(s):
  - `.config/containers/available/bookstack/bookstack.container`
  - `.config/containers/available/bookstack/bookstack-mariadb.container`
- Red: `.config/containers/available/bookstack/bookstack.network`
- Volumen(es): (ninguno con nombre; se usan binds)
  - App: `%h/.config/bookstack/config` → `/config` (`:Z`)
  - BD: `%h/.config/bookstack/mariadb` → `/config` (`:Z`)
- Config no secreta: `Environment=` de cada quadlet (no hay `.env` de stack)
- Secretos:
  - `bookstack_db_pass` → `DB_PASSWORD` (app)
  - `bookstack_app_key` → `APP_KEY` (app). Formato obligatorio `base64:<32 bytes aleatorios en base64>`;
    sin él el contenedor aborta con «The application key is missing, halting init!». Se inyecta con
    `Secret=bookstack_app_key,type=env,target=APP_KEY`.
  - `bookstack_mysql_root_password` → `MYSQL_ROOT_PASSWORD` (BD)
  - `bookstack_mysql_password` → `MYSQL_PASSWORD` (BD)

## Cómo funciona

- La **app** se une a dos redes: `bookstack.network` (donde resuelve la BD por su alias
  `bookstack_db`, que es lo que usa `DB_HOST`) y `proxy.network` (para que Traefik la publique en
  `bookstack.${FQDN}`). Antes solo estaba en `proxy.network`, así que `DB_HOST=bookstack_db` no
  resolvía y la app arrancaba sin poder conectar con la base.
- La **BD** (`bookstack-mariadb`) solo está en `bookstack.network` con `NetworkAlias=bookstack_db`.
- Dependencias: la app declara `After=bookstack-mariadb.service` / `Requires=bookstack-mariadb.service`
  más `traefik.service`; el orden con `proxy.network` lo genera el propio quadlet
  (`proxy-network.service`). La BD solo depende de `network-online.target`.
- **Binds separados** (antes los dos contenedores montaban `%h/.config/bookstack/config`, mezclando la
  config de la app con los datos de MariaDB): la app usa `%h/.config/bookstack/config` y MariaDB
  `%h/.config/bookstack/mariadb`. Crear ambos directorios antes de instalar y darles el UID/GID de
  `PUID`/`PGID` (1000) con `podman unshare chown -R 1000:1000 <dir>`.
- Ambas imágenes son LinuxServer.io y respetan `PUID`/`PGID`; el proceso no corre como root.
- **Sin `PodmanArgs=--init`**: las imágenes LinuxServer.io usan s6-overlay y exigen ser PID 1 (`s6-overlay-suexec: fatal: can only run as pid 1`); se omitió `--init` en ambos contenedores (verificado 2026-11-11). `AutoUpdate=registry` en ambos.
- Healthcheck no definido en los quadlets (no se añadió uno no verificado).
- **Nombres de variables de la imagen LinuxServer.io**: la app espera `DB_USERNAME` y `DB_PASSWORD`
  (no `DB_USER`/`DB_PASS`). El `.env.example` de la imagen usa esos nombres; con los antiguos
  BookStack caía al literal `database_username` y la conexión fallaba
  (`SQLSTATE[HY000] [1045] Access denied for user 'database_username'@...`, HTTP 500). El secreto
  sigue llamándose `bookstack_db_pass`; solo cambia su `target` a `DB_PASSWORD`.

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| PUID | Environment= | 1000 | UID del usuario de la aplicación |
| PGID | Environment= | 1000 | GID del grupo de la aplicación |
| APP_URL | Environment= | `https://bookstack.${FQDN}` | URL pública del servicio |
| DB_HOST | Environment= (`bookstack.container`) | `bookstack_db` | Host de la BD: alias de `bookstack-mariadb` en `bookstack.network` |
| DB_PORT | Environment= | `3306` | Puerto de la BD (valor por defecto de la imagen, explicitado) |
| DB_USERNAME | Environment= | `bookstack` | Usuario DB |
| DB_DATABASE | Environment= | `bookstackapp` | Base de datos |
| TZ | Environment= (`bookstack-mariadb.container`) | `Europe/Madrid` | Zona horaria de la BD |
| MYSQL_DATABASE | Environment= (`bookstack-mariadb.container`) | `bookstackapp` | Base de datos creada por la BD |
| MYSQL_USER | Environment= (`bookstack-mariadb.container`) | `bookstack` | Usuario creado por la BD |
| DB_PASSWORD | Secret=`bookstack_db_pass` (`type=env,target=DB_PASSWORD`) | *(secreto)* | Contraseña del usuario `bookstack` |
| APP_KEY | Secret=`bookstack_app_key` (`type=env,target=APP_KEY`) | *(secreto)* | Clave de aplicación Laravel; formato `base64:<32 bytes aleatorios en base64>`. Sin ella el contenedor aborta con «The application key is missing, halting init!» |
| MYSQL_PASSWORD | Secret=`bookstack_mysql_password` | *(secreto)* | Debe coincidir con `DB_PASSWORD` |
| MYSQL_ROOT_PASSWORD | Secret=`bookstack_mysql_root_password` | *(secreto)* | Contraseña root de MariaDB |

## Cómo habilitar / desplegar

1. Crear los directorios de los binds (uno por contenedor, no compartido):

   ```bash
   mkdir -p ~/.config/bookstack/config ~/.config/bookstack/mariadb
   podman unshare chown -R 1000:1000 ~/.config/bookstack/config ~/.config/bookstack/mariadb
   ```

2. Secretos (NUNCA `crypta store`):

   ```bash
   printf '%s' '<valor>' | podman secret create bookstack_db_pass -
   printf '%s' '<valor>' | podman secret create bookstack_mysql_password -
   printf '%s' '<valor>' | podman secret create bookstack_mysql_root_password -
   printf '%s' "base64:$(openssl rand -base64 32)" | podman secret create bookstack_app_key -
   ```

   `bookstack_db_pass` y `bookstack_mysql_password` deben tener el mismo valor. La `bookstack_app_key`
   debe llevar el prefijo `base64:` (formato que espera Laravel/BookStack); sin ella la app no arranca
   («The application key is missing, halting init!»). Recordatorio: **SIEMPRE `podman secret create`,
   nunca `crypta store`** (Podman resuelve por ID y `crypta store` deja la clave huérfana).

3. `cd .config/containers/available/bookstack && qctl install`
4. `systemctl --user daemon-reload`
5. `systemctl --user enable --now bookstack-mariadb bookstack`

Validación local sin tocar el host:

```bash
mkdir -p /tmp/qd/bookstack && cp .config/containers/available/bookstack/* /tmp/qd/bookstack/ \
  && cp .config/containers/available/traefik/proxy.network /tmp/qd/bookstack/ \
  && QUADLET_UNIT_DIRS=/tmp/qd/bookstack /usr/lib/podman/quadlet -user -dryrun
```

## Follow-ups

- Si ya había datos en `~/.config/bookstack/config` (bind compartido), mover los ficheros de MariaDB
  al nuevo `~/.config/bookstack/mariadb` antes de arrancar o la BD inicializará vacía.
- Valorar healthcheck (`/status` de BookStack y `mariadb-admin ping`) cuando se pueda verificar.
- `APP_KEY` se inyecta por el secreto `bookstack_app_key` (`Secret=…,type=env,target=APP_KEY`); si el
  contenedor aborta con «The application key is missing, halting init!», el secreto no existe o está
  vacío: recrearlo con
  `printf '%s' "base64:$(openssl rand -base64 32)" | podman secret create bookstack_app_key -`
  (**siempre `podman secret create`, nunca `crypta store`**). Rotar la `APP_KEY` con datos ya creados
  invalida las sesiones/cifrados previos, así que solo debe rellenarse en el primer despliegue.
- No aplica hardening adicional (`ReadOnly`, `NoNewPrivileges`); evaluar `ReadOnly` en la BD.
- **Verificado E2E el 2026-11-11 (PLAN-031 / issue #26)**: HTTP final 302 en `/` y 200 en `/login` (`https://bookstack.${FQDN}`); **purgado** tras la verificación.
