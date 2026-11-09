# PLAN-017 — Probar stacks homepage, portainer, jellyfin, zincobserve, yopass y searxng

- **Issue:** #12
- **Estado:** completado
- **Fecha:** 2026-11-09

## Objetivos
- [x] Desplegar y verificar E2E los 6 stacks y purgarlos dejando prod limpio.
- [x] Corregir los bugs latentes detectados.
- [x] Documentar y actualizar inventario + HANDOFF.

## Resultado
- Verificados E2E (200 con cert LE): homepage, portainer, yopass, searxng; jellyfin (302→`/web/` 200); zincobserve (307→`/web/` 200).
- Bugs latentes corregidos:
  - searxng: volumen `:rw:Z` inválido → `:Z`.
  - yopass: puerto 80 inbindable en rootless → `--port 1337` + `loadbalancer.server.port=1337`.
  - zincobserve: faltaban `ZO_ROOT_USER_EMAIL` (env de stack) + `ZO_ROOT_USER_PASSWORD` (Secret `zincobserve_root_password`).
- Inventario: 32 verificados · 93 sin verificar.
- Prod limpio (solo errserve, headscale, headscale-headplane, pocketid, traefik).

## Hallazgos / follow-ups
- `redis:alpine` está compartida (authentik/nextcloud): la guarda cross-stack de `qctl purge` la conserva (correcto).
- searxng: `SEARXNG_BASE_URL=https://localhost/` es placeholder; fijar a `https://searxng.${FQDN}`.
- Secreto huérfano pre-existente en prod (ajeno a esta ronda): `temporal` (no lo declara ningún quadlet).
