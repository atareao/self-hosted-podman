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