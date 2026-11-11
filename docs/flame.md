# flame — Flame es un monitor de logs en tiempo real

## Qué es
App: flame
Imagen: docker.io/pawelmalak/flame
Nº contenedores: 1
Red: proxy.network
Dominio: subdominio `flame.${FQDN}`
Puerto interno: 5005

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/flame/flame.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/flame/flame-data.volume
- Config no secreta:
- Secretos:
  - flame_password

## Cómo funciona
Red proxy.network, volumen flame-data.volume, bind mount podman socket, socket del daemon (none), healthcheck (none), enrutado Traefik, User/UserNS/NoNewPrivileges: none.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| | | | |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store):
  - `printf '%s' '\u003cvalor\u003e' | podman secret create flame_password -`
2. `cd .config/containers/available/flame && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-018, issue #13): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP 200) y **purgado ese mismo día**. Estado actual: **no desplegado**.