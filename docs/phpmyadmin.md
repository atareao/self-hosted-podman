# phpmyadmin — 

## Qué es
- app: phpmyadmin
- Image: docker.io/library/phpmyadmin
- nº contenedores: 1
- red: proxy.network, phpmyadmin.network
- dominio: subdominio myadmin.${FQDN} (root ${FQDN})
- puerto interno: 80

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/phpmyadmin/phpmyadmin.container
- Volumen(es): none
- Config no secreta: none
- Secretos: none

## Cómo funciona
Usa la red proxy.network y phpmyadmin.network. No necesita secretos ni sockets del daemon. Traefik enruta a https://myadmin.${FQDN} con puerto 80.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| PMA_ARBITRARY | container | 1 | Permite acceder a tablas arbitrarias. |

## Cómo habilitar / desplegar
1. `cd .config/containers/available/phpmyadmin && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)