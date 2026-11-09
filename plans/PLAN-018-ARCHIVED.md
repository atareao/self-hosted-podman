# PLAN-018 — Probar stacks flame, flatnotes, notemark, picoshare, podmixer y glass-keep

- **Issue:** #13
- **Estado:** completado
- **Fecha:** 2026-11-09

## Objetivos
- [x] Desplegar y verificar E2E los 6 stacks y purgarlos dejando prod limpio.
- [x] Corregir los bugs latentes detectados.
- [x] Documentar y actualizar inventario + HANDOFF.

## Resultado
- Verificados E2E (200 con cert LE): flame, flatnotes, notemark, picoshare, podmixer y glass-keep (dominio `keep.${FQDN}`).
- Bugs latentes corregidos:
  - flatnotes: router a `dnote.${FQDN}` (colisión) → `flatnotes.${FQDN}`; service port 3000 → 8080 (uvicorn).
  - notemark: `JWT_SECRET` de 32 chars fallaba la validación `gte` → usar ≥64 (`openssl rand -base64 48`).
  - glass-keep: faltaban `INITIAL_ADMIN_USERNAME` (env de stack) + `INITIAL_ADMIN_PASSWORD` (Secret `glass_keep_initial_admin_password`).
- Inventario: 38 verificados · 87 sin verificar.
- Prod limpio (solo errserve, headscale, headscale-headplane, pocketid, traefik).

## Hallazgos / follow-ups
- Los 6 requieren crear sus secretos con `podman secret create` antes de arrancar (no están versionados).
