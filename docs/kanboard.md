# kanboard — Tablero Kanban

## Qué es
Aplicación Kan Board para gestión de proyectos.
- Imagen principal: docker.io/kanboard/kanboard:latest
- Número de contenedores: 1
- Red(es) usadas: proxy.network
- Dominio(s): kanboard.${FQDN}
- Puerto interno: 80

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/kanboard/kanboard.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/kanboard/kanboard-data.volume, /data/self-hosted-podman/.config/containers/available/kanboard/kanboard-plugins.volume
- Config no secreta: N/A
- Secretos: N/A

## Cómo funciona
Conecta a proxy.network, monta volúmenes kanboard-data y kanboard-plugins, healthcheck none, enrutamiento Traefik con TLS.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| (none) | | | |

## Cómo habilitar / desplegar
1. Secretos (si existen; NUNCA crypta store): Ninguno
2. `cd .config/containers/available/kanboard && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)