# unbound — Resolver DNS recursivo local

## Qué es

Unbound: resolver DNS recursivo, validante y cacheable (imagen `docker.io/mvance/unbound:latest`). Un único contenedor (`unbound`). No está detrás de Traefik: no publica dominio ni usa `proxy.network`; en su lugar publica los puertos directamente con `PublishPort`. Puerto interno/publicado: `53/tcp` y `53/udp`.

## Ficheros

- Quadlet(s): `.config/containers/available/unbound/unbound.container`
- Volumen(es): — (no usa volúmenes nombrados; usa bind mounts de config)
- Config no secreta: — (no existe `.env` de stack; la config son los bind mounts `unbound.conf` y `conf/`)
- Secretos: — (ninguno)

## Cómo funciona

Contenedor sin red personalizada (no se une a `proxy.network` ni a ninguna red de stack) y sin labels Traefik: se expone directamente al host con `PublishPort=53:53/tcp` y `PublishPort=53:53/udp`, de modo que actúa como resolver DNS del host/red local. La configuración llega por bind mounts (con sufijo `:Z` para SELinux): el fichero `%h/.config/unbound/unbound.conf` como configuración principal (`/opt/unbound/etc/unbound/unbound.conf`) y el directorio `%h/.config/unbound/conf` como drop-in dir (`/opt/unbound/etc/unbound/unbound.conf.d/`). Arranca con `PodmanArgs=--init` y `Restart=always`. No define healthcheck, hardening, secretos ni variables de entorno (todo lo no secreto vive en los ficheros montados).

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| — | — | — | No define `Environment=` ni variables de `.env`; la configuración está en los ficheros montados |

## Cómo habilitar / desplegar

1. `cd .config/containers/available/unbound && qctl install`
2. `systemctl --user daemon-reload`

(No requiere secretos.)

## Follow-ups

- Al publicar el puerto `53` en el host, verificar que no colisiona con `systemd-resolved` u otro resolver.
- No define healthcheck; podría añadirse una consulta de prueba (`dig`/`unbound-host`).
- No aplica hardening (`ReadOnly`, `NoNewPrivileges`, `User`/`Group`); evaluar añadirlo.
