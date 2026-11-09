# navidrome — Reproductor de música

## Qué es
- Imagen: docker.io/deluan/navidrome:latest
- Nº contenedores: 1
- Red: proxy.network
- Dominio: Host(`navidrome.${FQDN}`)
- Puerto interno: 4533

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/navidrome/navidrome.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/navidrome/navidrome.container
- Config no secreta: NINGUNO
- Secretos: NINGUNO

## Cómo funciona
- Red: proxy.network
- Volúmenes: /config/navidrome/music and /config/navidrome/data (mapeados a /music y /data)
- Secretos: ninguno
- EnvironmentFile: ninguno
- Socket del daemon: no
- Healthcheck: ninguno
- Enrutado Traefik: router *navidrome*
- User: 1000:1000 (indicado en el quadlet)
- NoNewPrivileges: habilitado

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| (ninguno) | | | |

## Cómo habilitar / desplegar
1. `cd .config/containers/available/navidrome && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)

## Estado de despliegue

Desplegado y verificado en producción (`new_atareao`) el 2026-11-09 (PLAN-011, issue #5).
URL: https://navidrome.servidorlinux.es — cert LE válido, router Traefik activo.
Los binds `~/.config/navidrome/{data,music}` deben chownearse a uid 1000 (`podman unshare chown -R 1000:1000`).