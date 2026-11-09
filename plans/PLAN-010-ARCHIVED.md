# PLAN-010 — Headplane (UI web de Headscale) integrada en el stack `headscale`

- Issue: #4
- Estado: completado
- Stack: `headscale`

## Objetivo

Dotar al stack `headscale` de una interfaz web (**Headplane**) para gestionar el tailnet desde el navegador, expuesta en el mismo dominio bajo `/admin` (`https://headscale.<FQDN>/admin`), con integración completa con Podman para poder editar los ajustes de red de Headscale desde la UI.

## Decisiones de diseño

1. **Mismo dominio, bajo `/admin`** (diseño canónico de Headplane): dos routers Traefik sobre `headscale.<FQDN>`:
   - `headscale` → `headscale:8080` (regla `Host(...)`, todo el resto).
   - `headplane` → `headplane:3000` (regla `Host(...) && PathPrefix(/admin)`, prioridad 100).
2. **HTTP/1.1 en ambos routers**: el `TLSOption headscale-http1@file` se aplica también al router de headplane para evitar ambigüedad de SNI (si no, Traefik podría negociar h2 en el handshake y romper TS2021).
3. **Componente del mismo stack**: unit `headscale-headplane.container` en `.config/containers/available/headscale/`.
4. **Integración completa con Podman**: se monta `%t/podman/podman.sock:/var/run/docker.sock:ro` y el `config.yaml` de headscale (rw) para editar DNS/rutas; el contenedor headscale lleva la label `me.tale.headplane.target=headscale`.
5. **Cookie secret como secreto de Podman** (`headplane_cookie_secret` → `HEADPLANE_SERVER__COOKIE_SECRET` + `HEADPLANE_LOAD_ENV_OVERRIDES=true`); 32 caracteres exactos.

## Ficheros

Nuevos:
- `.config/containers/available/headscale/headscale-headplane.container`
- `.config/containers/available/headscale/headscale-headplane-data.volume`
- `.config/headplane/config.yaml.jinja`
- `.config/headplane/.gitignore`
- `.config/headplane/headplane.env`
- `docs/headplane.md`

Modificados:
- `.config/containers/available/headscale/headscale.container` (NetworkAlias=headscale, label headplane.target, middleware CORS)
- `docs/headscale.md` (sección Headplane)

## Tareas

- [x] Crear el unit `headscale-headplane.container` (11 secciones canónicas).
- [x] Crear el volumen `headplane-data.volume`.
- [x] Crear la plantilla `config.yaml.jinja` (base_path /admin, base_url con FQDN, docker integration).
- [x] Crear `.config/headplane/.gitignore` y `headplane.env`.
- [x] Modificar `headscale.container`: `NetworkAlias=headscale`, label `me.tale.headplane.target=headscale`, middleware CORS.
- [x] Validar con `quadlet -user -dryrun` (rc=0) y `qctl check`.
- [x] Crear el secreto `headplane_cookie_secret` en prod (`podman secret create`).
- [x] `yadm pull` + `qctl install` + arrancar headplane.
- [x] Verificar `https://headscale.<FQDN>/admin` (200, cert válido, HTTP/1.1) y que TS2021 sigue OK.
- [x] Crear API key de headscale y documentar el login.
- [x] `docs/headplane.md` + sección en `docs/headscale.md`.
- [x] Archivar el plan.

## Verificación (criterios de aceptación)

- `quadlet -user -dryrun` rc=0.
- `https://headscale.<FQDN>/admin` → UI Headplane, cert Let's Encrypt válido.
- `https://headscale.<FQDN>/health` sigue devolviendo `{"status":"pass"}` y el handshake TS2021 sigue OK (HTTP/1.1).
- Router Traefik `headplane@docker` activo.
- Contenedor `healthy`.

## Riesgos / notas

- Reiniciar el contenedor headscale desde la UI usa la API Docker de Podman sobre un unit gestionado por systemd; puede provocar drift del estado del servicio. Documentado.
- `cookie_secret` debe tener exactamente 32 caracteres.

## Resultado

- Desplegado y verificado en `new_atareao` (usuario `runner`).
- `https://headscale.<FQDN>/admin/` → 302 → `/admin/login` → 200 («Headplane»); `/admin/healthz` → 200.
- `https://headscale.<FQDN>/health` → `{"status":"pass"}`; `POST /ts2021` alcanza la ruta Noise.
- API key de Headscale creada para el login del UI.
- Healthcheck desactivado (`HealthCmd=none`) por imagen distroless sin shell (exit 125).
- Regla Traefik sin espacios (`Host(...)&&PathPrefix(/admin)`) por el particionado de systemd.
