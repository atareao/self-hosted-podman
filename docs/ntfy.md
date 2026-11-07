# ntfy — Servicio de notificaciones push

## Qué es
- App: ntfy
  Image: docker.io/atareao/ntfy:v1.0
  Contenedores: 1
  Red principal: proxy.network
  Dominio: ntfy.${FQDN}
  Puerto interno: 80

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/ntfy/ntfy.container
- Volumen(es):
  - Bind: /home/lorenzo/.config/ntfy/etc → /etc/ntfy (ntfy)
- Config no secreta: none
- Secretos: none

## Cómo funciona
- Proxy.network: sí (expuesto a traefik)
- Volúmenes: bind mount de configuración
- Secretos: ninguno
- EnvironmentFile: ninguno
- Socket del daemon: ninguno
- Healthcheck: ninguno
- Enrutado Traefik: etiquetas cargadas:
  - traefik.http.services.ntfy.loadbalancer.server.port=80
  - traefik.http.routers.ntfy.rule=Host(`ntfy.${FQDN}`)
  - traefik.http.routers.ntfy.entrypoints=websecure
  - traefik.http.routers.ntfy.tls.certresolver=letsencrypt
  - traefik.http.routers.ntfy.middlewares=seguridadHeaders@file,compresionHeaders@file
- User/UserNS/NoNewPrivileges: ninguno

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|

## Cómo habilitar / desplegar
1. cd .config/containers/available/ntfy && qctl install
2. systemctl --user daemon-reload

## Follow-ups
- (ninguno)
