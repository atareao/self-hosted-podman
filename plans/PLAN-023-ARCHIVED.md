# PLAN-023 — Limpieza de follow-ups y colisiones de enrutado

- **Issue:** #18
- **Estado:** completado (2026-11-10)
- **Fecha:** 2026-11-10

## Contexto

Ronda de limpieza sin despliegue E2E. Recoge los follow-ups abiertos en PLAN-021/022 y las
colisiones de enrutado de Traefik detectadas al auditar los quadlets. Todas son bugs latentes:
los stacks afectados están en «sin verificar», por lo que nunca se manifestaron en producción.

Traefik globaliza los nombres de **routers** y **services**: dos stacks con el mismo nombre se
pisan (`grafana`, `pdfding`). Además, dos routers con la misma regla `Host(...)` y sin
`PathPrefix` de distinto tamaño son una colisión real (gana uno y el otro queda inaccesible).

## Objetivos

- [x] Eliminar el stack duplicado `dingpdf` y todas sus referencias.
- [x] Dar subdominio propio a los 4 stacks que reclaman el apex `Host(${FQDN})`.
- [x] Deshacer la colisión de router/servicio `grafana` (nombres globales en Traefik).
- [x] Deshacer las colisiones de host sin path en `tick`, `matrix` y `miniflux`.
- [x] Deprecar y eliminar `laverna` del repo (quadlet, doc y middleware de Traefik).
- [x] Actualizar inventario, HANDOFF y docs afectados.
- [x] Archivar el plan: `plans/PLAN-023-ARCHIVED.md`.

## Cambios

### 1. dingpdf (duplicado de pdfding)

| Acción | Fichero |
|---|---|
| Eliminar stack | `.config/containers/available/dingpdf/` (`dingpdf-pdfding.container`, `dingpdf-media.volume`, `dingpdf-sqlite_data.volume`) |
| Eliminar doc | `docs/dingpdf.md` |
| Editar | `docs/pdfding.md` (quitar el follow-up del duplicado) |
| Editar | `docs/gestion-stacks-qctl.md` (quitar la mención «compartida con dingpdf») |
| Editar | `docs/estado-verificacion-e2e.md` (quitar `dingpdf` de sin verificar; nota de la fila pdfding) |

Evidencia del duplicado: misma imagen `docker.io/mrmn/pdfding:latest`, mismos volúmenes
(`*-sqlite_data`, `*-media`) y mismo rol; sólo cambia el dominio (`dingpdf` vs `pdfding`).

### 2. Colisión de apex `Host(${FQDN})` → subdominio

El origen tenía `${FQDN}` como «el dominio de ese stack»; en el repo consolidado eso hace que
cuatro stacks reclamen el dominio raíz. Se corrige con la convención `<stack>.${FQDN}`.

| Stack | Fichero | Antes | Después |
|---|---|---|---|
| zennotes | `zennotes/zennotes.container` | `Host(${FQDN})` | `Host(zennotes.${FQDN})` |
| umami | `umami/umami.container` | `Host(${FQDN})` | `Host(umami.${FQDN})` |
| watchbeat | `watchbeat/watchbeat.container` | `Host(${FQDN})` | `Host(watchbeat.${FQDN})` |
| alloy | `alloy/alloy.container` | `Host(${FQDN})` | `Host(alloy.${FQDN})` |

Docs a actualizar: `docs/zennotes.md`, `docs/umami.md`, `docs/watchbeat.md`, `docs/alloy.md`.

### 3. Nombre global `grafana` duplicado (tick vs grafana-influx-telegraf)

`grafana-influx-telegraf` conserva router/servicio `grafana` (host `grafana.${FQDN}`).
`tick` renombra los suyos a `tick-grafana` / `tick-influxdb` y separa hosts:

| Fichero | Antes | Después |
|---|---|---|
| `tick/tick-grafana.container` | router/servicio `grafana`, host `tick.${FQDN}` | router/servicio `tick-grafana`, host `tick.${FQDN}` |
| `tick/tick-influxdb.container` | router/servicio `influxdb`, host `tick.${FQDN}` | router/servicio `tick-influxdb`, host `influxdb.${FQDN}` |

Va en línea con el origen (`GRAFANA_FQDN` e `INFLUXDB_FQDN` eran dominios distintos).
Doc a actualizar: `docs/tick.md`.

### 4. Colisiones de host sin `PathPrefix`

| Fichero | Antes | Después |
|---|---|---|
| `matrix/matrix-element.container` | `Host(matrix.${FQDN})` | `Host(element.${FQDN})` |
| `miniflux/miniflux-reactflux.container` | `Host(miniflux.${FQDN})` | `Host(reactflux.${FQDN})` |

`matrix` (conduit, puerto 6167) y `miniflux` (puerto 8080) conservan su dominio.
Docs a actualizar: `docs/matrix.md`, `docs/miniflux.md`.

No se toca `headscale` + `headplane`: comparten `Host(headscale.${FQDN})` a propósito
(`headplane` añade `&&PathPrefix(/admin)`).

### 5. Eliminar laverna (app abandonada)

| Acción | Fichero |
|---|---|
| Eliminar stack | `.config/containers/available/laverna/` |
| Eliminar doc | `docs/laverna.md` |
| Eliminar middleware | `.config/traefik/dynamic/laverna-auth.yml` |
| Editar | `docs/estado-verificacion-e2e.md` (quitar la fila de laverna de verificados) |
| Editar | `HANDOFF.md` (quitar laverna del lote de PLAN-022 y el follow-up) |

Motivo: Laverna no tiene mantenimiento desde ~2018 y su imagen ya no existe en Docker Hub
(en PLAN-022 se sustituyó por `olegfiksel/laverna` con basic-auth en Traefik, pero no merece
la pena mantener la dependencia). La regla `.config/traefik/dynamic/*.htpasswd` del `.gitignore`
se conserva (es genérica).

## Fases

### 1. Preparación
- `git rm` de los stacks/docs/middleware eliminados.
- Edición de los 8 quadlets y sus docs.

### 2. Validación
- Render de los quadlets tocados + `QUADLET_UNIT_DIRS=<tmp> /usr/lib/podman/quadlet -user -dryrun`
  (sin tocar `~/.config/containers/systemd`).
- Comprobación de que no quedan duplicados: `ContainerName=`, nombres de router/servicio y reglas `Host(...)`.
- `grep` de que no queda ninguna referencia a `dingpdf`, `laverna`, `laverna-auth` ni a `Host(${FQDN})`.

### 3. Cierre
- Actualizar `docs/estado-verificacion-e2e.md` y `HANDOFF.md`.
- Renombrar a `plans/PLAN-023-ARCHIVED.md`; commit y push; cerrar issue #18.

## Criterios de aceptación

- No queda ninguna referencia a `dingpdf` ni `laverna` en el repo (salvo planes archivados, históricos).
- Ningún quadlet enruta `Host(${FQDN})` (apex) ni duplica `ContainerName`, router, servicio o regla host.
- Los quadlets tocados pasan `quadlet -dryrun` sin errores nuevos.
- Inventario coherente: 127 stacks = 55 verificados + 4 en producción + 68 sin verificar.

## Follow-ups previstos

- Valorar si algún stack debe servir el apex `${FQDN}` (hoy nadie lo hace; cae en el catch-all `errserve`).
- `huginn` contiene dos variantes de la misma app (`huginn.container` y `huginn-threaded.container`): decidir cuál queda.
- Revisar otros stacks multi-contenedor (`dev`, `wordpress-wp1/2`) por si arrastran el mismo patrón de host único.

## Resultado (2026-11-10)

- **dingpdf** eliminado (duplicado exacto de `pdfding`) y **laverna** eliminado junto con su doc y el middleware `.config/traefik/dynamic/laverna-auth.yml`.
- **Apex**: `zennotes`, `umami`, `watchbeat` y `alloy` pasan a `<stack>${FQDN}`; ya nadie reclama el dominio raíz.
- **tick**: routers y servicios renombrados a `tick-grafana` / `tick-influxdb` (ya no colisionan con el `grafana` de `grafana-influx-telegraf`); InfluxDB movido a `influxdb.${FQDN}`.
- **matrix**: Element Web a `element.${FQDN}` (Conduit conserva `matrix.${FQDN}`). **miniflux**: ReactFlux a `reactflux.${FQDN}`.
- **Validación**: `QUADLET_UNIT_DIRS=<tmp> /usr/lib/podman/quadlet -user -dryrun` sobre los 7 stacks tocados → 0 errores. Escaneo del repo: sin duplicados de `ContainerName`, router, servicio ni regla `Host(...)` (única duplicidad restante, intencional: `headscale` + `headplane` comparten host con `&&PathPrefix(\`/admin\`)`). Sin `Host(\`${FQDN}\`)` residual. No queda ninguna referencia a `dingpdf` ni `laverna` fuera de planes archivados.
- **Inventario**: 127 stacks = 55 verificados + 4 en producción + 68 sin verificar.
- No requirió despliegue en producción (todos los stacks afectados estaban sin verificar).
