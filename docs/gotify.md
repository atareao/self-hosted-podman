# gotify — gotify

## Qué es
- app: gotify
- imagen: docker.io/gotify/server:latest
- nº contenedores: 1
- red: proxy.network
- dominio: raíz ${FQDN}, subdominio gotify.${FQDN}
- puerto interno: 80

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/gotify/gotify.container
- Volumen(es): ninguno
- Config no secreta: ninguno
- Secretos: ninguno

## Cómo funciona
- red: proxy.network
- volúmenes: host path %h/.config/gotify/data dentro de la aplicación
- secretos: ninguno
- EnvironmentFile: ninguno
- socket del daemon: ninguno
- healthcheck: ninguno
- Traefik enrutado: router "gotify" sobre Host(`gotify.${FQDN}`) con entrada websecure
- User/UserNS/NoNewPrivileges: no se especifica, se ejecuta como root

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store): `printf '%s' '<valor>' | podman secret create <nombre> -`
2. `cd /data/self-hosted-podman/.config/containers/available/gotify && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-013, issue #7): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP OK) y **purgado ese mismo día** (units desenlazados,
volúmenes/binds e imágenes eliminados). Estado actual: **no desplegado**.

Usa un bind bajo `~/.config/<stack>/`; hay que crearlo (`mkdir -p`) antes de arrancar.