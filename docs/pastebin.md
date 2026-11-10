# pastebin — 

## Qué es
- app: pastebin
- Image: docker.io/mkaczanowski/pastebin:latest
- La imagen docker.io/atareao/pastebin:v1.0 ya no está disponible en Docker Hub; mkaczanowski/pastebin es el upstream del binario.
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
Usa la red proxy.network. Almacena los datos en %h/.config/pastebin/db. No requiere secretos. No tiene socket del daemon ni healthcheck. Traefik enruta a https://pastebin.${FQDN} con puerto 8081. El contenedor arranca con opciones `--address 0.0.0.0 --port 8081 --db=/rs/db/pastebin.db` y los datos persisten en `%h/.config/pastebin/db`.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| (ninguna) | | | |

## Cómo habilitar / desplegar
1. `cd .config/containers/available/pastebin && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
- La imagen upstream no se actualiza desde 2021; vigilar actualizaciones.