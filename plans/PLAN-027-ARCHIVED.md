# PLAN-027 — Ronda E2E, lote 1: alloy, apimail, couchdb, dim, ghost, kanboard

- **Issue:** #22
- **Estado:** cerrado
- **Fecha:** 2026-11-11

## Contexto

Ronda de verificación E2E del inventario `docs/estado-verificacion-e2e.md` (68 stacks sin verificar).
Lote de 6 stacks de **un solo contenedor** y con router HTTP. Flujo y purga según `docs/gestion-stacks-qctl.md`.
Infra de producción: usuario `runner` (uid 1002) en `new_atareao`, FQDN `servidorlinux.es`, acceso vía wrapper `rr`.
Desde PLAN-022 las rondas E2E usan el resolver `letsencrypt-staging` para no consumir la cuota de producción.

## Objetivos

- [x] Desplegar y verificar E2E: **couchdb, dim, ghost, kanboard** OK; **apimail** funcional pero arranque en frío bloqueado por #23; **alloy** bloqueado por OIDC.
- [x] Corregir los bugs latentes detectados (quadlets y docs).
- [x] Purgar los 6 stacks (`qctl purge --secrets --images --data -y`) dejando prod limpio.
- [x] Actualizar `docs/estado-verificacion-e2e.md` (55 → 59 verificados, +2 bloqueados, 68 → 62 sin verificar) y `HANDOFF.md`.
- [x] Revisar `docs/<stack>.md` de los 6 tras los cambios.
- [x] Archivar el plan: `plans/PLAN-027-ARCHIVED.md`.

## Stacks, configuración prevista y riesgos

| Stack | Dominio | Imagen | Servicio/port | Volúmenes/binds | Secretos | Riesgo latente a comprobar |
|---|---|---|---|---|---|---|
| alloy | `alloy.${FQDN}` | `docker.io/atareao/alloy:latest` | 3066 | `alloy-data.volume` + socket podman (ro) | `alloy_oidc_client_secret` | socket podman.sock; healthcheck `/api/health`; OIDC no configurado (env de ejemplo) |
| apimail | `apimail.${FQDN}` | `ghcr.io/atareao/apimail:latest` | 3000 | `apimail-data.volume` | `apimail_api_key`, `apimail_imap_password`, `apimail_smtp_password` | 3 secretos; IMAP/SMTP de ejemplo (sin red externa real) |
| couchdb | `couchdb.${FQDN}` | `docker.io/library/couchdb:latest` | 5984 | `couchdb-data.volume` | `couchdb_password` | `COUCHDB_USER`/`COUCHDB_PASSWORD` obligatorios en el primer arranque |
| dim | `dim.${FQDN}` | `docker.io/atareao/dim:latest` | 8000 | bind `~/.config/dim/config` + `dim-media.volume` | — | bind `config` debe existir; imagen no oficial |
| ghost | `ghost.${FQDN}` | `docker.io/library/ghost:4-alpine` | 2368 | bind `~/.config/ghost/blog` | — | **errata probable** `/var/lig/ghost/content` → `/var/lib/ghost/content`; `Environment=url` |
| kanboard | `kanboard.${FQDN}` | `docker.io/kanboard/kanboard:latest` | 80 | binds `~/.config/kanboard/kanboard_data`, `~/.config/kanboard/kanboard_plugins` | — | **errata probable** `/bar/www/app/data` → `/var/www/app/data` |

## Fases

### 1. Preparación (local)
- `qctl check` para colisiones (basename/ContainerName/router); comprobar que los dominios no colisionan.

### 2. Despliegue y verificación E2E (prod, usuario `runner` vía `rr`)
Por cada stack, en orden:
1. `yadm pull` → `cd ~/.config/containers/available/<stack>`.
2. Crear los secretos necesarios con **`podman secret create`** (nunca `crypta store`).
3. Preparar los binds que lo requieran (`ghost/blog`, `dim/config`, `kanboard/kanboard_data`+`kanboard_plugins`).
4. `qctl install` y `qctl start <unit>`.
5. Verificar 5 puntos: unit `active`; contenedor en `podman ps`; router en Traefik; cert LE válido; HTTP esperado.

### 3. Corrección de bugs latentes
- Arreglar quadlets/docs según hallazgos (delegar la escritura al subagente correspondiente).
- Tras corregir, recrear el contenedor; si Traefik no re-registra el router, `systemctl --user restart traefik`.

### 4. Purga
- Por stack: `qctl purge --secrets --images --data -y`; revisar restos (binds con uid mapeado, volúmenes dangling).
- Comprobar limpieza: `podman ps -a`, `podman volume ls`, `podman secret ls`, `podman images`, symlinks en `systemd/`.

### 5. Documentación y cierre
- Actualizar `docs/estado-verificacion-e2e.md`, `HANDOFF.md` y los `docs/<stack>.md` afectados.
- Renombrar el plan a `plans/PLAN-027-ARCHIVED.md`.

## Resultados

- **Verificados y purgados (4):** couchdb (200), dim (200), ghost (200), kanboard (302→/login). Cert LE staging válido.
- **Corregidos (bugs latentes):** `ghost` (url sin protocolo → `https://ghost.${FQDN}`; bind `/var/lig/ghost/content` → `/var/lib/ghost/content`) y `kanboard` (bind `/bar/www/app/data` → `/var/www/app/data`).
- **Bloqueados (2):** `apimail` (funcional; arranque en frío roto por el bug #23) y `alloy` (requiere OIDC real en PocketID).
- **Hallazgo repo-wide:** `Secret=…,type=env` con driver externo (`shell`/crypta) rompe el healthcheck de conmon (exit 125) en Podman 5.7.0 → **13 units afectadas**. Se abre el issue #23 y el `plans/PLAN-028.md` (remediación con `type=mount`).
- Prod purgada y limpia: solo `errserve`, `headscale`, `headscale-headplane`, `pocketid`, `traefik`.

## Criterios de aceptación
- Los 6 stacks alcanzan los 5 puntos E2E (o el hallazgo documentado que lo impida).
- Prod limpio al cerrar: solo `errserve`, `headscale`, `headscale-headplane`, `pocketid`, `traefik`.
- Inventario y HANDOFF actualizados; plan archivado.

## Follow-ups previstos
- Seguir con las rondas sucesivas hasta agotar los 68 sin verificar.
- Vigilar la cuota de Let's Encrypt de producción; mantener staging en las rondas E2E.
