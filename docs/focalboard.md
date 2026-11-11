# focalboard — gestión de proyectos y tableros (Focalboard + PostgreSQL)

## Qué es

Focalboard (Mattermost Boards, edición personal standalone): tableros kanban, tareas y wiki ligera.
Dos contenedores: `focalboard` (imagen `docker.io/mattermost/focalboard:latest`) y
`focalboard-postgresql` (imagen `docker.io/library/postgres:18-alpine`). Redes: `focalboard.network`
(interna, app↔BD) + `proxy.network` (front). Dominio: `focalboard.${FQDN}`. Puerto interno expuesto a
Traefik: `8000`.

## Ficheros

- Quadlet(s): `.config/containers/available/focalboard/focalboard.container`,
  `.config/containers/available/focalboard/focalboard-postgresql.container`
- Red(es): `.config/containers/available/focalboard/focalboard.network`
- Volumen(es): `.config/containers/available/focalboard/focalboard-data.volume` (adjuntos, montado en
  `/opt/focalboard/files`), `.config/containers/available/focalboard/focalboard-db.volume` (datos de
  PostgreSQL, montado en `/var/lib/postgresql`)
- Config no secreta: — (toda la config va en `Environment=` del quadlet)
- Secretos: `focalboard_database_url`, `focalboard_postgres_password`

## Cómo funciona

`focalboard` se une a `proxy.network` (para Traefik) y a `focalboard.network` (para hablar con la BD,
donde `focalboard-postgresql` publica `NetworkAlias=focalboarddb`). La app depende de la BD vía
`After=focalboard-postgresql.service` / `Requires=focalboard-postgresql.service`; el orden con
`proxy.network` lo genera solo el quadlet (`proxy-network.service`).

**No hay `config.json` montado** (antes se montaba `%h/.config/focalboard/config.json`, un bind a un
directorio inexistente que impedía arrancar la unit). La configuración de BD se pasa por variables de
entorno, que en Focalboard (viper, prefijo `FOCALBOARD_`) sobreescriben `config.json`:

- `FOCALBOARD_DBTYPE=postgres` — motor.
- `FOCALBOARD_DBCONFIG` — cadena de conexión completa de PostgreSQL, inyectada como secreto
  (`Secret=focalboard_database_url,type=env,target=FOCALBOARD_DBCONFIG`).

Ejemplo de valor del secreto:

```
postgres://focalboard:<password>@focalboarddb:5432/focalboard?sslmode=disable
```

La BD usa `focalboard_postgres_password` → `POSTGRES_PASSWORD`; el usuario y la base creados por la
imagen son `focalboard`/`focalboard` (`POSTGRES_USER`/`POSTGRES_DB`). El volumen de datos se monta en
`/var/lib/postgresql` (no en `/var/lib/postgresql/data`): PostgreSQL 18 cambia el layout del
directorio de datos y exige el padre. La BD tiene healthcheck `pg_isready`; la app no define
healthcheck fiable (no se añadió).

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `FOCALBOARD_DBTYPE` | `focalboard.container` (`Environment=`) | `postgres` | Motor de base de datos |
| `FOCALBOARD_DBCONFIG` | `focalboard.container` (`Secret=focalboard_database_url`) | *(secreto)* | URI completa `postgres://focalboard:<pass>@focalboarddb:5432/focalboard?sslmode=disable` |
| `TZ` | `focalboard.container` (`Environment=`) | `Europe/Madrid` | Zona horaria |
| `POSTGRES_USER` | `focalboard-postgresql.container` (`Environment=`) | `focalboard` | Usuario de PostgreSQL |
| `POSTGRES_DB` | `focalboard-postgresql.container` (`Environment=`) | `focalboard` | Base de datos |
| `POSTGRES_PASSWORD` | `focalboard-postgresql.container` (`Secret=focalboard_postgres_password`) | *(secreto)* | Contraseña del usuario `focalboard` |
| `TZ` | `focalboard-postgresql.container` (`Environment=`) | `Europe/Madrid` | Zona horaria |
| `FQDN` | entorno systemd (`~/.config/environment.d/fqdn.conf`) | `<tu-dominio>` | Dominio base; el router usa `focalboard.${FQDN}` |

## Cómo habilitar / desplegar

1. Crear los secretos (NUNCA `crypta store`):

   ```bash
   printf '%s' '<password>' | podman secret create focalboard_postgres_password -
   printf '%s' 'postgres://focalboard:<password>@focalboarddb:5432/focalboard?sslmode=disable' \
     | podman secret create focalboard_database_url -
   ```

   La contraseña embebida en la URI **debe coincidir** con `focalboard_postgres_password`: son dos
   secretos porque la BD necesita el valor crudo (`POSTGRES_PASSWORD`) y la app la URI completa.

2. `cd .config/containers/available/focalboard && qctl install`
3. `systemctl --user daemon-reload`
4. `systemctl --user enable --now focalboard-postgresql focalboard`

Validación local sin tocar el host:

```bash
mkdir -p /tmp/qd/focalboard && cp .config/containers/available/focalboard/* /tmp/qd/focalboard/ \
  && cp .config/containers/available/traefik/proxy.network /tmp/qd/focalboard/ \
  && QUADLET_UNIT_DIRS=/tmp/qd/focalboard /usr/lib/podman/quadlet -user -dryrun
```

## Decisiones y follow-ups

- Se eligió **una sola variable secreta con la URI completa** (`FOCALBOARD_DBCONFIG`) en vez de
  `FOCALBOARD_DBPASSWORD`: la imagen standalone no documenta esa variable y sí documenta
  `FOCALBOARD_DBCONFIG`; además evita componer cadenas en el quadlet. Mismo patrón que
  `umami_database_url` con `DATABASE_URL`.
- Un único secreto no puede servir a la vez para `POSTGRES_PASSWORD` y la URI, de ahí los dos nombres.
- Mantenimiento: el imagen standalone de Focalboard está descatalogado por Mattermost (última v7.11.4,
  2023); el tag `:latest` se fija explícito por convención. Aceptar que no habrá parches y valorar
  migrar a la alternativa mantenida si se usa en producción.
- Sin `HealthCmd` en la app: no hay endpoint fiable verificado en esta ronda.
- No aplica hardening (`ReadOnly`, `NoNewPrivileges`, `User`/`Group`); evaluar añadirlo.
