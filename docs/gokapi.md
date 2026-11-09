# gokapi — gokapi

## Qué es
- app: gokapi
- imagen: docker.io/f0rc3/gokapi:latest
- nº contenedores: 1
- red: proxy.network
- dominio: raíz ${FQDN}, subdominio gokapi.${FQDN}
- puerto interno: 8080

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/gokapi/gokapi.container
- Volumen(es):
  - /data/self-hosted-podman/.config/containers/available/gokapi/gokapi-config.volume
  - /data/self-hosted-podman/.config/containers/available/gokapi/gokapi-data.volume
- Config no secreta: /data/self-hosted-podman/.config/gokapi/gokapi.env
- Secretos: ninguno

## Cómo funciona
- red: proxy.network
- volúmenes: host paths %h/.config/gokapi/... dentro de la aplicación
- secretos: ninguno
- EnvironmentFile: %h/.config/gokapi/gokapi.env y .env.local (si existe)
- socket del daemon: ninguno
- healthcheck: ninguno
- Traefik enrutado: router "gokapi" sobre Host(`gokapi.${FQDN}`) con entrada websecure
- User/UserNS/NoNewPrivileges: no se especifica, se ejecuta como root

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| GOKAPI_PORT | EnvironmentFile | 8080 | |
| GOKAPI_EXTERNAL_URL | Environment= | https://gokapi.${FQDN} | |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store): `printf '%s' '<valor>' | podman secret create <nombre> -`
2. `cd /data/self-hosted-podman/.config/containers/available/gokapi && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-012, issue #6): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP OK) y **purgado ese mismo día** (units desenlazados,
volúmenes e imágenes eliminados). Estado actual: **no desplegado**.

Corrección aplicada: el `loadbalancer.server.port` de Traefik pasa de 80 a **8080** (la imagen `f0rc3/gokapi` v2 escucha en 8080).