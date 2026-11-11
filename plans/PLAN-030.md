# PLAN-030 — Ronda E2E lote 2: atuin, beszel, radicale, wakapi, wikijs, zincsearch

- **Issue:** #25
- **Fecha:** 2026-11-11
- **Estado:** COMPLETADO (2026-11-11)

## Objetivo

Continuar las rondas de verificación E2E de stacks en producción (`new_atareao`, usuario `runner`,
rootless Podman) con el lote 2: desplegar, verificar los 5 puntos E2E, corregir bugs latentes y
purgar (unit, volúmenes, secretos, binds e imágenes) cada stack, dejando `docs/` y
`docs/estado-verificacion-e2e.md` actualizados.

## Contexto

- Repo de dotfiles (yadm), no aplicación: sin build/test/lint. Verificación = `qctl status`, `podman ps`,
  router de Traefik, TLS y HTTP.
- `docs/estado-verificacion-e2e.md`: 127 stacks, 59 verificados, 4 en prod, 2 bloqueados, 62 sin verificar.
- Ronda anterior: `plans/PLAN-027-ARCHIVED.md` (lote 1, 6 stacks). Resolver TLS: `letsencrypt-staging`
  para no consumir cuota de producción.
- Flujo de despliegue y purga: `docs/gestion-stacks-qctl.md`. Invariantes de enrutado: `docs/traefik.md`.
- Producción solo como `runner` vía wrapper `rr` (desde `lorenzo`, NOPASSWD).

## Alcance (6 stacks)

| Stack | Units | Imagen(es) | Router / dominio | Secreto(s) `Secret=` |
|---|---|---|---|---|
| atuin | `atuin`, `atuin-postgresql` | `docker.io/ellieh/atuin:latest`, `postgres:latest` | `atuin` / `atuin.${FQDN}` :8888 | `atuin_postgres_password`, `atuin_db_uri` |
| beszel | `beszel`, `beszel-agent` | `henrygd/beszel:latest`, `henrygd/beszel-agent:latest` | `beszel` / `beszel.${FQDN}` :8090 | `beszel_key`, `beszel_token` |
| radicale | `radicale` | `atareao/radicale:v1.0` | `expulsabot`(!) / `radicale.${FQDN}` :5232 | ninguno |
| wakapi | `wakapi`, `wakapi-postgresql` | `ghcr.io/muety/wakapi:latest`, `postgres:17` | `wakapi` / `wakapi.${FQDN}` :3000 | `wakapi_postgres_password`, `wakapi_db_password` |
| wikijs | `wikijs`, `wikijs-postgresql` | `ghcr.io/requarks/wiki:2`, `postgres:14-alpine` | `wikijs` / `wikijs.${FQDN}` :80 | `wikijs_postgres_password`, `wikijs_db_pass` |
| zincsearch | `zincsearch` | `public.ecr.aws/h9e2j3o7/zinc:latest` | `zinc` / `zinc.${FQDN}` :4080 | `zincsearch_zinc_first_admin_password`, `zincsearch_token` |

Notas por stack:

- **beszel**: el agente monta `%t/podman/podman.sock` (ro) y el volumen `beszel-socket`; el hub es quien
  publica router. `beszel_key`/`beszel_token` deben ser el par clave/token coherente entre hub y agente.
- **radicale**: bug latente detectado en lectura estática — router y servicio se llaman `expulsabot`
  (copiar/pegar). Deben ser `radicale` (nombre de router/servicio es global en Traefik).
  Requiere binds `~/.config/radicale/.htpasswd-users` y `~/.config/radicale/data`.
- **wikijs**: `wikijs-postgresql` usa bind `~/.config/wikijs/data` (no volumen nombrado); `wikijs` está en
  `proxy.network` + `wikijs.network`.
- **wakapi**: ambos units cargan `EnvironmentFile=%h/.config/wakapi/wakapi.env` (+`.local`): verificar que
  existan y que las credenciales coincidan con los secretos.
- **zincsearch**: expone `ZINC_FIRST_ADMIN_PASSWORD` y `TOKEN` por secreto; verificar HTTP en la raíz.
- **atuin**: `ATUIN_DB_URI` se inyecta como secreto completo; debe apuntar al host `atuin-postgresql`
  dentro de `atuin.network`.

## Precondiciones

- `unjinja` disponible en el host de `runner` (hook `post_pull`), `qctl` en `~/.local/bin`.
- Secretos creados **con `podman secret create`** (NUNCA `crypta store`) antes de arrancar cada unit.
- `~/.config/environment.d/crypta.conf` desplegado (PLAN-028) para que los healthchecks re-resuelvan `type=env`.
- Binds creados con los permisos correctos antes de `qctl install`.

## Tareas

- [x] T1 — Preflight en prod: `systemctl --user is-system-running`, `qctl check` de los 6 stacks,
      `unjinja` (los `.jinja` renderizados existen).
- [x] T2 — Corregir estáticamente el bug de `radicale` (router/servicio `expulsabot` → `radicale`) en
      `available/radicale/radicale.container`; validar con `QUADLET_UNIT_DIRS` + `quadlet -user -dryrun`.
- [x] T3 — Desplegar **atuin**: secretos, `qctl install`, 5 puntos E2E.
- [x] T4 — Desplegar **beszel**: secretos, binds/volúmenes, `qctl install`, 5 puntos E2E.
- [x] T5 — Desplegar **radicale**: binds + `.htpasswd-users`, `qctl install`, 5 puntos E2E.
- [x] T6 — Desplegar **wakapi**: secretos, `.env`, `qctl install`, 5 puntos E2E.
- [x] T7 — Desplegar **wikijs**: secretos, bind de datos, `qctl install`, 5 puntos E2E.
- [x] T8 — Desplegar **zincsearch**: secretos, `qctl install`, 5 puntos E2E.
- [x] T9 — Purga por stack: `qctl uninstall`, volúmenes, secretos, binds e imágenes.
- [x] T10 — Actualizar `docs/estado-verificacion-e2e.md` (tabla «Verificados E2E», cifras 127 = 65 + 4 + 2 + 56
      si los 6 pasan) y `docs/<stack>.md` con hallazgos.
- [x] T11 — Commit gitmoji en `main` (`🐛 fix`/`📝 docs` según corresponda) y archivar el plan a
      `plans/PLAN-030-ARCHIVED.md`; actualizar `HANDOFF.md`.

## Criterio de verificado E2E (5 puntos)

1. Unit systemd `active` (`systemctl --user is-active <unit>`).
2. Contenedor(es) en ejecución (`podman ps`).
3. Traefik registra el router (`traefik.enable=true` y router visible en la API/logs).
4. Certificado TLS válido para el dominio (staging).
5. `curl` devuelve el HTTP esperado.

## Riesgos

- Cuota de certificados: usar siempre `letsencrypt-staging` en las rondas.
- `postgres:latest` en atuin (tag móvil): si el arranque falla por migración, documentarlo como follow-up
  y fijar tag en un cambio aparte.
- Healthcheck + driver externo de secretos: si un contenedor queda `unhealthy`, revisar
  `docs/secrets-healthcheck.md` antes de tocar el quadlet.
- Purga con `User=` no root: usar `podman unshare chown/rm` para los binds.

## Criterios de aceptación

- Los 6 stacks pasan los 5 puntos (o quedan documentados como bloqueados con causa concreta).
- `radicale` sin nombres globales `expulsabot`.
- Ningún stack del lote queda desplegado al cerrar la ronda.
- `docs/estado-verificacion-e2e.md` actualizado y plan archivado.

## Resultado (2026-11-11)

- Verificados E2E y purgados: atuin, beszel, radicale, wakapi, wikijs, zincsearch (6/6).
- Bugs latentes corregidos: 7 (atuin ×3, beszel ×2, radicale ×2, wikijs ×2 — ver `docs/<stack>.md`).
- Producción: sólo quedan los 4 stacks base + `headscale-headplane`; sin restos de la ronda.
- Cifras actualizadas: 127 = 65 verificados + 4 en producción + 2 bloqueados + 56 sin verificar.
