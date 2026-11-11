# PLAN-032 — Ronda E2E lote 4: wallabag, vscode, whisper, unbound, watchbeat, publirs

- **Issue:** #27
- **Fecha:** 2026-11-11
- **Estado:** ARCHIVADO (2026-11-12)

## Objetivo

Continuar las rondas de verificación E2E de stacks en producción (`new_atareao`, usuario `runner`,
rootless Podman) con el lote 4: revisar estáticamente los 6 stacks candidatos, corregir los bugs
latentes detectados, desplegar, verificar los 5 puntos E2E y purgar (unit, volúmenes, binds,
secretos e imágenes) cada stack, dejando `docs/` y `docs/estado-verificacion-e2e.md` actualizados.

## Contexto

- Repo de dotfiles (yadm), **no** aplicación: sin build/test/lint ni código de aplicación. Por tanto
  queda fuera del flujo OpenSpec/TDD de `AGENTS.md` global; el equivalente a la verificación es la
  comprobación E2E por CLI (los 5 puntos de abajo), como en los lotes 1–3.
- `docs/estado-verificacion-e2e.md`: 127 stacks = 71 verificados + 4 en producción + 2 bloqueados
  (`alloy`, `apimail`) + **50 sin verificar**. Al cerrar este lote, si los 6 pasan: 127 = 77 + 4 + 2 + 44.
- Ronda anterior: `plans/PLAN-031-ARCHIVED.md` (lote 3). Flujo de despliegue y purga:
  `docs/gestion-stacks-qctl.md`. Invariantes de enrutado: `docs/traefik.md`.
- Producción **solo** como `runner` vía wrapper `rr` (desde `lorenzo`, NOPASSWD). Secretos:
  `podman secret create` siempre, nunca `crypta store`.
- Para TLS usar `letsencrypt-staging` durante la verificación y **revertir** el cambio antes del
  `yadm pull`.
- Un stack cuyo fallo no se resuelva en tiempo razonable → se documenta, se purga y queda como
  «bloqueado» en el inventario; **el lote no se bloquea por él**.

## Criterio de «verificado E2E» (5 puntos)

1. El unit systemd queda `active`.
2. El contenedor arranca (`podman ps`).
3. Traefik registra el router (label `traefik.enable=true`).
4. El certificado Let's Encrypt es válido para el dominio.
5. La URL responde con el HTTP esperado.

Excepción documentada: los stacks sin dominio propio (servicio interno, sin labels Traefik) se
verifican por puerto/API (p. ej. `curl` al puerto publicado) y se anota como tal en su `docs/`.

## Alcance (6 stacks) e inventario estático

| Stack | Units | Imágenes | Exposición | Secretos `Secret=` | Notas |
|---|---|---|---|---|---|
| wallabag | `wallabag.container` | `docker.io/wallabag/wallabag` (sin tag) | `wallabag` / `wallabag.${FQDN}` :80 | **ninguno** | binds `%h/.config/wallabag/{images,data}`; `SYMFONY__ENV__DOMAIN_NAME`, `SYMFONY__ENV__SERVER_NAME`; sin unit de cron |
| vscode | `vscode.container` | `lscr.io/linuxserver/code-server` (sin tag) | `vscode` / `vscode.${FQDN}` :8443 | `vscode_password` (→ `PASSWORD`) | LSNG: **sin** `PodmanArgs=--init` (correcto); bind `%h/.config/vscode/config`; `PUID/PGID=1000` |
| whisper | `whisper.container`, `whisper-data.volume` | `docker.io/onerahmet/openai-whisper-asr-webservice:latest-gpu` | `PublishPort=9000:9000`, **sin Traefik** | **ninguno** | `ASR_MODEL=large-v1`, `ASR_ENGINE=faster_whisper`, `ASR_MODEL_PATH=/data/whisper` |
| unbound | `unbound.container` | `docker.io/mvance/unbound:latest` | `PublishPort=53:53/tcp` y `53:53/udp`, **sin Traefik** | **ninguno** | binds `%h/.config/unbound/unbound.conf` y `%h/.config/unbound/conf/` |
| watchbeat | `watchbeat.container`, `watchbeat-data.volume` | `docker.io/atareao/watchbeat:latest` | `watchbeat` / `watchbeat.${FQDN}` :3055 | `watchbeat_oidc_client_secret` (→ `OIDC_CLIENT_SECRET`) | `HealthCmd` wget `/health`; `OIDC_REDIRECT_URL` |
| publirs | `publirs.container`, `publirs-croni.container`, `publirs.network`, `publirs-db.volume` | `docker.io/atareao/publirs:latest`, `docker.io/atareao/croni:latest` | **sin Traefik** (interno, `PORT=8080`) | `publirs_token` (→ `TOKEN`, **solo** en `publirs`) | `DB_URL=sqlite:/app/db/publirs.db`; volumen en `/app/db` |

## Riesgos e hipótesis a validar (revisión estática previa)

- **wallabag:**
  - Imagen sin tag y **sin variables de BD**: el contenedor oficial usa SQLite en
    `/var/www/wallabag/data` si no se define `DATABASE_URL`. Confirmar migraciones automáticas y
    que sobrevive al reinicio (persistencia de `data/`).
  - `SYMFONY__ENV__SERVER_NAME="el nombre que quieras"` es un **placeholder sin sustituir** →
    corregir (poner el nombre real o eliminar la variable).
  - El compose original de wallabag incluye un contenedor **cron** (`wallabag-cron`, misma imagen,
    tarea programada): si falta, documentar o añadir como `<stack>--cron`.
  - Comprobar si el bind `images` necesita `podman unshare chown` (imagen corre como usuario no root).
- **vscode:** LSNG sin `--init` (correcto); verificar que la imagen arranca con s6 (no PID 1 error),
  que el secreto `vscode_password` existe en prod y que `8443` sirve por HTTPS interno sin romper TLS.
- **whisper:**
  - Imagen `:latest-gpu` **exige runtime NVIDIA**; si el host no tiene GPU, usar la variante CPU
    (`latest-cpu`) o documentar bloqueo.
  - `ASR_MODEL=large-v1` descarga varios GB en el primer arranque → usar modelo menor o precargar en
    el volumen `whisper-data` antes de dar por válido el arranque.
  - `PublishPort=9000` sin Traefik: comprobar **colisión de puerto** con otros stacks y si debe
    llevar dominio. Sin labels, no aplica el punto 3/4 (excepción documentada).
- **unbound:**
  - Los puertos 53/tcp y 53/udp son **privilegiados**: el Podman rootless de `runner` no puede
    enlazarlos (salvo `net.ipv4.ip_unprivileged_port_start=0` en el host, que requiere root del
    sistema y no está permitido por el modelo de acceso). Hipótesis principal de **bloqueo**;
    alternativas: publicar en puerto alto (p. ej. `5353`) y dejar el 53 fuera del alcance, o
    documentar bloqueo. No se publica 53 en prod sin confirmación.
  - Verificar que existen `%h/.config/unbound/unbound.conf` y `%h/.config/unbound/conf/` antes de
    instalar (bind a fichero inexistente = fallo de arranque).
- **watchbeat:**
  - **Bug probable de OIDC:** `OIDC_REDIRECT_URL=https://${FQDN}/auth/callback` apunta al **apex**, mientras el router sirve `watchbeat.${FQDN}` → debería ser
    `https://watchbeat.${FQDN}/auth/callback`. Corregir y actualizar `docs/watchbeat.md`.
  - Necesita un **cliente OIDC real en PocketID** (`watchbeat_oidc_client_secret` + resto de
    `OIDC_*`); sin él, la app arranca pero el login no funciona → decidir entre crear el cliente o
    verificar sólo hasta el login y documentar lo pendiente.
- **publirs:**
  - `publirs-croni` **no** recibe `TOKEN`; si croni llama a la API de publirs, necesitará el mismo
    secreto → comprobar en el arranque y unificar si falla.
  - Stack sin Traefik: verificar por `curl` al puerto interno en la red `publirs.network` y por log.
  - Confirmar que `DB_URL=sqlite:/app/db/publirs.db` crea y persiste la BD en el volumen
    `publirs-db` (y que el sufijo `:Z` del volumen no rompe el acceso).

## Tareas

### T0 — Preparación (estática, sin prod)

- [x] T0.1 Revisar los 6 stacks con `qctl check` (colisiones de basename/`ContainerName=`) y
      `QUADLET_UNIT_DIRS=<tmp> /usr/lib/podman/quadlet -user -dryrun` (validación del generador).
- [x] T0.2 Comprobar colisiones de **puertos publicados** (`9000`, `53`) contra los stacks en prod y
      contra `~/.config/systemd/user/*.socket` (80/443).
- [x] T0.3 Verificar que existen los binds referenciados (`%h/.config/{wallabag,vscode,unbound}/…`
      ) y crear el contenido mínimo que falte (`unbound.conf`, `conf/`).
- [x] T0.4 Listar los secretos a crear y crear cada uno con `podman secret create` (nunca `crypta
      store`): `vscode_password`, `watchbeat_oidc_client_secret`, `publirs_token`.

### T1–T6 — Un stack por tarea (wallabag, vscode, whisper, unbound, watchbeat, publirs)

Para cada stack, en este orden:

- [x] Corregir los bugs latentes de la sección «Riesgos» que apliquen (commit gitmoji `fix`/`chore`).
- [x] Desplegar: `cd .config/containers/available/<stack> && qctl install`, `systemctl --user
      daemon-reload`, `systemctl --user start <unit>`.
- [x] Verificar los 5 puntos E2E (los servicios internos por puerto/API).
- [x] Si algo no arranca: `journalctl --user -u <unit>` acotado con `head`; un intento razonable de
      arreglo; si no, documentar y marcar bloqueado.
- [x] **Purgar**: `qctl uninstall` (y borrar symlinks colgantes en
      `~/.config/containers/systemd/` — un symlink roto invalida el `daemon-reload`), borrar
      volúmenes/binds/secrets/imágenes del stack, `systemctl --user reset-failed` si quedan units
      `not-found`.
- [x] Actualizar `docs/<stack>.md` (qué es, ficheros, cómo funciona, config, despliegue, decisiones
      de migración y follow-ups) y marcar aquí lo verificado.

### T7 — Cierre

- [x] Actualizar `docs/estado-verificacion-e2e.md`: tabla de verificados del lote 4, bloqueados y
      recuento final del inventario.
- [x] Fijar `origin/main`, cerrar el issue #27, y renombrar este plan a
      `plans/PLAN-032-ARCHIVED.md` a `ARCHIVED`, con el resumen de hallazgos.
- [x] Actualizar `HANDOFF.md` con el relevo (estado, pendiente, notas críticas nuevas).

## Entregables

- Quadlets corregidos en `main` (commits gitmoji convencionales).
- `docs/<stack>.md` actualizado para cada stack del lote.
- `docs/estado-verificacion-e2e.md` con el inventario recalculado.
- `plans/PLAN-032-ARCHIVED.md` y `HANDOFF.md` al día.

## Resultado (2026-11-12)

Ronda E2E lote 4 **completada**: los 6 stacks (`wallabag`, `vscode`, `whisper`, `unbound`,
`watchbeat`, `publirs`) se desplegaron, verificaron E2E y **purgaron** el **2026-11-11/12**.
Excepciones documentadas (servicio interno, sin Traefik): `whisper` (verificado por puerto/API) y
`unbound` (verificado por consulta DNS recursiva).

Bugs latentes corregidos:

- **wallabag:** eliminado el placeholder sin sustituir de `SYMFONY__ENV__SERVER_NAME`.
- **whisper:** `:latest-gpu` → `:latest` (prod sin GPU NVIDIA), `large-v1` → `small`, host 9000 →
  9001 (colisión con authentik).
- **watchbeat:** issuer OIDC real de PocketID y `OIDC_REDIRECT_URL` al **subdominio** (no al apex);
  healthcheck en `127.0.0.1` (no `localhost`) + `AddHost=auth.${FQDN}:host-gateway`.
- **unbound:** publica **5353** (rootless no puede enlazar el 53) y monta la config por el include
  real de la imagen.
- **publirs:** expuesto por Traefik en `publirs.${FQDN}`; `crontab.txt` montado en croni; quitado el
  bind a `/etc/timezone` inexistente.

Pendientes abiertos (no bloquean la ronda):

- **watchbeat:** cliente OIDC `watchbeat` sin registrar en PocketID; `watchbeat_oidc_client_secret`
  con **placeholder** (login no funciona E2E).
- **publirs:** `publirs_token` con **placeholder** (envío a Telegram sin probar).
- **publirs (croni):** `publish_tip`/`publish_poll` invocados por **GET** y la API responde 404/405
  (probable POST) → esos jobs fallarán.
- **unbound:** ACL de la IP del host sin descomentar.

El puerto **53 del host no se cubre a propósito**: el Podman rootless de `runner` no puede enlazar
puertos privilegiados por la limitación `net.ipv4.ip_unprivileged_port_start=80`; `unbound` queda en
5353.

Cifras: 127 = **77 verificados** + 4 en producción + 2 bloqueados + **44 sin verificar**.