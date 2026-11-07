# PLAN — Stack `errserve` (quadlet)

## Objetivo

Añadir el stack `errserve` (páginas de error *catch-all* tras Traefik) como quadlets Podman
rootless, siguiendo el **Canonical quadlet skeleton** y las convenciones del repo.

## Análisis compose → quadlet

| Elemento compose | Destino |
|---|---|
| single-service, `init: true` | `PodmanArgs=--init` |
| `ghcr.io/atareao/errserve:latest` | `Image=` + `AutoUpdate=registry` (tag flotante) |
| `environment:` (PORT, LOG_LEVEL, LOG_FORMAT, CONTENT_DIR, DEFAULT_ERROR_PAGE, THEME) — todo no secreto | `.config/errserve/errserve.env` + `EnvironmentFile=` (`.env` + `.env.local`) |
| red `proxy` externa | `proxy.network` + `NetworkAlias=errserve` (lo necesita el middleware `errors`) |
| `volumes:` / `secrets:` | no hay |
| labels Traefik (catch-all + middlewares `errpages`/`errfixed`) | se copian **tal cual**, adaptadas a `Label=` |
| fichero `.container` vs `.jinja` | **plano** (no usa `{{ env.* }}` ni `${FQDN}`) |

## Decisiones

- Esta stack **NO** sigue el patrón "single-router seguro" (`Host(...)` + `seguridadHeaders`/`compresionHeaders`):
  es, por diseño, un *catch-all* de páginas de error (`HostRegexp(.+)` prioridad 1) más dos middlewares reutilizables.
- `Hardening`, `Resources` y `Healthcheck` vacías (igual que el compose; evita romper en runtime).
- Sin secretos Podman, sin volúmenes, sin red interna, sin plantilla `.jinja`.

## Ficheros a crear

1. `.config/errserve/errserve.env`
2. `.config/containers/available/errserve/errserve.container`

## Tareas

1. [x] Crear `.config/errserve/errserve.env`.
2. [x] Crear `.config/containers/available/errserve/errserve.container`.
3. [x] Validar con `/usr/lib/podman/quadlet -user -dryrun` (0 errores) y `qcheck` (0 colisiones duras).
4. [x] Commit gitmoji conventional (`✨ feat(errserve): ...`).

## Follow-ups (documentar, no implementar)

- Volumen de `CONTENT_DIR` si se quieren páginas de error personalizadas.
- El middleware `errfixed` queda definido para que otros stacks lo referencien explícitamente.