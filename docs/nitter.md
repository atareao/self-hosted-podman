# nitter — Servicio de Nitter (interfaz alternativa a Twitter)

## Qué es
- App: nitter
  Image: docker.io/zedeus/nitter:latest
  Contenedores: 1
  Red principal: proxy.network
  Dominio: nitter.${FQDN}
  Puerto interno: 8080

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/nitter/nitter.container
- Volumen(es):
  - Bind: /home/lorenzo/.config/nitter/nitter.conf -> /src/nitter.conf (nitter)
- Config no secreta: none
- Secretos: none

## Cómo funciona
- Proxy.network: sí (expuesto a traefik)
- Volúmenes: bind mount de configuración
- Secretos: ninguno
- EnvironmentFile: ninguno
- Socket del daemon: ninguno
- Healthcheck: sí (wget -nv --tries=1 --spider http://127.0.0.1:8080/Jack/status/20)
- Enrutado Traefik: etiquetas cargadas:\n  - traefik.http.services.nitter.loadbalancer.server.port=8080\n  - traefik.http.routers.nitter.rule=Host(`nitter.${FQDN}`)\n  - traefik.http.routers.nitter.entrypoints=websecure\n  - traefik.http.routers.nitter.tls.certresolver=letsencrypt\n  - traefik.http.routers.nitter.middlewares=seguridadHeaders@file,compresionHeaders@file
- User/UserNS/NoNewPrivileges: ninguno

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|

## Cómo habilitar / desplegar
1. cd .config/containers/available/nitter && qctl install
2. systemctl --user daemon-reload

## Follow-ups
- (ninguno)
