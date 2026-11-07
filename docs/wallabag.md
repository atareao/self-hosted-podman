# wallabag — Servicio de lectura web para guardar artículos

## Qué es
Aplicación: Wallabag
Imagen: docker.io/wallabag/wallabag
Número de contenedores: 1
Red: proxy.network
Dominio: `wallabag.${FQDN}` (subdominio wallabag)
Puerto interno: 80

## Ficheros
- Quadlet(s): `/data/self-hosted-podman/.config/containers/available/wallabag/wallabag.container`
- Volumen(es): ninguno (volúmenes se definen directamente en la unidad)
- Config no secreta: ninguno
- Secretos: ninguno

## Cómo funciona
El contenedor se une a la red `proxy.network` y expone el puerto 80 a Traefik a través de `traefik.http.services.wallabag.loadbalancer.server.port`. Se configuran las variables de entorno `SYMFONY__ENV__DOMAIN_NAME` y `SYMFONY__ENV__SERVER_NAME` para definir el dominio interno y el nombre del servidor. Traefik dirige las peticiones a `wallabag.${FQDN}`.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| SYMFONY__ENV__DOMAIN_NAME | `Environment=` | "https://wallabag.${FQDN}" | Dominio externo |
| SYMFONY__ENV__SERVER_NAME | `Environment=` | "el nombre que quieras" | Nombre del servidor |

## Cómo habilitar / desplegar
1. `cd .config/containers/available/wallabag && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
