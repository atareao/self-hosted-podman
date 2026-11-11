# picoshare — 

## Qué es
- app: picoshare
- Image: docker.io/mtlynch/picoshare
- nº contenedores: 1
- red: proxy.network
- dominio: subdominio picoshare.${FQDN} (root ${FQDN})
- puerto interno: 4001

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/picoshare/picoshare.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/picoshare/picoshare-data.volume
- Config no secreta: none
- Secretos: picoshare_ps_shared_secret

## Cómo funciona
Conecta a la red proxy.network. Persiste datos en picoshare-data.volume. Inyecta PS_SHARED_SECRET mediante secret. No tiene socket del daemon ni healthcheck. Traefik enruta a https://picoshare.${FQDN} con puerto 4001.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| PORT | container | 4001 | Puerto interno del servicio. |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store): `printf '%s' '<valor>' | podman secret create picoshare_ps_shared_secret -`
2. `cd .config/containers/available/picoshare && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-018, issue #13): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP 200) y **purgado ese mismo día**. Estado actual: **no desplegado**.