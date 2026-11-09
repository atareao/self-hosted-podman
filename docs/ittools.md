# ittools — Herramientas de IT

## Qué es
Herramientas web para administración de sistemas.
- Imagen principal: docker.io/corentinth/it-tools
- Número de contenedores: 1
- Red(es) usadas: proxy.network
- Dominio(s): ittools.${FQDN}
- Puerto interno: 80

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/ittools/ittools.container
- Volumen(es): N/A
- Config no secreta: N/A
- Secretos: N/A

## Cómo funciona
Conecta a la red proxy.network, no requiere volúmenes, utiliza secretos none, env none, healthcheck none, enrutamiento Traefik con TLS.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| (none) | | | |

## Cómo habilitar / desplegar
1. Secretos (si existen; NUNCA crypta store): Ninguno
2. `cd .config/containers/available/ittools && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-012, issue #6): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP OK) y **purgado ese mismo día** (units desenlazados,
volúmenes e imágenes eliminados). Estado actual: **no desplegado**.