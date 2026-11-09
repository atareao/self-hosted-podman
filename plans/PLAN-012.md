# PLAN-012 — Probar stacks ittools, metube, shaarli y gokapi

- **Issue GitHub:** #6
- **Fecha:** 2026-11-09
- **Estado:** en curso

## Objetivo

Desplegar en producción (`new_atareao`, usuario `runner`) cuatro stacks de **fricción cero real** (sin `podman secret`, sin OIDC, sin binds que necesiten `chown`) para probarlos, verificarlos end-to-end y **volver a desinstalarlos y purgarlos** al terminar.

## Stacks

| Stack | Imagen | Puerto | Almacenamiento | URL |
|---|---|---|---|---|
| ittools | `docker.io/corentinth/it-tools:latest` | 80 | ninguno | ittools.servidorlinux.es |
| metube | `docker.io/alexta69/metube:latest` | 8081 | volumen `metube-metube` → `/downloads` | metube.servidorlinux.es |
| shaarli | `docker.io/shaarli/shaarli:latest` | 80 | volúmenes `shaarli-cache` y `shaarli-data` | shaarli.servidorlinux.es |
| gokapi | `docker.io/f0rc3/gokapi:latest` | 80 | volúmenes `gokapi-config` y `gokapi-data` | gokapi.servidorlinux.es |

Todos: red `proxy.network`, dominio `Host(`<stack>.${FQDN}`)`, `websecure` + `certresolver=letsencrypt`.

## Verificaciones previas hechas

- Ninguno declara `Secret=` ni `OIDC`.
- Los tags de imagen existen (comprobados en Docker Hub, HTTP 200).
- Ningún bind host-side bajo `~/.config/<stack>` → no requiere `mkdir`/`chown`.

## Fase A — repo

- No hay cambios de quadlets. Crear este plan y el issue de GitHub.

## Fase B — despliegue

1. `yadm pull` en prod (usuario `runner`).
2. Por cada stack: `cd .config/containers/available/<stack> && qctl install `.
3. `systemctl --user daemon-reload` y `systemctl --user start <stack>`.

## Fase C — verificación

- Unit `active`, contenedor arriba, router Traefik registrado, cert LE válido y HTTP correcto en `https://<stack>.servidorlinux.es `.

## Fase D — purga (objetivo final: no dejar nada)

1. Por cada stack: `qctl uninstall` (parar + desenlazar).
2. `qctl clean-volumes` (o `podman volume rm`) para `metube-metube`, `shaarli-{cache,data}`, `gokapi-{config,data}`.
3. `podman rmi` de las cuatro imágenes.
4. Comprobar: sin symlinks en `~/.config/containers/systemd/`, `podman ps -a` limpio.

## Criterios de aceptación

- Los cuatro stacks verificados (unit + contenedor + router + cert + HTTP).
- Al terminar, TODO purgado: sin units, sin volúmenes, sin imágenes.
- `docs/<stack>.md` con sección «Estado de despliegue» reflejando probado + purgado; `HANDOFF.md` actualizado.

## Tareas

- [ ] Crear issue GitHub.
- [ ] Fase B: `yadm pull` + `qctl install` + start de los cuatro.
- [ ] Fase C: verificación end-to-end de cada stack.
- [ ] Fase D: `qctl uninstall` + volúmenes + imágenes (purga total).
- [ ] Actualizar `docs/` y `HANDOFF.md`; archivar este plan.