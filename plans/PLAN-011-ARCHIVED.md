# PLAN-011 — Desplegar stacks dozzle, navidrome, stirling-pdf y memos

- **Issue GitHub:** #5
- **Fecha:** 2026-11-09
- **Estado:** completado

## Objetivo

Desplegar en producción (`new_atareao`, usuario `runner`, rootless Podman + Traefik) cuatro
stacks ya presentes en el repo y de **fricción cero** (sin `podman secret`, sin OIDC, sin
`.env.local`): **dozzle**, **navidrome**, **stirling-pdf** y **memos**. Cada uno se sirve en su
subdominio `servidorlinux.es`.

## Estado actual (reconocimiento)

- Repo: quadlets en `.config/containers/available/<stack>/` y docs en `docs/<stack>.md`.
  Los cuatro ya declaran `Host(`<stack>.${FQDN}`)`, así que **no requieren cambios de fichero**.
- Producción: `FQDN=servidorlinux.es`; OIDC = PocketID (`auth.servidorlinux.es`).
  Corriendo: `errserve`, `pocketid`, `traefik`, `headscale`, `headscale-headplane`.
  El dominio raíz está libre.

## Detalle de los stacks

| Stack | Imagen | Puerto | Almacenamiento | URL |
|---|---|---|---|---|
| dozzle | `amir20/dozzle` | 8080 | monta `%t/podman/podman.sock` (ro) | dozzle.servidorlinux.es |
| navidrome | `deluan/navidrome` | 4533 | binds `%h/.config/navidrome/music` (ro) y `/data` | navidrome.servidorlinux.es |
| stirling-pdf | `stirlingtools/stirling-pdf` | 8080 | 5 volúmenes (trainingData, configs, customFiles, logs, pipeline) | stirling-pdf.servidorlinux.es |
| memos | `neosmemo/memos` | 5230 | volumen `memos-memos` | memos.servidorlinux.es |

## Particularidades

- **navidrome**: usa *bind mounts* bajo `%h/.config/navidrome/` → crear en prod `music/` y
  `data/` antes de arrancar. Arranca con biblioteca vacía (sin música).
- **dozzle**: necesita el socket `%t/podman/podman.sock` (ya disponible en runner).
- **stirling-pdf**: varios volúmenes nombrados; se crean solos con `qctl install`.
- **memos**: volumen nombrado `memos-memos`; crea el admin la primera vez desde la UI.

## Fase A — repo

- Sin cambios de quadlets (ya en subdominio y sin secretos).
- Crear `plans/PLAN-011.md` (este plan) y el issue de GitHub.

## Fase B — preparación en prod

1. `yadm pull` en prod (usuario `runner`) para asegurar el árbol al día.
2. Crear directorios de navidrome: `mkdir -p ~/.config/navidrome/music ~/.config/navidrome/data`.

## Fase C — despliegue y verificación

1. Por cada stack: `cd .config/containers/available/<stack> && qctl install`.
2. `systemctl --user daemon-reload`.
3. Verificar por stack: unit `active`, contenedor arriba, router Traefik registrado,
   cert LE válido y respuesta HTTP en `https://<stack>.servidorlinux.es`.
4. Logs ante fallo: `journalctl --user -u <unit>`.

## Criterios de aceptación

- Los cuatro stacks: unit activo, contenedor arriba, router activo, cert LE y URL responde.
- Ningún stack ocupa el dominio raíz.
- Sin secretos nuevos (ninguno requerido).
- `docs/<stack>.md` actualizadas con la URL final; `HANDOFF.md` actualizado al cierre.

## Tareas

- [x] Crear issue GitHub de la feature.
- [x] Fase B: `yadm pull` en prod + crear directorios de navidrome.
- [x] Fase C: `qctl install` de los cuatro + `daemon-reload`.
- [x] Fase C: verificación end-to-end (up + router + cert + HTTP) de cada stack.
- [x] Actualizar `docs/` y `HANDOFF.md`; archivar este plan.
