---
# PLAN-022 — Probar stacks homer, dockge, laverna, pastebin, vaultwarden y microbin

- **Issue:** #17
- **Estado:** completado (2026-11-10)
- **Fecha:** 2026-11-10

## Contexto
Ronda de verificación E2E del inventario `docs/estado-verificacion-e2e.md` (75 stacks sin verificar).
Lote de 6 stacks, todos de un solo contenedor. Flujo y purga según `docs/gestion-stacks-qctl.md `.
Infra de producción: usuario `runner` (uid 1002) en `new_atareao`, FQDN `servidorlinux.es`, acceso vía wrapper `rr`.

## Objetivos
- [x] Desplegar y verificar E2E los 6 stacks: homer, dockge, laverna, pastebin, vaultwarden, microbin.
- [x] Corregir los bugs latentes detectados (quadlets y docs).
- [x] Purgar los 6 stacks (`qctl purge --secrets --images --data -y`) dejando prod limpio.
- [x] Actualizar `docs/estado-verificacion-e2e.md` (50 → 56 verificados, 75 → 69 sin verificar) y `HANDOFF.md `.
- [x] Asegurar `docs/<stack>.md` de los 6 (ya existen; revisar contenido tras los cambios).
- [x] Archivar el plan: `plans/PLAN-022-ARCHIVED.md `.

## Stacks, configuración prevista y riesgos

| Stack | Dominio | Imagen | Servicio/port | Volúmenes/binds | Secretos | Riesgo latente a comprobar |
|---|---|---|---|---|---|---|
| homer | `homer.${FQDN}` | `docker.io/b4bz/homer` | 8080 | bind `~/.config/homer/assets`; `User=1000:1000` | — | el bind `assets` debe existir y ser escribible por uid 1000 (`podman unshare chown -R 1000:1000`); si falta `config.yml`, Homer sirve la demo |
| dockge | `dockge.${FQDN}` | `docker.io/louislam/dockge` | 5001 | socket podman.sock (ro) + binds `~/.config/dockge/stacks`, `~/.config/dockge/data` | — | socket podman.sock debe existir; `HealthCmd=/app/extra/healthcheck`; los binds deben existir |
| laverna | `laverna.${FQDN}` | `docker.io/atareao/laverna:v1.0` | 8080 | bind `~/.config/laverna/htpasswd` | — | imagen no oficial; bind `htpasswd` debe existir; auth básica (401/200) |
| pastebin | `pastebin.${FQDN}` | `docker.io/atareao/pastebin:v1.0` | 8081 | bind `~/.config/pastebin/db` | — | imagen no oficial; bind `db` debe existir; service port 8081 |
| vaultwarden | `vaultwarden.${FQDN}` | `docker.io/vaultwarden/server:latest` | 80 | bind `~/.config/vaultwarden/data` | `vaultwarden_admin_token` (ADMIN_TOKEN) | ADMIN_TOKEN por `Secret=` (crear con `podman secret create`); signups; el bind `data` debe existir |
| microbin | `microbin.${FQDN}` | `docker.io/danielszabo99/microbin:latest` | 8080 | `microbin-microbin.volume:/app/data` + socket podman.sock (ro) | `microbin_basic_auth_password`, `microbin_admin_password` | 2 secretos; socket podman.sock; muchos envs `MICROBIN_*` |

## Fases

### 1. Preparación (local)
- Revisar los 6 quadlets y sus docs; `qctl check` para colisiones (basename/ContainerName/router).
- Comprobar que los dominios no colisionan con los ya usados (`homer`, `dockge`, `laverna`, `pastebin`, `vaultwarden`, `microbin`).

### 2. Despliegue y verificación E2E (prod, usuario `runner` vía `rr`)
Por cada stack, en orden:
1. `cd ~/.config/containers/available/<stack>` (tras `yadm pull`).
2. Crear los secretos necesarios con **`podman secret create`** (nunca `crypta store`):
   - vaultwarden: `vaultwarden_admin_token `.
   - microbin: `microbin_basic_auth_password`, `microbin_admin_password `.
3. Preparar los binds que lo requieran (homer `assets/`, dockge `stacks/` + `data/`, laverna `htpasswd`, pastebin `db/`, vaultwarden `data/`); chownear con `podman unshare` los que corran con uid 1000.
4. `qctl install` y `qctl start <unit>`.
5. Verificar los 5 puntos E2E: (a) unit `active`; (b) contenedor en `podman ps`; (c) router registrado en Traefik; (d) certificado LE válido para el dominio; (e) URL responde con el HTTP esperado (`curl -sS -o /dev/null -w '%{http_code}' `).

### 3. Corrección de bugs latentes
- Arreglar quadlets/docs según hallazgos (delegar la escritura al subagente correspondiente).
- Tras corregir, **recrear** el contenedor y, si Traefik no re-registra el router, `systemctl --user restart traefik `.

### 4. Purga
- Por stack: `qctl purge --secrets --images --data -y`; revisar restos manuales (binds con uid mapeado con `podman unshare rm -rf`, volúmenes anónimos *dangling*).
- Comprobar limpieza: `podman ps -a`, `podman volume ls`, `podman secret ls`, `podman images`, symlinks en `~/.config/containers/systemd/`.

### 5. Documentación y cierre
- Actualizar `docs/estado-verificacion-e2e.md`, `HANDOFF.md` y los `docs/<stack>.md` afectados.
- Renombrar el plan a `plans/PLAN-022-ARCHIVED.md `.

## Criterios de aceptación
- Los 6 stacks alcanzan los 5 puntos E2E (o el hallazgo documentado que lo impida).
- Prod limpio al cerrar: solo `errserve`, `headscale`, `headscale-headplane`, `pocketid`, `traefik `.
- Inventario y HANDOFF actualizados; plan archivado.

## Follow-ups previstos
- Eliminar `dingpdf` (duplicado de `pdfding`).
- Revisar el dominio de `zennotes`: enruta `Host(${FQDN})` (apex) → posible conflicto; valorar subdominio propio.
- Laverna está abandonada (última release ~2018): valorar migración a otra app de notas.
- Vigilar la cuota de Let's Encrypt de producción (50 certs/dominio/168 h); seguir usando staging en las rondas E2E.

## Resultado (2026-11-10)

Ronda cerrada: **6 stacks verificados E2E** (5 puntos) y **purgados**; prod limpio.

| Stack | HTTP | Resultado |
|---|---|---|
| homer | 200 | OK |
| dockge | 200 | OK (healthy) |
| vaultwarden | 200 | OK |
| microbin | 401 | OK (auth básica esperada) |
| pastebin | 303→200 | OK tras cambiar la imagen |
| laverna | 401/200 | OK tras cambiar la imagen + añadir basicAuth en Traefik |

### Hallazgos e incidencias

1. **Let's Encrypt: 429 rate limit.** Las rondas E2E habían agotado la cuota de producción (50 certs por
   dominio / 168 h). Se añadió un segundo resolver `letsencrypt-staging` a `.config/traefik/traefik.yml`
   (CA staging, storage `acme-staging.json`, HTTP-01) y las pruebas usan
   `Label=traefik.http.routers.<x>.tls.certresolver=letsencrypt-staging`. Documentado en `docs/traefik.md`.
   Nota: el dominio tiene los NS en `dondominio` (no Cloudflare), así que el reto no puede ser DNS-01/wildcard
   con el `cf_dns_api_token` actual.
2. **Imágenes de atareao desaparecidas.** `docker.io/atareao/laverna:v1.0` y `docker.io/atareao/pastebin:v1.0`
   ya no existen en Docker Hub (el autor los construye con `build: .`).
   - **pastebin** → `docker.io/mkaczanowski/pastebin:latest` (el binario upstream), con
     `Exec=--address 0.0.0.0 --port 8081 --db=/rs/db/pastebin.db`.
   - **laverna** → `docker.io/olegfiksel/laverna:0.7.54` (nginx, puerto 80); se quitó el bind `htpasswd` del
     contenedor y la basic-auth pasó a Traefik con el middleware `laverna-auth@file`
     (`.config/traefik/dynamic/laverna-auth.yml`, leyendo `~/.config/traefik/dynamic/laverna.htpasswd`, no versionado).
3. Los `sed` temporales de `certresolver` en prod se revirtieron con `yadm checkout` (los quadlets versionados
   apuntan al resolver de producción `letsencrypt`).

### Purga
Los 6 stacks purgados con `qctl purge --secrets --images --data -y`; sin volúmenes dangling ni binds residuales.
Prod final: solo `errserve`, `headscale`, `headscale-headplane`, `pocketid`, `traefik`.
---