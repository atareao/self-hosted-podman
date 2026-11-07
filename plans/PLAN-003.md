# PLAN-003 — Consolidar la gestión de stacks en `qctl` (retirar los helpers fish)

## Objetivo
Eliminar las funciones fish `qenable`/`qdisable`/`qlist`/`qcheck` y dejar `qctl` como única herramienta de gestión de stacks. Antes hay que cubrir los dos huecos que solo viven en los scripts: la guarda de colisión global en `install` y la auditoría en `check`.

## Contexto
- `qctl` (Rust, `/data/rust/qctl`) ya cubre `install`/`uninstall`/`status` (equivalen a `qenable`/`qdisable`/`qlist`).
- `qcheck` (auditoría de colisiones + convención de nombres) no tiene equivalente → pasa a `qctl check` sin argumento.
- `install` carece del pre-scan atómico anti-colisión de `qenable`.

## Alcance

### Repo `qctl` (`/data/rust/qctl`) — rama `feature/consolidate-stack-management`
Spec OpenSpec: `openspec/changes/consolidate-stack-management/`.
1. `install`: **guarda de colisión global atómica** (basename de unit + `ContainerName=` entre todos los stacks del stacks root). Aborta sin enlazar nada si hay choque.
2. `check`: `check <QUADLET>` valida un fichero (como hoy) + `check` sin args = **auditoría global** (colisiones duras → error/exit≠0; nombres fuera de convención `<stack>.<ext>`/`<stack>-<rol>` → aviso, no falla).
3. `--stacks-root <dir>` (default `$HOME/.config/containers/available`).

### Repo `self-hosted-podman` (`/data/self-hosted-podman`) — tras el release de qctl
4. Borrar `.config/fish/functions/{qenable,qdisable,qlist,qcheck}.fish`.
5. Actualizar **AGENTS.md** y **README.md** (y `docs/errserve.md`) al flujo `qctl`:
   - `qenable <stack>` → `cd .config/containers/available/<stack> && qctl install`
   - `qdisable <stack>` → `qctl uninstall`
   - `qlist` → `qctl status`
   - `qcheck` → `qctl check`
6. `unjinja` sigue siendo necesario antes de `qctl install` (renderiza `.jinja` → `.container`).
7. Los `plans/*-ARCHIVED.md` **no se editan** (registro histórico).

## Orden (dependencia cruzada)
1. `qctl`: spec → TDD → auditoría → PR a `develop` → release.
2. dotfiles: borrar scripts + actualizar docs **solo** cuando `qctl` ya tenga la paridad publicada.

## Decisiones (aprobadas)
- `check` con/sin argumento + avisos de convención.
- Se pierde el "operar por nombre desde cualquier sitio" de `qenable`; el flujo pasa a `cd <stack> && qctl ...`.
- Stacks root por defecto `$HOME/.config/containers/available`, con override por flag.

## Tareas
1. [x] `qctl`: crear el change OpenSpec `consolidate-stack-management` y validar `--strict`.
2. [ ] `qctl`: TDD (`install` guard + `check` auditoría), `cargo test` verde, fmt/clippy.
3. [ ] `qctl`: auditoría `@rust-reviewer` + PR a `develop` + merge + `openspec archive`.
4. [ ] `qctl`: release (bump `.vampus.yml`) y binario en prod.
5. [ ] dotfiles: borrar los 4 helpers fish.
6. [ ] dotfiles: actualizar AGENTS.md, README.md, `docs/errserve.md`.
7. [ ] Cerrar este plan → `plans/PLAN-003-ARCHIVED.md`.

## Follow-ups
- `docs/` (dotfiles): doc de la consolidación.
- Valorar hacer configurable la regla de convención de nombres de `check` (hoy fija a `<stack>.<ext>`/`<stack>-<rol>`).
