# notemark — Servicio de notas en Markdown

## Qué es
- App: notemark
  Image: ghcr.io/enchant97/note-mark-aio
  Contenedores: 1
  Red principal: proxy.network
  Dominio: notemark.${FQDN}
  Puerto interno: 8080

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/notemark/notemark.container
- Volumen(es):
  - Volume: notemark-data.volume → /data (notemark)
- Config no secreta: none
- Secretos: notemark_jwt_secret

## Cómo funciona
- Proxy.network: sí (expuesto a traefik)
- Volúmenes: un volumen persistente
- Secretos: JWT secret inyectado via Secret=notemark_jwt_secret
- EnvironmentFile: ninguno
- Socket del daemon: ninguno
- Healthcheck: ninguno
- Enrutado Traefik: etiquetas cargadas:
  - traefik.http.services.notemark.loadbalancer.server.port=8080
  - traefik.http.routers.notemark.rule=Host(`notemark.${FQDN}`)
  - traefik.http.routers.notemark.entrypoints=websecure
  - traefik.http.routers.notemark.tls.certresolver=letsencrypt
  - traefik.http.routers.notemark.middlewares=seguridadHeaders@file,compresionHeaders@file
- User/UserNS/NoNewPrivileges: none

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|

## Cómo habilitar / desplegar
1. cd .config/containers/available/notemark && qctl install
2. systemctl --user daemon-reload

## Follow-ups
- (ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-018, issue #13): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP 200) y **purgado ese mismo día**. Estado actual: **no desplegado**.

**Nota**: el secreto `notemark_jwt_secret` (`JWT_SECRET`) debe ser **largo** (validación `gte`): con 32
caracteres la app aborta con `Key: 'AppConfig.JWTSecret' Error:Field validation for 'JWTSecret' failed on the 'gte' tag`.
Usar ≥64 caracteres (p. ej. `openssl rand -base64 48`).
