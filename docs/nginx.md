# nginx — servidor web de ejemplo tras Traefik

## Qué es

`nginx` usa la imagen `docker.io/library/nginx:alpine`. Es un stack de un único contenedor tras Traefik, en la red `proxy`. Se sirve en el subdominio `web.${FQDN}` (label `traefik.http.routers.nginx-web.rule=Host(`web.${FQDN}`)`) y escucha en el puerto interno `80`.

## Ficheros

- Quadlet: `.config/containers/available/nginx/nginx.container`
- Volúmenes: (ninguno)
- Config no secreta: (ninguna)
- Secretos: (ninguno)

## Cómo funciona

- **Red**: se une a `proxy.network` (red de borde de Traefik). No define `NetworkAlias`.
- **Persistencia**: sin volúmenes declarados; el contenido servido es el por defecto de la imagen.
- **Configuración**: no usa `EnvironmentFile` ni secretos; el quadlet no define variables de entorno.
- **Healthcheck**: no define `HealthCmd`.
- **Enrutado**: router `nginx-web` con `Host(`web.${FQDN}`)`, `entrypoints=websecure`, `tls.certresolver=letsencrypt` y los middlewares del repo (`seguridadHeaders@file,compresionHeaders@file`); el servicio `nginx-web` apunta al puerto `80`.
- **Hardening/Resources**: sin `User`, `UserNS` ni `NoNewPrivileges`; sin límites de recursos.
- **Servicio**: `Restart=always`.

## Variables / configuración

No hay variables de entorno ni `.env` de stack.

## Cómo habilitar / desplegar

1. No requiere secretos.
2. `cd .config/containers/available/nginx && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups

- (ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-015, issue #10): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP 200) y **purgado ese mismo día** (unit desenlazado,
volumenes/binds e imagen eliminados). Estado actual: **no desplegado**.
