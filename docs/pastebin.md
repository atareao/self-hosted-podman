# pastebin — 

## Qué es
- app: pastebin
- Image: docker.io/atareao/pastebin:v1.0
- nº contenedores: 1
- red: proxy.network
- dominio: subdominio pastebin.${FQDN} (root ${FQDN})
- puerto interno: 8081

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/pastebin/pastebin.container
- Volumen(es): %h/.config/pastebin/db:/rs/db:Z
- Config no secreta: none
- Secretos: none

## Cómo funciona
Usa la red proxy.network. Almacena los datos en %h/.config/pastebin/db. No requiere secretos. No tiene socket del daemon ni healthcheck. Traefik enruta a https://pastebin.${FQDN} con puerto 8081.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| (ninguna) | | | |

## Cómo habilitar / desplegar
1. `cd .config/containers/available/pastebin && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)