# caddy — un servidor proxy y CDN ligero, usa la imagen oficial caddy-docker-proxy

## Qué es
*Imagen*: docker.io/lucaslorentz/caddy-docker-proxy:latest
*nº contenedores*: 1
*Red*: proxy.network
*Dominio*: N/A
*Puerto interno*: 80, 443

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/caddy/caddy.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/caddy/caddy-caddy_data.volume
- Config no secreta: N/A
- Secretos: N/A

## Cómo funciona
Red: proxy.network
Volúmenes: caddy-caddy_data.volume mounted at /data
Socket del daemon: /var/run/docker.sock (via podman.sock bind)
Healthcheck: N/A
Enrutado Traefik: N/A
User/UserNS/NoNewPrivileges: N/A

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| CADDY_INGRESS_NETWORKS | Environment | proxy | Define que Caddy escuchará en la red proxy.

## Cómo habilitar / desplegar
1. `cd .config/containers/available/caddy && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)