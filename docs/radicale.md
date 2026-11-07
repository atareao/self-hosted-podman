# radicale — Servidor CalDAV/CardDAV

## Qué es
- **App**: radicale
- **Imagen**: docker.io/atareao/radicale:v1.0
- **Nº contenedores**: 1 (radicale)
- **Red**: proxy.network
- **Dominio**: radicale.${FQDN} (subdominio "radicale")
- **Puerto interno**: 5232 (traefik http.services expulsabot loadbalancer.port)

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/radicale/radicale.container
- Volumen(es): ninguno
- Config no secreta: ninguno
- Secretos: ninguno

## Cómo funciona
- **Red**: proxy.network
- **Volúmenes**: %h/.config/radicale/.htpasswd-users -> /app/.htpasswd-users; %h/.config/radicale/data -> /app/data
- **Secretos**: ninguno
- **Healthcheck**: ninguno
- **Routing Traefik**: Host(`radicale.${FQDN}`), puerto 5232 (servicio expulsabot)
- **User/UserNS/NoNewPrivileges**: ninguno

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| (ninguna) | | | |

## Cómo habilitar / desplegar
1. `cd .config/containers/available/radicale && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
- El servicio Traefik expone el contenedor con el nombre "expulsabot" pero la app es radicale.
- (ninguno)