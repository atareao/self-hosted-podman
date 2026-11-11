# PLAN-028 — Healthcheck con driver de secretos externo (crypta): `no such secret`

- **Issue:** #23
- **Estado:** COMPLETADO — fix versionado (commit adcfb0a) y desplegado+validado E2E en prod.
- **Fecha:** 2026-11-11
- **Sustituye al enfoque inicial** (remediación por-unit `type=mount`/fallback), descartado al hallar la causa raíz.

## Causa raíz (confirmada en prod)

El healthcheck automático de Podman (presente cuando un quadlet define `HealthCmd`) **no lo ejecuta conmon directamente**: Podman lo lanza como **unit transitoria** `systemd-run --user … podman healthcheck run <ctr>`. Esa unit **solo hereda el entorno del systemd user manager**, que en prod carecía de:

- `~/.local/bin` en el `PATH` (donde viven `crypta` **y** `sops`).
- `SOPS_AGE_KEY_FILE` (la clave age con la que SOPS descifra el store).

Al re-resolver los secretos `type=env` para construir el exec del healthcheck, el driver `shell` invoca `crypta lookup <id>` → `crypt, sops` no encontrados y/o sin clave age → Podman falla con `Error: <id>: no such secret` → healthcheck `unhealthy` (y unit `activating` donde hay `ExecStartPost` que espera `healthy`).

**No es un fallo del driver ni de crypta/SOPS**: es entorno ausente en la unit transitoria.

### Evidencia (prod `new_atareao`, Podman 5.7.0 / conmon 2.1.13 / crun 1.21)

- `journalctl --user`: `Started …timer - [systemd-run] /usr/bin/podman healthcheck run <ctr>` seguido de `Error: <id>: no such secret`.
- `podman healthcheck run <ctr>` manual → rc=0; el automático → unhealthy.
- Dentro de `systemd-run --user`: `crypta: not found` (rc=127); con ruta absoluta → `sops` no instalado; con `PATH` + `SOPS_AGE_KEY_FILE` → OK (`hunter2`, rc=0).
- En dev (Podman 6.1.4) no reproducía porque `containers.conf` usa la **ruta absoluta** de crypta y el store local no exige la clave age.

## Arreglo elegido (conserva crypta + SOPS, sin tocar ninguna unit)

Añadir al **systemd user manager** el entorno que el driver necesita, vía `~/.config/environment.d/crypta.conf`:

```
PATH=$PATH:$HOME/.local/bin
SOPS_AGE_KEY_FILE=$HOME/.secrets/sops/age/key.txt
```

Aplicar con `systemctl --user daemon-reexec` (las units ya en ejecución conservan su propio `Environment=`).

### Validación E2E (prod)

Contenedor de prueba `--secret X,type=env --health-cmd …` → `Health=healthy` tras el reexec. Stacks reales (`traefik`, `pocketid`, `headscale`, `errserve`) intactos. Artefactos de prueba eliminados.

## Por qué se descarta la remediación por-unit

El enfoque inicial proponía migrar 8 units a `type=mount` (que soportan `*_FILE`), 5 a fallback (quitar `HealthCmd` + gate desde el host) y documentar excepciones. **Descartado**: el problema era de entorno, no de las units. Arreglar la raíz evita reescribir 13 unidades y conserva `type=env` + crypta + SOPS tal cual.

### Matriz de soporte de fichero (inventario T1, ya no necesaria)

| Unit | Secretos `type=env` | Soporte `*_FILE` |
|---|---|---|
| authentik-postgresql, gitea-db, invidious-postgresql, miniflux-postgresql, umami-postgresql, wger-postgresql | `POSTGRES_PASSWORD` | sí (`POSTGRES_PASSWORD_FILE`) |
| rustfs | `RUSTFS_ACCESS_KEY`, `RUSTFS_SECRET_KEY` | sí (`RUSTFS_*_KEY_FILE`) |
| zennotes | `ZENNOTES_AUTH_TOKEN` | sí (`ZENNOTES_AUTH_TOKEN_FILE`) |
| alloy, apimail, umami, vector, watchbeat | `OIDC_CLIENT_SECRET` / `APIMAIL_*_PASSWORD` / `APP_SECRET`,`DATABASE_URL` / `OO_USER_PASSWORD` | no |

## Tareas

- [x] T1. Inventario de las 13 units: secretos `type=env` y soporte `*_FILE`.
- [x] T2. Matriz de remediación (descartada tras hallar la causa raíz).
- [x] T3. Diagnóstico reproducido en prod (unit transitoria + `no such secret`).
- [x] T4. Fix de raíz identificado y validado E2E en prod.
- [x] T5. Versionar en el repo: `.config/environment.d/crypta.conf`, `docs/secrets-healthcheck.md` y nota en `AGENTS.md`.
- [x] T6. Desplegar en prod (`yadm pull` como runner) + `systemctl --user daemon-reexec`; re-verificar un stack afectado en arranque en frío.
- [ ] T7. (Opcional) Reporte upstream: la unit transitoria del healthcheck debería heredar el entorno del contenedor/unit, o documentarse.
- [ ] T8. Cerrar: marcar tareas, renombrar a `plans/PLAN-028-ARCHIVED.md`, cerrar el issue #23.

## Criterios de cierre

- Ninguna unit afectada queda `unhealthy`/`activating` en arranque en frío.
- Fix versionado y desplegado (environment.d + `daemon-reexec`).
- `AGENTS.md` y `docs/secrets-healthcheck.md` actualizados; issue #23 cerrado.

## Notas

- Nunca usar `crypta store` para secretos de Podman: se crean con `podman secret create` (el driver `shell` resuelve por ID).
- Los secretos de Podman son write-only: no sirven para guardar una contraseña recuperable.
- Follow-up independiente: `StartLimitIntervalSec`/`StartLimitBurst` están en `[Service]` (systemd los ignora; van en `[Unit]`).

## Cierre (2026-11-11)

- Fix versionado en `main` (commit `adcfb0a`): `.config/environment.d/crypta.conf`, `docs/secrets-healthcheck.md`, nota en `AGENTS.md`, este plan.
- Desplegado en prod: `yadm pull` (runner) + `systemctl --user daemon-reexec`.
- Verificación E2E en prod (Podman 5.7.0): contenedor con `--secret X,type=env --health-cmd …` → `Health=healthy`; stacks reales (`traefik`, `pocketid`, `headscale`, `errserve`) intactos; artefactos de prueba eliminados.
- Nota de despliegue: el `yadm pull` abortaba porque el `crypta.conf` creado a mano durante el diagnóstico estaba sin commitear (untracked) y colisionaba con el del repo; se eliminó y el pull fast-forwardeó.