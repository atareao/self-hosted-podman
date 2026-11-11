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

**ACL (access-control) y cliente visto por pasta.** La ACL por defecto de la imagen (`allow 127/8,10/8,172.16/12,192.168/16`) **no** incluye la IP que pasta presenta como cliente en este host (la IP pública del host, no la del contenedor): por eso `dig @127.0.0.1 -p 5353 example.com` desde el host devuelve `REFUSED` + `EDE: 18 (Prohibited)`. El fragmento versionado lleva una **línea de ejemplo comentada** (`# access-control: <ip-del-host>/32 allow`); esa IP es host-específica y **no** se hardcodea en el repo. Averiguarla: lanzar una consulta desde el host y mirar el log de unbound, que registra la IP del cliente en el `refused` (`journalctl --user -u unbound -n 20`, o `dig @127.0.0.1 -p 5353 example.com` seguido de ese log). Descomentar la línea sustituyendo `<ip-del-host>` por esa IP y reiniciar el stack (`systemctl --user restart unbound`); con ella la consulta resuelve `NOERROR` con flag `ad` (DNSSEC). Dentro del contenedor, `unbound-host example.com` resuelve siempre (no pasa por pasta).

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| — | — | — | No define `Environment=` ni variables de `.env`; la configuración está en `.config/unbound/conf/forward-records.conf` (montado en el contenedor) |

## Cómo habilitar / desplegar

1. `cd .config/containers/available/unbound && qctl install`
2. `systemctl --user daemon-reload`

(No requiere secretos. El resolver queda escuchando en el `5353` del host, no en el `53`.)

## Follow-ups

- Puerto publicado en `5353` (no en `53`): el Podman rootless de `runner` no puede enlazar puertos privilegiados (`ip_unprivileged_port_start=80`), así que el `53` del host queda **sin cubrir a propósito**; cualquier cliente/`systemd-resolved` que quiera usar este resolver debe apuntar explícitamente a `127.0.0.1:5353`.
- **ACL por defecto insuficiente**: `dig` desde el host puede dar `REFUSED`/`EDE 18` si la IP que pasta presenta como cliente no cae en la ACL de la imagen; descomentar la línea de ejemplo `# access-control: <ip-del-host>/32 allow` del fragmento con la IP del host (ver «Cómo funciona»).
- Para reenviar a un resolver público (Cloudflare DoT, etc.) en lugar de recursar, descomentar la `forward-zone` de `.config/unbound/conf/forward-records.conf`.
- Para añadir registros locales (A/PTR) sin tocar el fragmento, montar además un `a-records.conf` propio.
- Usa el healthcheck de la imagen (`drill @127.0.0.1 cloudflare.com`); no se define `HealthCmd` propio (la imagen no trae `curl`/`wget`).
- No aplica hardening (`ReadOnly`, `NoNewPrivileges`, `User`/`Group`); evaluar añadirlo.
