# jellyfin — Servidor multimedia

## Qué es
Servidor de streaming multimedia Jellyfin.
- Imagen principal: docker.io/jellyfin/jellyfin
- Número de contenedores: 1
- Red(es) usadas: proxy.network
- Dominio(s): jellyfin.${FQDN}
- Puerto interno: 8096

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/jellyfin/jellyfin.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/jellyfin/jellyfin-config.volume, /data/self-hosted-podman/.config/containers/available/jellyfin/jellyfin-cache.volume, /data/self-hosted-podman/.config/containers/available/jellyfin/jellyfin-media.volume
- Config no secreta: N/A
- Secretos: N/A

## Cómo funciona
Conecta a proxy.network, volúmenes jellyfin-config, jellyfin-cache, jellyfin-media, healthcheck none, enrutamiento Traefik con TLS, ejecuta como usuario 1000:1000.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| (none) | | | |

## Cómo habilitar / desplegar
1. Secretos (si existen; NUNCA crypta store): Ninguno
2. `cd .config/containers/available/jellyfin && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-017, issue #12): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP 200) y **purgado ese mismo día**. Estado actual: **no desplegado**.