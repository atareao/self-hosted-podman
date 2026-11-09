# PLAN-016 — Automatizar el `--init` de ferrishare + verificar `qctl purge`

- **Issue:** #11
- **Estado:** completado
- **Fecha:** 2026-11-09

## Objetivos
- [x] Provisioning no interactivo de ferrishare (`config.toml` en el volumen nombrado).
- [x] Desplegar y verificar ferrishare end-to-end (200 + cert LE) y purgarlo.
- [x] Verificar `qctl purge` en real (dry-run, base, `--volumes/--secrets/--images/--data`, guarda cross-stack y `--force`).
- [x] Documentar ferrishare y `qctl purge`; actualizar inventario y HANDOFF.

## Resultado
- `ferrishare-init.py` (driver PTY sobre `ferrishare --init`): genera `config.toml` con hash argon2id; el
  despliegue de ferrishare ya no requiere pasos manuales.
- ferrishare verificado E2E en prod y purgado.
- `qctl purge` verificado: base + volúmenes + `--secrets` + `--images` + `--data` + guarda cross-stack + `--force`.
  Caveat: solo elimina recursos **declarados en los quadlets**.
- Inventario: 26 verificados · 99 sin verificar.
- Prod limpio (solo errserve, headscale, headscale-headplane, pocketid, traefik).
