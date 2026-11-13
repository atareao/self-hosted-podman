# registry — Registro de contenedores Docker privado

## Qué es
registry (con UI `docker.io/joxit/docker-registry-ui:main`), docker.io/library/registry (v3.1.2), 2 contenedores, red: registry.network + proxy.network (UI), dominio: registry.${FQDN}, puerto interno: 80 (UI)

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/registry/registry.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/registry/registry-ui.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/registry/registry-data.volume
- Red: /data/self-hosted-podman/.config/containers/available/registry/registry.network
- Config no secreta: /data/self-hosted-podman/.config/registry/config.yml.jinja
- Secretos: ninguno

## Cómo funciona
- Red: registry.network (ambos contenedores) y proxy.network (solo `registry-ui`)
- Volúmenes/binds: registry-data.volume montado en /var/lib/registry; bind `~/.config/registry/config.yml` → `/etc/distribution/config.yml`; bind `~/.config/registry/htpasswd` → `/auth/htpasswd` (ro)
- Secretos: ninguno
- Socket del daemon: N/A
- Config: `.config/registry/config.yml.jinja` lo renderiza `unjinja` (hook `post_pull`) a `config.yml` usando `{{ env.FQDN }}` para el CORS; `.config/registry/.gitignore` excluye `config.yml` y `htpasswd`
- Autenticación: basic-auth (`htpasswd` bcrypt) para la API `/v2/`
- Healthcheck: N/A
- Enrutado Traefik: router/servicio `registryui`, Host(`registry.${FQDN}`) → puerto 80; la UI proxya `/v2/` al registry interno (`http://registry:5000`), por eso `registry.container` no tiene router propio
- `[Service]`: N/A
- User/UserNS/NoNewPrivileges: N/A

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|-----|-------|-------|-------------|
| REGISTRY_STORAGE_DELETE_ENABLED | registry.container | true | permite borrar imágenes vía API |
| NGINX_PROXY_PASS_URL | registry-ui.container | http://registry:5000 | upstream de la UI hacia el registry (**Environment**, antes era secreto) |
| SINGLE_REGISTRY | registry-ui.container | true | la UI asume un único registry |
| REGISTRY_TITLE | registry-ui.container | Atareao Docker Registry | título mostrado en la UI |
| DELETE_IMAGES | registry-ui.container | true | habilita el borrado desde la UI |
| SHOW_CONTENT_DIGEST | registry-ui.container | true | muestra el digest de las imágenes |
| SHOW_CATALOG_NB_TAGS | registry-ui.container | true | muestra el número de tags por imagen |
| CATALOG_MIN_BRANCHES | registry-ui.container | 1 | mínimo de ramas del catálogo |
| CATALOG_MAX_BRANCHES | registry-ui.container | 1 | máximo de ramas del catálogo |
| TAGLIST_PAGE_SIZE | registry-ui.container | 100 | tamaño de página de tags |
| REGISTRY_SECURED | registry-ui.container | false | la UI no añade credenciales por sí misma |
| CATALOG_ELEMENTS_LIMIT | registry-ui.container | 1000 | límite de elementos del catálogo |

## Cómo habilitar / desplegar
1. Generar las credenciales:
   `htpasswd -Bbn <usuario> '<password>' > ~/.config/registry/htpasswd`
   (o `podman run --rm --entrypoint htpasswd docker.io/library/httpd:2 -Bbn <usuario> '<password>' > ~/.config/registry/htpasswd`)
2. Renderizar el config: `unjinja` (o `yadm pull`, que lo hace en el hook).
3. `cd .config/containers/available/registry && qctl install`
4. `systemctl --user daemon-reload`

## Verificación E2E (2026-11-13)

Verificado en producción (`new_atareao`, usuario `runner`) y después purgado:

1. Units `registry` y `registry-ui` → `active`.
2. Los 2 contenedores → `Up`.
3. Router `registryui@docker` registrado en Traefik.
4. Certificado Let's Encrypt válido (`CN=registry.<fqdn>`).
5. UI `https://registry.${FQDN}/` → `200`; API `/v2/_catalog` → `401` sin credenciales y `200` con ellas; login + `podman push` + catálogo OK.

Bugs corregidos para llegar hasta aquí:

- **Crítico**: `registry:latest` es la **3.1.2**, que lee su config en **`/etc/distribution/config.yml`**; el bind a la ruta antigua `/etc/docker/registry/config.yml` se **ignoraba**, así que arrancaba con la config de fábrica (sin `auth`): la API quedaba **abierta** (200 sin auth). Corregido el bind.
- El host de Traefik era el placeholder `tu.${FQDN}` → corregido a `registry.${FQDN}`.
- `NGINX_PROXY_PASS_URL` estaba como secreto (no lo es) → movido a `Environment`.

Hallazgo operativo: recrear solo el contenedor `registry` deja `registry-ui` devolviendo **502** en `/v2/` (su nginx cachea el upstream); hay que reiniciar `registry-ui`. Y tras recrear contenedores puede hacer falta `systemctl --user restart traefik`.

Purga: `qctl purge --secrets --images`.

## Follow-ups
- El `htpasswd` no se versiona: se genera en el deploy.
- `config.yml` se renderiza con `unjinja` desde `config.yml.jinja`.
