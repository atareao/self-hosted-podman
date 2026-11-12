# webdav — Servidor de WebDAV con autenticación básica

## Qué es
Aplicación: WebDAV
Imagen: docker.io/atareao/webdav:v2.0
Número de contenedores: 1
Red: proxy.network
Dominio: `webdav.${FQDN}` (subdominio webdav)
Puerto interno: 8080

## Ficheros
- Quadlet(s): `/data/self-hosted-podman/.config/containers/available/webdav/webdav.container`
- Volumen(es): 2 binds (`%h/.config/webdav/share` → `/share` y `%h/.config/webdav/htpasswd` → `/opt/nginx/conf/.htpasswd`)
- Config no secreta: ninguno
- Secretos: `htpasswd` es credencial (credenciales de autenticación básica, no un secreto de Podman)

## Cómo funciona
El contenedor se une a la red `proxy.network` y expone el puerto 8080 a Traefik. Se monta el directorio de compartición en `/share` y el archivo `htpasswd` en `/opt/nginx/conf/.htpasswd` para la autenticación básica. Traefik dirige las peticiones a `webdav.${FQDN}`.

## Variables / configuración
(ninguna)

## Cómo habilitar / desplegar
1. Crear en prod los bind mounts **antes** de arrancar:
   - `%h/.config/webdav/share/` (directorio de compartición)
   - `%h/.config/webdav/htpasswd` (fichero de credenciales, p. ej. generado con `htpasswd -Bc`)
2. `cd .config/containers/available/webdav && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- `%h/.config/webdav/htpasswd` y `%h/.config/webdav/share/` deben existir en prod antes de arrancar el contenedor.

## Verificación E2E (PLAN-033 / #28)

Desplegado y verificado el **2026-11-12**: unit `active`, contenedor up, **cert Let's Encrypt real** y
`401` vía Traefik en `webdav.servidorlinux.es`. Bind `~/.config/webdav/htpasswd` (user `admin`,
bcrypt) + `~/.config/webdav/share/`.

Follow-up: sin `HealthCmd`.
