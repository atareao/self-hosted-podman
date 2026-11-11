# unbound — Resolver DNS recursivo local

## Qué es

Unbound: resolver DNS recursivo, validante y cacheable (imagen `docker.io/mvance/unbound:latest`). Un único contenedor (`unbound`). No está detrás de Traefik: no publica dominio ni usa `proxy.network`; en su lugar publica los puertos directamente con `PublishPort`. Puerto interno `53/tcp` y `53/udp`; **publicado en el host en `5353`** (Podman rootless no puede enlazar puertos < 80).

## Ficheros

- Quadlet(s): `.config/containers/available/unbound/unbound.container`
- Volumen(es): — (no usa volúmenes nombrados; usa bind mount de config)
- Config no secreta: `.config/unbound/conf/forward-records.conf` (fragmento versionado)
- Secretos: — (ninguno); no hay `.env` de stack

## Cómo funciona

Contenedor sin red personalizada (no se une a `proxy.network` ni a ninguna red de stack) y sin labels Traefik: se expone directamente al host con `PublishPort=5353:53/tcp` y `PublishPort=5353:53/udp`, de modo que actúa como resolver DNS del host/red local en el puerto `5353` (el `53` interno no se puede publicar en rootless). Arranca con `PodmanArgs=--init` y `Restart=always`.

**Configuración (importante).** La imagen NO lee `unbound.conf.d/`: su script de arranque (`/unbound.sh`) **genera** `/opt/unbound/etc/unbound/unbound.conf` si no existe y solo incluye `a-records.conf`, `srv-records.conf` y `forward-records.conf`. Por eso el repo monta **solo** `.config/unbound/conf/forward-records.conf` sobre `/opt/unbound/etc/unbound/forward-records.conf` (con `:ro,Z`): es el punto de extensión documentado por la imagen y **no** sustituye su `unbound.conf` (que mantiene chroot, `access-control` para LAN, DNSSEC, etc.). Como ese fichero deja la `forward-zone` comentada, el contenedor **resuelve por recursión** y no reenvía a Cloudflare (comportamiento por defecto de la imagen). No define healthcheck (usa el de la imagen, `drill @127.0.0.1`), hardening, secretos ni variables de entorno.

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| — | — | — | No define `Environment=` ni variables de `.env`; la configuración está en `.config/unbound/conf/forward-records.conf` (montado en el contenedor) |

## Cómo habilitar / desplegar

1. `cd .config/containers/available/unbound && qctl install`
2. `systemctl --user daemon-reload`

(No requiere secretos. El resolver queda escuchando en el `5353` del host, no en el `53`.)

## Follow-ups

- Puerto publicado en `5353` (no en `53`): cualquier cliente/`systemd-resolved` que quiera usarlo debe apuntar explícitamente a `127.0.0.1:5353`.
- Para reenviar a un resolver público (Cloudflare DoT, etc.) en lugar de recursar, descomentar la `forward-zone` de `.config/unbound/conf/forward-records.conf`.
- Para añadir registros locales (A/PTR) sin tocar el fragmento, montar además un `a-records.conf` propio.
- Usa el healthcheck de la imagen (`drill @127.0.0.1 cloudflare.com`); no se define `HealthCmd` propio (la imagen no trae `curl`/`wget`).
- No aplica hardening (`ReadOnly`, `NoNewPrivileges`, `User`/`Group`); evaluar añadirlo.
