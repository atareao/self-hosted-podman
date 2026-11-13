# huginn — Automatización de tareas y workflows

## Qué es

`huginn` es un sistema de agentes que monitorizan servicios y actúan (scraping, RSS, webhooks,
notificaciones). Se despliega con **tres contenedores** detrás de Traefik:

| Contenedor (quadlet) | Imagen | Rol | Puerto |
|---|---|---|---|
| `huginn` (`huginn.container`) | `docker.io/huginn/huginn-single-process` | Interfaz web | `3000` (vía Traefik) |
| `huginn-threaded` (`huginn-threaded.container`) | `docker.io/huginn/huginn-single-process` | Worker de tareas (`WORKER_CMD=bin/threaded.rb`) | — |
| `huginn-mariadb` (`huginn-mariadb.container`) | `docker.io/library/mariadb` | Base de datos | — |

Los dos contenedores de aplicación **comparten la misma imagen pero tienen roles distintos**: la web
sirve la UI y el worker consume la cola de trabajos. **No son duplicados** (mismo patrón que otros
stacks con worker, p. ej. `wger`).

- **Redes:** `huginn.network` (interna del stack) para los tres; solo la web se une además a `proxy.network`.
  La BD lleva `NetworkAlias=mariadb`, que es el host usado por la app.
- **Dominio:** `huginn.${FQDN}` (subdominio) → router `huginn`, servicio `huginn`, puerto interno `3000`.

## Ficheros

- Quadlet(s):
  - `.config/containers/available/huginn/huginn.container` (web)
  - `.config/containers/available/huginn/huginn-threaded.container` (worker)
  - `.config/containers/available/huginn/huginn-mariadb.container` (BD)
- Volumen(es):
  - `.config/containers/available/huginn/huginn-mariadb.volume` (`VolumeName=huginn-mariadb`)
- Red(es):
  - `.config/containers/available/huginn/huginn.network` (`NetworkName=huginn`)
- Config no secreta: ninguna (todo por `Environment=` y `Secret=`).
- Secretos: `huginn_database_password`, `huginn_mysql_password`, `huginn_mariadb_root_password`,
  `huginn_app_secret_token`.

## Cómo funciona

- **Web** (`huginn.container`): labels de Traefik (`Host(\`huginn.${FQDN}\`)`, puerto `3000`), `DATABASE_NAME=huginn`,
  `DATABASE_USERNAME=huginn`, `DATABASE_ADAPTER=mysql2`, `DATABASE_HOST=mariadb`, `DATABASE_PORT=3306` y
  `Secret=huginn_database_password` → `DATABASE_PASSWORD`; `Requires=`/`After=` sobre `huginn-mariadb.service`.
- **Worker** (`huginn-threaded.container`): mismas variables de BD, `WORKER_CMD=bin/threaded.rb`,
  `NetworkAlias=threaded`; **sin labels** (no se expone) y con `Requires=`/`After=` sobre la BD.
- **BD** (`huginn-mariadb.container`): `MYSQL_DATABASE=huginn`, `MYSQL_USER=huginn`, `NetworkAlias=mariadb`;
  secretos `huginn_mysql_password` (`MYSQL_PASSWORD`) y `huginn_mariadb_root_password`
  (`MARIADB_ROOT_PASSWORD`); volumen `huginn-mariadb.volume` en `/var/lib/mysql:Z`.
- `APP_SECRET_TOKEN` se inyecta con `Secret=huginn_app_secret_token` en web y worker. Si no se fija, la
  imagen lo regenera en cada arranque e invalida las sesiones; además rechaza el token público histórico
  que trae por defecto.
- Ningún contenedor declara healthcheck.

## Variables / configuración

| Var | Dónde | Descripción |
|---|---|---|
| `DATABASE_NAME` | `huginn.container`, `huginn-threaded.container` | Nombre de la BD (`huginn`) |
| `DATABASE_USERNAME` | `huginn.container`, `huginn-threaded.container` | Usuario de la BD (`huginn`) |
| `DATABASE_PASSWORD` | `Secret=huginn_database_password` | Contraseña del usuario de la app |
| `DATABASE_ADAPTER` | `huginn.container`, `huginn-threaded.container` | `mysql2` |
| `DATABASE_HOST` | `huginn.container`, `huginn-threaded.container` | `mariadb` (alias de la BD) |
| `DATABASE_PORT` | `huginn.container`, `huginn-threaded.container` | `3306` |
| `APP_SECRET_TOKEN` | `Secret=huginn_app_secret_token` | Firma de sesiones; estable entre arranques |
| `WORKER_CMD` | `huginn-threaded.container` | `bin/threaded.rb` (rol worker) |
| `MYSQL_DATABASE` / `MYSQL_USER` | `huginn-mariadb.container` | Base y usuario a crear en MariaDB |
| `MYSQL_PASSWORD` | `Secret=huginn_mysql_password` | Contraseña del usuario `MYSQL_USER` |
| `MARIADB_ROOT_PASSWORD` | `Secret=huginn_mariadb_root_password` | Contraseña de root de MariaDB |
| `FQDN` | entorno systemd (`~/.config/environment.d/fqdn.conf`) | Dominio base; el router usa `huginn.${FQDN}` |

## Cómo habilitar / desplegar

```bash
# 1. Crear los secretos ANTES de arrancar (nunca `crypta store`)
printf '%s' "$(openssl rand -base64 24)" | podman secret create huginn_database_password -
printf '%s' "$(openssl rand -base64 24)" | podman secret create huginn_mysql_password -
printf '%s' "$(openssl rand -base64 24)" | podman secret create huginn_mariadb_root_password -
printf '%s' "$(openssl rand -base64 32)" | podman secret create huginn_app_secret_token -

# 2. Enlazar y arrancar
cd .config/containers/available/huginn
qctl install
systemctl --user daemon-reload
```

## Decisiones de migración (compose → quadlet)

| Compose (origen) | Quadlet |
|---|---|
| `mariadb` / `container_name: huginn_mariadb` | `huginn-mariadb.container` (`ContainerName=huginn-mariadb`) |
| `huginn` (web) | `huginn.container` |
| `threaded` (`WORKER_CMD=bin/threaded.rb`) | `huginn-threaded.container` |
| `depends_on` | eliminado (resuelto por la red compartida) |
| `restart: unless-stopped` | `Restart=always` |

## Verificación E2E (2026-11-13)

Verificado en producción (`new_atareao`, usuario `runner`) con certificado `letsencrypt-staging`
(purgado después):

1. Units `huginn`, `huginn-threaded` y `huginn-mariadb` → `active`.
2. Contenedores arrancados (`podman ps`).
3. Router `huginn` registrado en Traefik.
4. Certificado staging válido para `huginn.servidorlinux.es`.
5. `https://huginn.servidorlinux.es` → **200** (login); **13 tablas** creadas en MariaDB.

Bugs corregidos para llegar hasta aquí:

- La web solo estaba en `proxy.network`; la BD vive en `huginn.network` → la web no la resolvía.
- **Faltaba `DATABASE_HOST`** (y `DATABASE_ADAPTER`/`DATABASE_PORT`): sin host, `setup_env` cae en
  `START_MYSQL=true` y la imagen intenta arrancar un MySQL interno.
- Faltaba `APP_SECRET_TOKEN`: se regeneraba en cada arranque (sesiones invalidadas) y la imagen rechaza
  el token público histórico.
- Añadidos `Requires=`/`After=` hacia `huginn-mariadb.service` en web y worker.

## Follow-ups

- Sin `SEED_USERNAME`/`SEED_PASSWORD`, el administrador se crea con una contraseña **aleatoria** que solo
  aparece una vez en el log del primer arranque. Fijarla en el quadlet o usar `DO_NOT_SEED=true`.
- Ningún contenedor declara healthcheck.
