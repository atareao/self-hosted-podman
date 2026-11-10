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
- **Dominio:** `huginn.${FQDN}` (subdominio) → router `huginn`, servicio `huginn`, puerto interno `3000`.

## Ficheros

- Quadlet(s):
  - `.config/containers/available/huginn/huginn.container` (web)
  - `.config/containers/available/huginn/huginn-threaded.container` (worker)
  - `.config/containers/available/huginn/huginn-mariadb.container` (BD)
- Volumen(es):
  - `.config/containers/available/huginn/huginn-huginn_mariadb.volume` (`VolumeName=huginn-huginn_mariadb`)
- Red(es):
  - `.config/containers/available/huginn/huginn.network` (`NetworkName=huginn`)
- Config no secreta: ninguna (todo por `Environment=` y `Secret=`).
- Secretos: `huginn_database_password`, `huginn_mysql_password`, `huginn_mariadb_root_password`.

## Cómo funciona

- **Web** (`huginn.container`): labels de Traefik (`Host(\`huginn.${FQDN}\`)`, puerto `3000`), `DATABASE_NAME=huginn`,
  `DATABASE_USERNAME=huginn` y `Secret=huginn_database_password` → `DATABASE_PASSWORD`.
- **Worker** (`huginn-threaded.container`): `WORKER_CMD=bin/threaded.rb`, `NetworkAlias=threaded`; **sin labels**
  (no se expone).
- **BD** (`huginn-mariadb.container`): `MYSQL_DATABASE=huginn`, `MYSQL_USER=huginn`, secretos
  `huginn_mysql_password` (`MYSQL_PASSWORD`) y `huginn_mariadb_root_password` (`MARIADB_ROOT_PASSWORD`);
  volumen `huginn-huginn_mariadb.volume` en `/var/lib/mysql:Z`.
- Ninguno de los tres declara healthcheck ni `After=`/`Requires=` sobre la BD: si la web arranca antes que
  MariaDB, reintenta.

## Variables / configuración

| Var | Dónde | Descripción |
|---|---|---|
| `DATABASE_NAME` | `huginn.container`, `huginn-threaded.container` | Nombre de la BD (`huginn`) |
| `DATABASE_USERNAME` | `huginn.container`, `huginn-threaded.container` | Usuario de la BD (`huginn`) |
| `DATABASE_PASSWORD` | `Secret=huginn_database_password` | Contraseña del usuario de la app |
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

## Follow-ups

- Renombrar el volumen `huginn-huginn_mariadb` a `huginn-mariadb` (convención `<stack>-<rol>`); es cosmético y requiere cambiar el nombre del `.volume` y la `Volume=` del quadlet.
- Ningún contenedor declara healthcheck.
