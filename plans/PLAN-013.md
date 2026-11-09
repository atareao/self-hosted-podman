# PLAN-013 — Probar stacks freshrss, gotify, kavita y otterwiki

- **Issue GitHub:** #7
- **Fecha:** 2026-11-09
- **Estado:** en curso

## Objetivo

Desplegar en producción (`new_atareao`, usuario `runner`) cuatro stacks (sin `Secret=` ni OIDC),
verificarlos end-to-end y **volver a desinstalarlos y purgarlos** al terminar.

## Stacks

| Stack | Imagen | Puerto | Almacenamiento | URL |
|---|---|---|---|---|
| freshrss | `docker.io/freshrss/freshrss:latest` | 80 | binds `%h/.config/freshrss/{data,extensions}` | freshrss.servidorlinux.es |
| gotify | `docker.io/gotify/server:latest` | 80 | bind `%h/.config/gotify/data` | gotify.servidorlinux.es |
| kavita | `docker.io/jvmilazz0/kavita:latest` | 5000 | volúmenes `kavita-books`, `kavita-data` | kavita.servidorlinux.es |
| otterwiki | `docker.io/redimp/otterwiki:2` | 80 | volumen `otterwiki-data` | **wiki**.servidorlinux.es |

- Sin `Secret=` ni OIDC. Tags de imagen verificados en Docker Hub (HTTP 200).
- `freshrss` y `gotify` usan **binds** bajo `~/.config/<stack>/` → requieren crear directorios y, si
  procede, `podman unshare chown` al uid que use la imagen (ajustar empíricamente con los logs).

## Fase A — repo
- Crear este plan y el issue.

## Fase B — despliegue
1. `yadm pull` en prod.
2. Crear binds: `mkdir -p ~/.config/freshrss/{data,extensions} ~/.config/gotify/data`.
3. Por stack: `cd .config/containers/available/<stack> && qctl install`.
4. `systemctl --user daemon-reload` y `start` de los cuatro; ajustar permisos si los logs muestran fallo de escritura.

## Fase C — verificación
- Unit `active`, contenedor arriba, router Traefik, cert LE y HTTP correcto en `https://<host>`.

## Fase D — purga
1. `qctl uninstall` de los cuatro.
2. `podman volume rm kavita-books kavita-data otterwiki-data`.
3. Borrar los binds de freshrss y gotify (`podman unshare rm -rf` si el uid está mapeado).
4. `podman rmi` de las cuatro imágenes.
5. Comprobar: sin symlinks, sin contenedores, sin volúmenes.

## Criterios de aceptación
- Los cuatro verificados (unit + contenedor + router + cert + HTTP).
- Al terminar, TODO purgado.
- `docs/<stack>.md` con «Estado de despliegue»; `HANDOFF.md` actualizado.

## Tareas
- [ ] Crear issue GitHub.
- [ ] Fase B: binds + `qctl install` + start (+ permisos si hacen falta).
- [ ] Fase C: verificación end-to-end.
- [ ] Fase D: purga total (units + volúmenes + binds + imágenes).
- [ ] Actualizar `docs/` y `HANDOFF.md`; archivar este plan.