# PLAN-029 — `StartLimitIntervalSec`/`StartLimitBurst` mal ubicados en `[Service]`

- **Issue:** #24
- **Estado:** COMPLETADO — fix implementado (commit bc16df9) y desplegado+verificado en prod.
- **Fecha:** 2026-11-11
- **Origen:** follow-up detectado al cerrar PLAN-028 (issue #23).

## Problema

195 quadlets de `.config/containers/available/**` declaran `StartLimitIntervalSec=300` y `StartLimitBurst=3` en la sección `[Service]`. En systemd ≥ 230 esas claves pertenecen a **`[Unit]`**; en `[Service]` systemd las ignora:

```
Unknown key 'StartLimitIntervalSec' in section [Service], ignoring.
```

Consecuencia: la política de límite de reinicios (300 s / 3 intentos) **no se aplica**; el `Restart=always` queda sin tope efectivo.

## Verificación del diagnóstico (hecha)

- `systemd-analyze verify` sobre el unit generado con `StartLimit*` en `[Service]` → `Unknown key ... ignoring`.
- Lo mismo con `StartLimit*` en `[Unit]` → sin warnings.
- El generador quadlet (`/usr/lib/podman/quadlet`) acepta `StartLimitIntervalSec`/`StartLimitBurst` en `[Unit]` y los emite en la sección `[Unit]` del unit resultante.
- (Nota histórica: `StartLimitInterval=` sin `Sec` era opción de `[Service]` en systemd < 230; hoy la forma correcta es `StartLimitIntervalSec` en `[Unit]`.)

## Alcance

- **195** ficheros `.container` (ninguno `.jinja`), todos con exactamente `StartLimitIntervalSec=300` y `StartLimitBurst=3`, todos en `[Service]`.
- `AGENTS.md`: el *canonical skeleton* los coloca en `[Service]` (reproduce el bug).
- **8** `docs/*.md` (tick, dozzle, memos, socks5, stirling-pdf, storyteller, snibox, navidrome) describen el patrón con la ubicación errónea.

## Fix

En cada `.container`: **quitar** las dos líneas de `[Service]` y **añadirlas al final de `[Unit]`** (tras `Description`/`After`/`Requires`), manteniendo el orden `StartLimitIntervalSec=300` y luego `StartLimitBurst=3`.

En `AGENTS.md`: mover esas dos líneas del bloque `[Service]` del skeleton al bloque `[Unit]`.

En los 8 `docs/*.md`: corregir la mención para reflejar que van en `[Unit]`.

**No** cambia ninguna otra cosa: mismos valores, mismos ficheros, `[Container]` intacto.

## Tareas (TDD/verificación)

- [x] T1. Transformación mecánica de las 195 units (script determinista; quitar de `[Service]`, insertar al final de `[Unit]`).
- [x] T2. Corregir el skeleton de `AGENTS.md` (mover `StartLimit*` a `[Unit]`).
- [x] T3. Corregir los 8 `docs/*.md`.
- [x] T4. Verificación estática: 0 ocurrencias de `StartLimit` en `[Service]`; 195×2 = 390 en `[Unit]`; diff solo con esas líneas movidas.
- [x] T5. Verificación con el generador quadlet: render de plantillas + `QUADLET_UNIT_DIRS=… quadlet -user -dryrun` sobre una muestra de stacks; y `systemd-analyze verify` del unit generado sin el warning.
- [x] T6. Commit (gitmoji) y push a `main`.
- [x] T7. Desplegar en prod (`yadm pull` como runner) + `systemctl --user daemon-reload`; verificar el unit generado (`systemctl --user cat <unit>` → `StartLimitIntervalSec` en `[Unit]`).
- [x] T8. Documentar (`docs/quadlet-startlimit.md` o nota en AGENTS.md) y cerrar: `plans/PLAN-029-ARCHIVED.md`, cerrar issue #24.

## Criterios de cierre

- Ninguna unit tiene `StartLimit*` en `[Service]`.
- `systemd-analyze verify` del unit generado no emite el warning `Unknown key 'StartLimitIntervalSec'`.
- Skeleton y docs coherentes; plan archivado e issue #24 cerrado.

## Notas

- Transformación determinista y de bajo riesgo: solo mueve dos líneas por fichero; no toca valores ni `[Container]`.
- La verificación con el generador quadlet requiere, por stack, renderizar `.jinja` y copiar las redes compartidas (`proxy.network`) al dir temporal, o el generador falla con `unable to translate dependency for <net>.network`.
## Cierre (2026-11-11)

- Commit `bc16df9` en `main`: 195 `.container` (StartLimit* movidos de `[Service]` a `[Unit]`), skeleton+regla en `AGENTS.md`, 8 `docs/*.md`, y eliminación del fichero huérfano `data/self-hosted-podman/.config/.../authentik/geoipupdate.container` (artefacto del import masivo `b386b56`).
- Verificación local: 0 en `[Service]`, 390 en `[Unit]`; generador quadlet emite StartLimit* en `[Unit]`; `systemd-analyze verify` sin el warning.
- Desplegado en prod (`yadm pull`): unit generado de `headscale.service` con StartLimit* en `[Unit]`.
- Prueba definitiva en prod: `systemctl --user show headscale.service -p StartLimitIntervalUSec -p StartLimitBurst` → `StartLimitIntervalUSec=5min`, `StartLimitBurst=3` (antes se ignoraban). Stacks vivos intactos.
