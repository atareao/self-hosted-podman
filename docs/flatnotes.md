# flatnotes — Flatnotes es un gestor de notas ligera

## Qué es
App: flatnotes
Imagen: docker.io/dullage/flatnotes:latest
Nº contenedores: 1
Red: proxy.network
Dominio: subdominio `dnote.${FQDN}`
Puerto interno: 3000

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/flatnotes/flatnotes.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/flatnotes/flatnotes-data.volume
- Config no secreta:
- Secretos:
  - flatnotes_password
  - flatnotes_secret_key

## Cómo funciona
Red proxy.network, volumen flatnotes-data.volume, socket del daemon (none), healthcheck (none), enrutado Traefik, User/UserNS/NoNewPrivileges: none.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| FLATNOTES_AUTH_TYPE | flatnotes.container | password | Tipo de autenticación |
| FLATNOTES_USERNAME | flatnotes.container | user | Usuario |
| | | | |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store):
  - `printf '%s' '\u003cvalor\u003e' | podman secret create flatnotes_password -`
  - `printf '%s' '\u003cvalor\u003e' | podman secret create flatnotes_secret_key -`
2. `cd .config/containers/available/flatnotes && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-018, issue #13): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP 200) y **purgado ese mismo día**. Estado actual: **no desplegado**.

**Bugs corregidos**:
- El router apuntaba a `Host(`dnote.${FQDN}`)` (copia-pega), colisionando con el stack `dnote`. Corregido a `flatnotes.${FQDN}`.
- El service de Traefik usaba `port=3000`, pero flatnotes (uvicorn) escucha en **8080** (`FLATNOTES_PORT=8080`) → daba 502. Corregido a 8080.