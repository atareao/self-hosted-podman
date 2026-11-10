# PLAN-024 — Roles e invariantes de enrutado (cierre de follow-ups)

- **Issue:** #19
- **Estado:** completado (2026-11-10)
- **Fecha:** 2026-11-10

## Contexto

Cierra los tres follow-ups vivos de PLAN-022/023 tras auditarlos. No hay despliegue ni cambio de
comportamiento: el resultado de la auditoría es que el enrutado ya está sano y lo que falta es
documentarlo bien y deshacer un falso positivo.

## Hallazgos de la auditoría

1. **`huginn` no es un duplicado** (falso positivo). El repo origen define tres servicios:
   `mariadb`, `huginn` (web) y `threaded` (worker, `WORKER_CMD=bin/threaded.rb`). Ambos contenedores
   usan la misma imagen `docker.io/huginn/huginn-single-process` pero con rol distinto, igual que
   otros stacks con worker (p. ej. `wger`). Se quedan los tres. Lo que está mal es `docs/huginn.md`:
   está generado automáticamente con roles y nombres de fichero incorrectos.
2. **Stacks multi-contenedor (45 auditados)**: ninguna BBDD, Redis ni worker se expone; no queda
   ninguna regla `Host(...)` duplicada salvo `headscale` + `headplane` (intencional, `&&PathPrefix(/admin)`).
   `mumble` publica `64738/tcp+udp` directamente (`PublishPort`), no vía Traefik, por ser un protocolo
   no HTTP. `open-webui`, `authentik`, `publirs`, `miniflux-client` y `matrixmail` no se enrutan tampoco
   en el repo origen → no es un bug de migración, es exposición manual por diseño.
3. **Apex `${FQDN}`**: ningún stack lo reclama desde PLAN-023. Hoy lo atiende el router catch-all
   `errserve-catchall` (`HostRegexp(.+)`, `priority=1`), que sirve páginas de error. **No es urgente
   definirlo**; se documenta como «sin dueño explícito» y revisable.

## Objetivos

- [x] Reescribir `docs/huginn.md` con los roles reales (web + worker + mariadb) y los nombres de fichero correctos.
- [x] Añadir a `docs/traefik.md` una sección de invariantes de enrutado con el comando de auditoría.
- [x] Añadir una nota de exposición a los docs de los stacks sin router por diseño.
- [x] Actualizar `docs/estado-verificacion-e2e.md` y `HANDOFF.md`.
- [x] Archivar el plan: `plans/PLAN-024-ARCHIVED.md`.

## Fases

### 1. Documentación

- `docs/huginn.md`: reescritura completa.
- `docs/traefik.md`: sección `## Invariantes de enrutado`.
- Notas de exposición en `docs/open-webui.md`, `docs/authentik.md`, `docs/publirs.md`,
  `docs/miniflux-client.md`, `docs/matrixmail.md` y `docs/mumble.md`.

### 2. Verificación

- Auditoría de duplicados (`ContainerName=`, nombres de router/servicio y reglas `Host(...)`).
- `grep` de que ningún doc afirma ya que `huginn` es un duplicado.

### 3. Cierre

- Actualizar inventario y HANDOFF; renombrar a `plans/PLAN-024-ARCHIVED.md`; commit, push y cierre del issue #19.

## Criterios de aceptación

- `docs/huginn.md` describe los tres contenedores con su rol y sus ficheros reales.
- `docs/traefik.md` documenta los invariantes: host único, nombres globales de router/servicio, apex sin
  dueño, política multi-contenedor, y el comando de auditoría.
- Auditoría sin duplicados (salvo `headscale`+`headplane`) y sin referencias al falso positivo.
- Sin cambios en quadlets ni en la configuración de Traefik.

## Follow-ups previstos

- Decidir si algún stack sirve el apex `${FQDN}` (hoy lo atiende el catch-all de `errserve`).
- Renombrar el volumen `huginn-huginn_mariadb` a `huginn-mariadb` (convención `<stack>-<rol>`); cosmético, requiere coordinar el renombrado del `.volume` y de la `Volume=` del quadlet.

## Resultado (2026-11-10)

- `docs/huginn.md` reescrito: los tres contenedores y su rol (web `huginn` puerto 3000; worker `huginn-threaded` con `WORKER_CMD=bin/threaded.rb`; BD `huginn-mariadb`), ficheros reales, secretos y despliegue. Queda explícito que **no son duplicados**.
- `docs/traefik.md` con la sección `## Invariantes de enrutado`: host único por router (excepción `headscale`+`headplane` con `/admin`), nombres de router/servicio globales (prefijar con el stack), apex `${FQDN}` sin dueño (lo atiende el catch-all de `errserve`), política multi-contenedor, y bloque «Auditoría rápida» con los comandos.
- Notas de exposición añadidas a `docs/open-webui.md`, `docs/authentik.md`, `docs/publirs.md`, `docs/miniflux-client.md`, `docs/matrixmail.md` (sin router por diseño, igual que el origen) y `docs/mumble.md` (`PublishPort` 64738 tcp/udp).
- **Auditoría final:** sin duplicados de `ContainerName`, router ni servicio; la única regla `Host(...)` repetida es `headscale.${FQDN}` (intencional). Sin cambios en quadlets ni en la configuración de Traefik.
- Inventario sin cambios de cifras: 127 stacks = 55 verificados + 4 en producción + 68 sin verificar.
