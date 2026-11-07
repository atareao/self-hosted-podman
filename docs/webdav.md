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
- Volumen(es): ninguno (volúmenes definidos directamente)
- Config no secreta: ninguno
- Secretos: ninguno

## Cómo funciona
El contenedor se une a la red `proxy.network` y expone el puerto 8080 a Traefik. Se monta el directorio de compartición en `/share` y el archivo `.htpasswd` para la autenticación. Traefik dirige las peticiones a `webdav.${FQDN}`.

## Variables / configuración
(ninguna)

## Cómo habilitar / desplegar
1. `cd .config/containers/available/webdav && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
