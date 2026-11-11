---
# PLAN-028 — Secrets con driver externo + `type=env`: arreglar el healthcheck de conmon

- **Issue:** #23
- **Estado:** abierto
- **Fecha:** 2026-11-11
- **Relacionado:** PLAN-027 (ronda E2E lote 1, issue #22)

## Contexto

Las units que combinan `Secret=<name>,type=env` (driver de secretos externo `shell` → `crypta`) con una `HealthCmd` real **no arrancan en frío**: el `ExecStartPost` que espera el estado `healthy` nunca lo ve (el healthcheck automático de **conmon** sale con **exit 125**), agota `TimeoutStartSec` y la unit queda `activating` con el contenedor girando.

Reproducido en producción (`new_atareao`, Podman **5.7.0**):

- `podman healthcheck run <ctr>` on-demand → **rc=0** (el comando es correcto).
- El **spec OCI `config.json` es idéntico** entre un contenedor sano (driver `file`) y uno roto (driver `shell`).
- El entorno de conmon **sí tiene** `SOPS_AGE_KEY_FILE` y `~/.local/bin` en `PATH`.
- El binomio letal es **driver externo (`shell`) + `type=env`**: con driver `file` + `type=env` → healthy; con `shell` + `type=mount` → healthy; con `shell` + `type=env` → 125.
- Misma familia que el bug upstream [podman#27713](https://github.com/podman-container-tools/podman/issues/27713) (driver `pass` + quadlet → `no such secret`): los drivers externos re-resuelven el secreto en la ruta de *exec* de conmon y fallan.

## Objetivo

Eliminar el fallo de arranque en frío en las 13 units afectadas **conservando el modelo de secretos** (Podman secrets con driver `shell`/crypta + SOPS).

## Alcance

Units afectadas (13): `alloy`, `apimail`, `authentik-postgresql`, `gitea-db`, `invidious-postgresql`, `miniflux-postgresql`, `rustfs`, `umami`, `umami-postgresql`, `vector`, `watchbeat`, `wger-postgresql`, `zennotes`.

Fuera de alcance: `traefik` (su secreto usa driver `file`) y `headscale-headplane` (`HealthCmd=none`).

## Enfoque

1. **Preferente — `type=mount`:** exponer el secreto como fichero (`/run/secrets/<target>`, o `target=` a medida) y ajustar la app para leerlo (variables `*_FILE` o lectura directa del fichero). Conserva crypta/SOPS y el `HealthCmd`.
2. **Fallback — readiness en systemd:** donde la app no pueda leer de fichero, quitar `HealthCmd`+`ExecStartPost` y gatear la readiness con un `ExecStartPost` desde el host. Se pierde el `healthy` en `podman ps`.
3. **Excepción documentada:** si ninguna de las dos encaja, documentar la limitación en `docs/<stack>.md`.

## Matriz de remediación (a completar durante la ejecución)

| Unit | Secretos `type=env` | ¿App soporta fichero/`*_FILE`? | Acción |
|---|---|---|---|
| alloy | `alloy_oidc_client_secret` | (a determinar) | |
| apimail | `apimail_api_key`, `apimail_imap_password`, `apimail_smtp_password` | (a determinar) | |
| authentik-postgresql | (a determinar) | (postgres) | |
| gitea-db | (a determinar) | (postgres/mysql) | |
| invidious-postgresql | (a determinar) | (postgres) | |
| miniflux-postgresql | (a determinar) | (postgres) | |
| rustfs | (a determinar) | (a determinar) | |
| umami | `umami_app_secret` | (a determinar) | |
| umami-postgresql | (a determinar) | (postgres) | |
| vector | (a determinar) | (a determinar) | |
| watchbeat | `watchbeat_oidc_client_secret` | (a determinar) | |
| wger-postgresql | (a determinar) | (postgres) | |
| zennotes | `zennotes_auth_token` | (a determinar) | |

## Tareas

- [ ] T1. Inventario de las 13 units: identificar los secretos `type=env` concretos y si la app soporta `*_FILE` o lectura de `/run/secrets`.
- [ ] T2. Rellenar la matriz de remediación con la acción elegida por unit.
- [ ] T3. Aplicar `type=mount` (+ `target=`) y ajustar el env de la app en cada quadlet donde aplique.
- [ ] T4. Donde no haya soporte de fichero: quitar `HealthCmd`+`ExecStartPost` y gatear readiness desde systemd.
- [ ] T5. Validar cada unit con el generador quadlet en dryrun.
- [ ] T6. Desplegar 1 unit representativa (`apimail`) en prod con **arranque en frío** y verificar E2E (unit `active`, contenedor `Up`+`healthy`, router Traefik, cert válido, HTTP esperado).
- [ ] T7. Actualizar `docs/<stack>.md` afectados y `AGENTS.md` (invariante + hallazgo latente).
- [ ] T8. Reportar el bug upstream en Podman (familia de #27713).
- [ ] T9. Cerrar: marcar tareas, renombrar a `plans/PLAN-028-ARCHIVED.md`, cerrar el issue #23.

## Validación / criterios de cierre

- Ninguna unit afectada queda `activating` en arranque en frío.
- Dryrun del generador quadlet sin errores para las units tocadas.
- `apimail` (representativa) pasa E2E con arranque en frío.
- `docs/` afectados y `AGENTS.md` actualizados; issue #23 cerrado.

## Notas

- Nunca usar `crypta store` para secretos de Podman: se crean con `podman secret create` (el driver `shell` resuelve por ID).
- `type=mount` monta por defecto en `/run/secrets/<name>`; `target=` permite otra ruta.
- Recordar el hallazgo latente independiente: `StartLimitIntervalSec`/`StartLimitBurst` están en `[Service]` (systemd los ignora; van en `[Unit]`) — follow-up aparte.
---
