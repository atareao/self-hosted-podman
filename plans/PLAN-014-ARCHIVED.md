# PLAN-014 — Probar stacks uptime-kuma, trilium, audiobookshelf, pairdrop, readeck y bentopdf

- **Issue GitHub:** #9
- **Fecha:** 2026-11-09
- **Estado:** completado

## Objetivo

Desplegar en producción (`new_atareao`, usuario `runner`) seis stacks de **fricción cero**
(sin `Secret=`, sin OIDC, 1 contenedor, imagen con tag existente, sin binds que necesiten `chown`),
verificarlos end-to-end y **volver a desinstalarlos y purgarlos** al terminar.

Primer lote de 6 (cambio respecto a las rondas anteriores de 4) para reducir el número de rondas
necesarias sobre los stacks sin verificar E2E (ver `docs/estado-verificacion-e2e.md`).

## Stacks

| Stack | Imagen | Puerto Traefik | Almacenamiento | URL |
|---|---|---|---|---|
| uptime-kuma | `docker.io/louislam/uptime-kuma:2` | 3001 | volumen `uptime-kuma-data` | uptime.servidorlinux.es |
| trilium | `docker.io/zadam/trilium:latest` | 8080 | volumen `trilium-trilium` | trilium.servidorlinux.es |
| audiobookshelf | `ghcr.io/advplyr/audiobookshelf:latest` | 80 | volúmenes `audiobookshelf-{books,metadata,config}` | books.servidorlinux.es |
| pairdrop | `ghcr.io/schlagmichdoch/pairdrop` | 3000 | ninguno | pairdrop.servidorlinux.es |
| readeck | `codeberg.org/readeck/readeck` | 8000 | volumen `readeck-data` | readeck.servidorlinux.es |
| bentopdf | `docker.io/bentopdf/bentopdf` | 8080 | ninguno | pdf.servidorlinux.es |

- Sin `Secret=` ni OIDC. Tags de imagen verificados en sus registros (HTTP 200).
- Ningún bind host-side → no requiere `mkdir`/`chown`.

## Fase A — repo
- Crear este plan y el issue.

## Fase B — despliegue
1. `yadm pull` en prod.
2. Por stack: `cd .config/containers/available/<stack> && qctl install`.
3. `systemctl --user daemon-reload` y `start` de los seis.

## Fase C — verificación
- Unit `active`, contenedor arriba, router Traefik, cert LE y HTTP correcto en `https://<host>`.
- Reintentar si hay 502 transitorio por arranque lento.

## Fase D — purga
1. `qctl uninstall` de los seis.
2. `podman volume rm` de `uptime-kuma-data`, `trilium-trilium`, `audiobookshelf-books`, `audiobookshelf-metadata`, `audiobookshelf-config`, `readeck-data`.
3. `podman rmi` de las seis imágenes.
4. Comprobar: sin symlinks, sin contenedores, sin volúmenes, sin imágenes.

## Criterios de aceptación
- Los seis verificados (unit + contenedor + router + cert + HTTP).
- Al terminar, TODO purgado.
- `docs/<stack>.md` con «Estado de despliegue»; `docs/estado-verificacion-e2e.md` actualizado (mover los 6 de «sin verificar» a «verificados»); `HANDOFF.md` actualizado.

## Tareas
- [x] Crear issue GitHub.
- [x] Fase B: `yadm pull` + `qctl install` + start de los seis.
- [x] Fase C: verificación end-to-end de cada stack.
- [x] Fase D: purga total (units + volúmenes + imágenes).
- [x] Actualizar docs, `docs/estado-verificacion-e2e.md` y `HANDOFF.md`; archivar este plan.