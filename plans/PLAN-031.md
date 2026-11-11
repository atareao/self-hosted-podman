# PLAN-031 — Ronda E2E lote 3: bookstack, dnote, focalboard, snibox, umami, hedgedoc

- **Issue:** #26
- **Fecha:** 2026-11-11
- **Estado:** EN CURSO

## Objetivo

Continuar las rondas de verificación E2E de stacks en producción (`new_atareao`, usuario `runner`,
rootless Podman) con el lote 3: leer y corregir los bugs latentes detectados en la revisión estática,
desplegar, verificar los 5 puntos E2E y purgar (unit, volúmenes, secretos, binds e imágenes) cada
stack, dejando `docs/` y `docs/estado-verificacion-e2e.md` actualizados.

## Contexto

- Repo de dotfiles (yadm), no aplicación: sin build/test/lint. Verificación = `qctl status`,
  `podman ps`, router de Traefik, TLS y HTTP.
- `docs/estado-verificacion-e2e.md`: 127 stacks, 65 verificados, 4 en prod, 2 bloqueados,
  56 sin verificar. Al cerrar este lote, si los 6 pasan: 127 = 71 + 4 + 2 + 50.
- Ronda anterior: `plans/PLAN-030-ARCHIVED.md` (lote 2). Para TLS usar `letsencrypt-staging`
durante la verificación y no consumir cuota de producción.
- Flujo de despliegue y purga: `docs/gestion-stacks-qctl.md`. Invariantes de enrutado: `docs/traefik.md`.
- Producción solo como `runner` vía wrapper `rr` (desde `lorenzo`, NOPASSWD).
- Un fallo por stack que no se resuelva en tiempo razonable → se documenta, se purga y el stack
  queda como «bloqueado» en `docs/estado-verificacion-e2e.md`; el lote no se bloquea por él.

## Alcance (6 stacks) e inventario estático

| Stack | Units | Imágenes | Router / dominio / puerto | Secretos `Secret=` |
|---|---|---|---|---|
| bookstack | `bookstack`, `bookstack-mariadb`, `bookstack.network` | `lscr.io/linuxserver/bookstack`, `lscr.io/linuxserver/mariadb` (ambas sin tag) | `bookstack` / `bookstack.${FQDN}` :80 | `bookstack_db_pass`, `bookstack_mysql_root_password`, `bookstack_mysql_password` |
| dnote | `dnote`, `dnote-postgres`, `dnote.network` | `docker.io/dnote/dnote:latest`, `postgres:11-alpine` | `dnote` / `dnote.${FQDN}` :3000 | `dnote_dbpassword`, `dnote_postgres_password` (duplicado del mismo valor) |
| focalboard | `focalboard`, `focalboard-postgresql`, `focalboard.network`, `focalboard-data.volume`, `focalboard-db.volume` | `mattermost/focalboard` (sin tag), `postgres:latest` (PG18) | `focalboard` / `focalboard.${FQDN}` :8000 | **ninguno** |
| snibox | `snibox`, `snibox-backend`, `snibox-postgresql`, `snibox.network`, `snibox-pg-data.volume`, `snibox-static-files.volume` | `snibox/nginx-puma:1.15.9`, `snibox/snibox:latest`, `postgres:10.7-alpine` | `snibox` / `snibox.${FQDN}` :80 | `snibox_db_pass`, `snibox_mailgun_*`, `snibox_secret_key_base` |
| umami | `umami`, `umami-postgresql`, `umami.network`, `umami-data.volume` | `ghcr.io/umami-software/umami:postgresql-latest`, `postgres:18-alpine` | `umami` / `umami.${FQDN}` :3000 | `umami_app_secret`, `umami_database_url`, `umamidb_password` |
| hedgedoc | `hedgedoc`, `hedgedoc-mariadb`, `hedgedoc.network`, `hedgedoc-config.volume`, `hedgedoc-data.volume` | `lscr.io/linuxserver/hedgedoc:latest`, `lscr.io/linuxserver/mariadb:latest` | `hedgedoc` / `doc.${FQDN}` :3000 (intencional) | `hedgedoc_db_pass`, `hedgedoc_mysql_root_password`, `hedgedoc_mysql_password` |

## Bugs latentes a corregir antes de desplegar

Bloqueantes (el stack no arranca o no sirve):

- **umami:** `Requires=umamidb.service` y `After=umamidb.service` apuntan a una unit inexistente
  (la real es `umami-postgresql.service`) → la transacción de systemd no carga. Quitar además
  `proxy.network` del `After=` (nombre de unit inválido; sería `proxy-network.service`).
  Corregir `docs/umami.md`, que reproduce el nombre erróneo.
- **focalboard:** (a) `postgres:latest` (PG18) montado en `/var/lib/postgresql/data` → mover el
  volumen a `/var/lib/postgresql`; (b) faltan `POSTGRES_PASSWORD`/`POSTGRES_USER`/`POSTGRES_DB`
  → secreto `focalboard_postgres_password` + `Environment=`; (c) el bind
  `%h/.config/focalboard/config.json` apunta a un directorio inexistente → crear el `config.json`
  real con la `dbconfig` (o sustituirlo por un volumen) antes de instalar.
- **bookstack:** la app solo está en `proxy.network` pero usa `DB_HOST=bookstack_db` (alias de
  `bookstack.network`) → añadir la red; y el bind `%h/.config/bookstack/config` lo comparten app y
  MariaDB → separar en `.../config` (app) y `.../mariadb` (BD).
- **dnote:** la app solo está en `proxy.network` pero usa `DBHost=postgres` → añadir
  `dnote.network`. Unificar la contraseña de BD en un único secreto (app y BD) para evitar
  desincronización. `Description=postgres` en `dnote-postgres.container` → corregir.
- **snibox:** `snibox` (nginx) solo en `proxy.network` y `snibox-backend` solo en `snibox.network`
  → nginx no resuelve `backend` (502); añadir `snibox.network` al contenedor `snibox`. La BD no
  declara `POSTGRES_PASSWORD` → no arranca; inyectar el secreto y hacer que el `DB_PASS` de la app
  sea el mismo valor.

Altos:

- Añadir `Requires=`/`After=` hacia la BD en bookstack, dnote, snibox y hedgedoc (carrera en arranque en frío).
- EOL a evaluar: `postgres:11-alpine` (dnote), `postgres:10.7-alpine` y `nginx-puma:1.15.9` (snibox).
  Si la imagen de la app no admite un PG moderno, fijar el tag actual, documentar el EOL y no
  actualizar a ciegas.
- hedgedoc: los nombres de volumen están invertidos (`hedgedoc-data` guarda la BD,
  `hedgedoc-config` la config de la app). No renombrar si eso obliga a migrar datos; documentarlo
  explícitamente en `docs/hedgedoc.md` para no equivocarse en backup/purga.
- healthchecks ausentes en los 6 stacks: valorar añadirlos sólo donde el `HealthCmd` sea fiable
  (no introducir healthchecks nuevos si no se pueden verificar en esta ronda).

Higiene (aplicar según el skeleton canónico de `AGENTS.md`):

- `PodmanArgs=--init` en bookstack, dnote, focalboard, hedgedoc y `snibox.container`.
- Imágenes sin tag → fijar tag explícito; `AutoUpdate=registry` en las BD que no lo tienen.
- `Restart=` sólo con valores systemd (`always`/`on-failure`), nunca `unless-stopped`.
- `StartLimitIntervalSec`/`StartLimitBurst` en `[Unit]`, nunca en `[Service]`.
- Convención `.config/<stack>/<stack>.env` (+ `.env.local`): crear el `.env` versionado con la
  config no secreta de cada stack donde hoy no exista, si aporta valor real; no migrar por migrar.

## Precondiciones

- `unjinja` disponible en el host de `runner` (hook `post_pull`), `qctl` en `~/.local/bin`.
- Secretos creados **con `podman secret create`** (NUNCA `crypta store`) antes de arrancar cada unit.
- `~/.config/environment.d/crypta.conf` desplegado (PLAN-028) para que los healthchecks re-resuelvan `type=env`.
- Binds creados antes de `qctl install`; con usuario no root en la imagen, `podman unshare chown -R <uid>:<uid> <bind>`.
- Validación local de cada stack corregido con `QUADLET_UNIT_DIRS=<tmp> /usr/lib/podman/quadlet -user -dryrun`.

## Tareas

- [ ] T1 — Preflight en prod: `systemctl --user is-system-running`, `systemctl --user daemon-reload`,
      `qctl check` de los 6 stacks, `unjinja` ejecutado y `.jinja` renderizados presentes.
- [ ] T2 — Corregir **umami** (`Requires=`/`After=` → `umami-postgresql.service`, quitar `proxy.network`
      del `After=`, corregir `docs/umami.md`) y validar con quadlet dryrun.
- [ ] T3 — Corregir **focalboard**: volumen PG18 en `/var/lib/postgresql`, secreto
      `focalboard_postgres_password` + `POSTGRES_*`, crear `%h/.config/focalboard/config.json` con la
      `dbconfig` (host `focalboarddb`), `Requires=`/`After=`, `--init`, tag de imagen. Dryrun.
- [ ] T4 — Corregir **bookstack**: añadir `bookstack.network` a la app, separar los binds `/config`
      app vs MariaDB, `Requires=`/`After=`, `--init`, tags. Dryrun.
- [5] T5 — Corregir **dnote**: añadir `dnote.network` a la app, unificar secreto de BD,
      `Description`, `Requires=`/`After=`, `--init`, política de tag/EOL de PG. Dryrun.
- [ ] T6 — Corregir **snibox**: `snibox` en `snibox.network`, `POSTGRES_PASSWORD` en la BD,
      `Requires=`/`After=`, `--init`, `AutoUpdate`. Dryrun.
- [ ] T7 — Revisar **hedgedoc** (redes y secretos ya correctos): `Requires=`/`After=`, `--init`,
      tags, y documentar los nombres de volumen invertidos. Dryrun.
- [ ] T8 — Desplegar y verificar los 6 stacks (uno a uno): secretos con `podman secret create`,
      binds con permisos correctos, `qctl install`, 5 puntos E2E con `letsencrypt-staging`.
      Anotar por stack el código HTTP final y los fixes aplicados.
- [ ] T9 — Purga por stack: `qctl uninstall`, volúmenes nombrados, secretos, binds (`podman unshare rm -rf`
      si el uid no es `runner`), imágenes. Borrar también los symlinks en `~/.config/containers/systemd/`
      (un symlink colgante rompe el generador para todo el stack).
- [ ] T10 — Actualizar `docs/estado-verificacion-e2e.md` (tabla «Verificados E2E» + cifras
      127 = 71 + 4 + 2 + 50 si los 6 pasan; bloquear los que fallen) y `docs/<stack>.md` de los 6
      stacks con hallazgos, fixes y follow-ups.
- [ ] T11 — Commit gitmoji en `main`, archivar el plan a `plans/PLAN-031-ARCHIVED.md`, actualizar
      `HANDOFF.md` y cerrar la issue #26.

## Criterio de verificado E2E (5 puntos)

1. Unit systemd `active` (`systemctl --user is-active <unit>`).
2. Contenedor(es) en ejecución (`podman ps`).
3. Traefik registra el router (`traefik.enable=true` y router visible en la API/logs).
4. Certificado TLS válido para el dominio (staging).
5. La URL responde con el HTTP esperado (200/302 según la app).

## Riesgos y notas

- `bookstack`, `hedgedoc` y `snibox` usan MariaDB/MySQL vía LSNG: el bind `/config` de LSNG debe ser
  propio de cada contenedor; compartirlo corrompe la config.
- `snibox` depende de imágenes de 2018-2019 (Rails antiguo): si no arranca, no invertir la ronda en
  modernizarlo; documentar como bloqueado.
- Recrear un contenedor puede dejar el router sin registrar: si tras recrear no enruta,
  `systemctl --user restart traefik`.
- Los symlinks huérfanos en `~/.config/containers/systemd/` son la causa número uno de que
  `daemon-reload` no genere ninguna unit del stack.