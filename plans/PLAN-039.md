# PLAN-039 — Ronda E2E lote 10b: gitea, open-webui, pinepods, vector

- **Issue:** #33 (Ronda E2E lote 10) — este plan cierra el sub-lote **10b**.
- **Fecha apertura:** 2026-11-13
- **Rama:** `main` (este repo usa commits gitmoji directos a `main`, sin gitflow).

## Contexto y objetivo

El lote 10 (9 stacks MEDIO con dependencias externas) se partió en dos. El **lote 10a** (`crowdsec`, `miniflux`, `nitter`, `dev`, `firefly`) ya está cerrado y verificado E2E en producción (ver `plans/PLAN-038-ARCHIVED.md`). El inventario quedó en 127 = 104 verificados + 5 en producción + 3 bloqueados + 15 sin verificar.

Este plan cubre el **lote 10b**: corregir bugs latentes detectados en auditoría estática, desplegar en `new_atareao` (usuario `runner`, rootless Podman), verificar E2E y purgar los stacks de ejemplo. Criterio E2E: unit `active`, contenedor `healthy`, router Traefik registrado, certificado Let's Encrypt válido y HTTP esperado.

## Hallazgos confirmados (auditoría estática)

Todos verificados sobre el árbol actual; ninguno descartado.

### gitea (`.config/containers/available/gitea/`)
- `gitea.container:41-57` — **Falta trusted-proxy**: la app no confía en `X-Forwarded-For`; solo declara `Network=proxy.network`. Debe confiar en la subred `10.89.0.0/24`.
- `gitea.container:41,42` — `GITEA__server__DOMAIN` y `SSH_DOMAIN` apuntan al host desnudo `${FQDN}`, desalineados con `ROOT_URL` (`:43`) y el router (`:54`), que usan `gitea.${FQDN}`.
- `gitea.container:10` — `Image=docker.io/gitea/gitea:1.19` (pin viejo).
- `gitea.container:59` — sección Healthcheck **vacía`.
- (OK, sin cambios: `Secret=gitea_db_password` coherente entre `gitea.container:29` y `gitea-db.container:23`.)

### open-webui (`.config/containers/available/open-webui/`)
- `open-webui.container:31` — `WEBUI_SECRET_KEY=` **vacío** (sección Secrets en `:26` también vacía).
- `open-webui.container:3` — **sin dependencias** (`After=network-online.target` solo, sin `Requires`) hacia el contenedor `open-webui-ollama`.
- `open-webui.container:33,36` — Labels y Healthcheck **vacíos`.

### pinepods (`.config/containers/available/pinepods/`)
- `pinepods.container:32` (`pinepods_db_password`→`DB_PASSWORD`) vs `pinepods-postgresql.container:27` (`pinepods_postgres_password`→`POSTGRES_PASSWORD`) — **dos secretos distintos para la misma BD** (riesgo de desalineación).
- `pinepods.container:37` — `HOSTNAME=https://{FQDN}` con **llaves simples** → no expande (el resto usa `${FQDN}`).
- `pinepods.container:3` — **sin deps** a `pinepods-postgresql` ni `pinepods-valkey`.
- Healthchecks **vacíos** en los tres contenedores (`pinepods.container:58`, `pinepods-postgresql.container:37`, `pinepods-valkey.container:36`).
- (OK: `DB_HOST=pinepods_db` / `VALKEY_HOST=pinepods_valkey` cuadran con los `NetworkAlias`.)

### vector (`.config/containers/available/vector/`, config en `.config/vector/`)
- `vector.yaml:43` — **URI con template inválido**: `uri: "http://openobserve:5080/api/default/${.container_name:-syslog}/_json"`. El sink `http` de Vector no interpola campos por evento; `${...}` se interpreta como variable de entorno → URI roto.
- `vector.yaml:51-60` + `vector.container:31` — **sink crowdsec muerto**: `password: "${VECTOR_INGEST_PASSWORD:-}"` siempre vacío porque el `Secret=crowdsec_ingest_password` está **comentado**; además crowdsec no define ingest.
- `vector.container:19,20` (`/var/log/journal`, `/run/log/journal`) y `:48` (`AddCapability=CAP_DAC_READ_SEARCH`) — **muertos**: no hay source `journald` (`vector.yaml:9-10` solo declara `type: "docker_logs"`).

## Tareas

### A. gitea
- [ ] A1. Añadir trusted-proxy: `GITEA__security__REVERSE_PROXY_TRUSTED_PROXIES=10.89.0.0/24` en `Environment=`, y comprobar si hace falta `GITEA__security__REVERSE_PROXY_TRUSTED_PROXIES` o la variante que use esta versión de imagen (documentar la elegida).
- [ ] A2. Alinear `GITEA__server__DOMAIN` y `SSH_DOMAIN` con `gitea.${FQDN}` (coherente con `ROOT_URL` y el router). Documentar la decisión (si el SSH se expone en el host, justificarlo; si no, usar el subdominio).
- [ ] A3. Añadir `HealthCmd` (p. ej. `curl -fsS http://127.0.0.1:3000/api/healthz`) manteniendo el esqueleto de 11 secciones.
- [ ] A4. Evaluar bump del pin `gitea:1.19` a una versión estable actual; aplicar solo si el cambio es seguro y documentar.

### B. open-webui
- [ ] B1. Crear secreto `open_webui_secret_key` con `podman secret create open_webui_secret_key -` (NUNCA `crypta store`) e inyectarlo con `Secret=open_webui_secret_key,type=env,target=WEBUI_SECRET_KEY` (eliminar el `WEBUI_SECRET_KEY=` vacío).
- [ ] B2. Añadir `After=open-webui-ollama.service` + `Requires=open-webui-ollama.service` a `open-webui.container`; valorar lo mismo en el contenedor ollama si procede.
- [ ] B3. Añadir `HealthCmd` si es viable.

### C. pinepods
- [ ] C1. Unificar a **un solo** secreto de BD: usar `pinepods_db_password` en ambos contenedores (target `DB_PASSWORD` en la app, `POSTGRES_PASSWORD` en postgresql) y eliminar `pinepods_postgres_password` del repo y de la lista de secretos.
- [ ] C2. Corregir `HOSTNAME=https://{FQDN}` → `https://${FQDN}` (`pinepods.container:37`).
- [ ] C3. Añadir `Requires`/`After` hacia `pinepods-postgresql.service` y `pinepods-valkey.service`.
- [ ] C4. Añadir Healthchecks: `pg_isready` en postgresql, `valkey-cli ping` en valkey, health de la app si es viable.

### D. vector
- [ ] D1. Corregir el URI del sink openobserve a un URI fijo válido (p. ej. `http://openobserve:5080/api/default/vector/_json`), sin template por evento.
- [ ] D2. Decidir el sink crowdsec: **eliminarlo** (junto con el `Secret=` comentado y su documentación) dado que crowdsec no tiene ingest configurado, dejando follow-up; o, si se decide lo contrario, cablear `VECTOR_INGEST_PASSWORD` con un `Secret=` real creado por `podman secret create`.
- [ ] D3. Eliminar los mounts de journal (`/var/log/journal`, `/run/log/journal`) y `AddCapability=CAP_DAC_READ_SEARCH` por no tener source `journald`.
- [ ] D4. Mantener el orden `EnvironmentFile` = `.env` luego `.env.local` y validar `vector validate`.

### E. Validación local (sin tocar `~/.config/containers/systemd`)
- [ ] E1. Renderizar cualquier `.jinja` afectado (emular `unjinja`) y validar cada stack en aislamiento con `QUADLET_UNIT_DIRS=<dir> /usr/lib/podman/quadlet -user -dryrun`, incluyendo las redes compartidas referenciadas.

### F. Despliegue y verificación E2E (producción `new_atareao`, usuario `runner` vía `lorenzo` + `rr`)
- [ ] F1. Crear los secretos necesarios con `podman secret create` antes de arrancar cada unit.
- [ ] F2. `qctl install` desde el directorio de cada stack + `systemctl --user daemon-reload` + arranque.
- [ ] F3. Verificar E2E (unit active, contenedor healthy, router Traefik, cert LE válido, HTTP esperado) y documentar hallazgos transversales.
- [ ] F4. Purgar los stacks de ejemplo tras verificar (recrear sus secretos si se vuelven a desplegar). Decidir expresamente si `vector` se conserva por su rol de observabilidad, dejando la decisión documentada.

### G. Documentación y cierre
- [ ] G1. Actualizar/crear `docs/{gitea,open-webui,pinepods,vector}.md` con ficheros implicados, decisiones, secretos y follow-ups.
- [ ] G2. Actualizar `docs/estado-verificacion-e2e.md` (contador de inventario) y la sección de blockers.
- [ ] G3. Commits gitmoji en `main`, y al cerrar renombrar este plan a `plans/PLAN-039-ARCHIVED.md` y actualizar `HANDOFF.md`.

## Riesgos y notas
- La purga borra los secretos: si algún stack de 10b se re-despliega hay que recrearlos.
- Cualquier `Secret=` nuevo debe existir antes de arrancar la unit (aquí **sí** aplica `podman secret create`, nunca `crypta store`).
- Recuerda: tras recrear un contenedor puede caer el enrutado de Traefik → `systemctl --user restart traefik` si no enruta.

## Criterio de cierre
Todas las casillas marcadas, los stacks verificados E2E (o purgados y documentados), inventario actualizado y plan archivado.