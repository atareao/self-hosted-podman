# PLAN-019 — Probar stacks dagu, semaphore, rustfs, storyteller, pdfding y openobserve

- **Issue:** #14
- **Estado:** completado
- **Fecha:** 2026-11-09

## Objetivos
- [x] Desplegar y verificar E2E los 6 stacks y purgarlos dejando prod limpio.
- [x] Corregir los bugs latentes detectados.
- [x] Documentar y actualizar inventario + HANDOFF.

## Resultado
- Verificados E2E (200 con cert LE): dagu, semaphore, storyteller, pdfding, openobserve; rustfs en
  `/rustfs/console` (root 403 — API S3).
- Bugs latentes corregidos:
  - dagu: imagen `ghcr.io/dagu-org/dagu` (403) → `ghcr.io/dagucloud/dagu`; quitar `DAGU_BASE_PATH` (router en raíz).
  - semaphore: dialecto `bolt` retirado en 2.19 → `sqlite` + `SEMAPHORE_DB`; service port Traefik 5005 → 3000.
  - rustfs: `HealthCmd` CMD-SHELL daba exit 125 en conmon → forma exec; console en `/rustfs/console`.
  - storyteller: volumen `:rw:Z` inválido → `:Z`.
- openobserve: requiere enlazar `security.network` (vive en el stack `vector`).
- Inventario: 44 verificados · 81 sin verificar.
- Prod limpio (solo errserve, headscale, headscale-headplane, pocketid, traefik).

## Hallazgos / follow-ups
- `dingpdf` es un **duplicado** de `pdfding` (misma imagen, mismos volúmenes, mismo service `pdfding`); conviene eliminarlo.
- rustfs: el console vive en `/rustfs/console` (base path de compilación, no configurable).
- Los 6 requieren crear sus secretos con `podman secret create` antes de arrancar.
