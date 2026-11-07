# ferrishare — Ferrishare es un servicio de compartición de archivos interno

## Qué es
App: ferrishare
Imagen: ghcr.io/tobiasmarschner/ferrishare
Nº contenedores: 1
Red: proxy.network
Dominio: subdominio `ferrishare.${FQDN}`
Puerto interno: 3000

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/ferrishare/ferrishare.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/ferrishare/ferrishare-data.volume
- Config no secreta:
- Secretos:

## Cómo funciona
Red proxy.network, volumen ferrishare-data.volume, socket del daemon (none), healthcheck (none), enrutado Traefik, User/UserNS/NoNewPrivileges (none).

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| | | | |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store):
2. `cd .config/containers/available/ferrishare && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)