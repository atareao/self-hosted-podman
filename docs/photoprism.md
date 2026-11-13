# photoprism — servidor de fotos autoalojado

## Qué es
- app: photoprism
- Image: docker.io/photoprism/photoprism:latest
- nº contenedores: 1
- red: proxy.network
- dominio: subdominio photoprism.${FQDN} (root ${FQDN})
- puerto interno: 2342

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/photoprism/photoprism.container
- Volumen(es): %h/.config/photoprism/Pictures:/photoprism/originals:Z, %h/.config/photoprism/Storage:/photoprism/storage:Z, %h/.config/photoprism/Import:/photoprism/import:ro
- Config no secreta: `Environment=` en el propio quadlet (TZ, `PHOTOPRISM_SITE_URL`, `PHOTOPRISM_ADMIN_USER`)
- Secretos: photoprism_admin_password

## Cómo funciona
Conecta a la red proxy.network y monta binds locales bajo `~/.config/photoprism/` para originales, almacenamiento e importaciones (este último en solo lectura). El contenedor sirve en el puerto 2342 y Traefik enruta a https://photoprism.${FQDN}.

- **Healthcheck**: `curl -f -s -o /dev/null http://127.0.0.1:2342/` (60 s / 5 reintentos / timeout 15 s / `HealthStartPeriod=120s`).
- **Sin `PodmanArgs=--init`**: la imagen 26.x (Ubuntu 26.04) usa s6-overlay y exige ser PID 1.
- **Binds**: los tres directorios deben existir antes de desplegar; el proceso corre como root dentro del userns y escribe sin necesidad de `chown`.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| PHOTOPRISM_ADMIN_USER | Environment | admin | usuario administrador |
| PHOTOPRISM_ADMIN_PASSWORD | Secret (`type=env`) | `photoprism_admin_password` | contraseña del admin; sin ella no hay login usable |
| PHOTOPRISM_SITE_URL | Environment | https://photoprism.${FQDN}/ | URL pública (enlaces y redirecciones) |
| TZ | Environment | Europe/Madrid | zona horaria |

## Cómo habilitar / desplegar
1. Crear los binds: `mkdir -p ~/.config/photoprism/{Pictures,Storage,Import}`.
2. Secreto (NUNCA crypta store): `openssl rand -base64 32 | podman secret create photoprism_admin_password -`.
3. `cd .config/containers/available/photoprism && qctl install`
4. `systemctl --user daemon-reload`

## Verificación E2E (2026-11-13)

Verificado en producción (`new_atareao`, usuario `runner`) y después purgado:

1. Unit `photoprism` → `active`.
2. Contenedor `photoprism` → `Up (healthy)`.
3. Router `photoprism@docker` registrado en Traefik (servicio → `2342`).
4. Certificado válido con el resolver `letsencrypt-staging`.
5. `https://photoprism.${FQDN}/` → `307` → `200` (página de login).

Bugs latentes corregidos para llegar hasta aquí:

- El quadlet no tenía **ningún** `Environment` ni secreto: no había admin usable ni `SITE_URL`. Se añadieron el secreto `photoprism_admin_password` (`type=env,target=PHOTOPRISM_ADMIN_PASSWORD`), `PHOTOPRISM_ADMIN_USER=admin`, `PHOTOPRISM_SITE_URL` y `TZ`.
- `PodmanArgs=--init` rompía el arranque: la imagen ya trae **s6-overlay** y aborta con `s6-overlay-suexec: fatal: can only run as pid 1`. Se eliminó `--init` (misma familia de problema que las imágenes LinuxServer.io).
- `HealthCmd=photoprism status` fallaba **dentro** del contenedor (`cannot connect to 0.0.0.0:2342`) y lo dejaba en `(starting)/unhealthy`; se sustituyó por `curl` contra `127.0.0.1:2342`. Efecto colateral observado: con el contenedor atascado en `starting`, Traefik no registraba el router y servía el catch-all (404) aunque la app escuchaba.
- `Import` pasa a `:ro` y se añadió `HealthStartPeriod=120s` (el primer arranque indexa y tarda).

Purga: `qctl purge --secrets --images`; binds retirados a mano.

## Follow-ups
- Revisar el pin de imagen (`:latest` avanza sola con `AutoUpdate=registry`); fijar una versión concreta cuando se despliegue de forma estable.
