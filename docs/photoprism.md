# photoprism — 

## Qué es
- app: photoprism
- Image: docker.io/photoprism/photoprism:latest
- nº contenedores: 1
- red: proxy.network
- dominio: subdominio photoprism.${FQDN} (root ${FQDN})
- puerto interno: 2342

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/photoprism/photoprism.container
- Volumen(es): %h/.config/photoprism/Pictures:/photoprism/originals:Z, %h/.config/photoprism/Storage:/photoprism/storage:Z, %h/.config/photoprism/Import:/photoprism/import:Z
- Config no secreta: none
- Secretos: none

## Cómo funciona
Conecta a la red proxy.network y monta volúmenes locales para fotos, almacenamiento e importaciones. No requiere secretos ni sockets del daemon. Traefik enruta a https://photoprism.${FQDN} con puerto 2342.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| (ninguna) | | | |

## Cómo habilitar / desplegar
1. `cd .config/containers/available/photoprism && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)