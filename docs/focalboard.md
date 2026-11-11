# focalboard — Focalboard es una herramienta de gestión de proyectos y tareas

## Qué es
App: focalboard y PostgreSQL
Imagen(es):
- focalboard: docker.io/mattermost/focalboard
- postgres: docker.io/library/postgres:latest
Nº contenedores: 2
Red(s): proxy.network, focalboard.network
Dominio: subdominio `focalboard.${FQDN}`
Puerto interno: 8000 (focalboard)

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/focalboard/focalboard.container
  - /data/self-hosted-podman/.config/containers/available/focalboard/focalboard-postgresql.container
- Volumen(es):
  - /data/self-hosted-podman/.config/containers/available/focalboard/focalboard-db.volume
  - /data/self-hosted-podman/.config/containers/available/focalboard/focalboard-data.volume
- Config no secreta:
- Secretos:

## Cómo funciona
Red proxy.network y focalboard.network. Volúmenes focalboard-data.volume (fichas) y focalboard-db.volume (BD). Socket del daemon (none). Healthcheck (none). Enrutado Traefik, User/UserNS/NoNewPrivileges: none.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| | | | |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store):
2. `cd .config/containers/available/focalboard && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)