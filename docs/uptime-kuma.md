# uptime-kuma — Monitorización de disponibilidad (Uptime Kuma)

## Qué es

Uptime Kuma: herramienta de monitorización de disponibilidad y estado de servicios (imagen `docker.io/louislam/uptime-kuma:2`). Un único contenedor (`uptime-kuma`). Red: `proxy.network`. Dominio: subdominio `uptime.${FQDN}` (`${FQDN}` es la raíz del host). Puerto interno expuesto a Traefik: `3001`.

## Ficheros

- Quadlet(s): `.config/containers/available/uptime-kuma/uptime-kuma.container`
- Volumen(es): `.config/containers/available/uptime-kuma/uptime-kuma-data.volume`
- Config no secreta: — (no existe `.env` de stack)
- Secretos: — (ninguno)

## Cómo funciona

Se une a `proxy.network` con `NetworkAlias=uptime_kuma`, de modo que Traefik lo alcanza por el puerto interno `3001`. Los datos (monitores, histórico, configuración) persisten en el volumen nombrado `uptime-kuma-data.volume` montado en `/app/data` (con `:Z`). Arranca con `PodmanArgs=--init` y `Restart=always`. No define `AutoUpdate`, healthcheck, hardening, secretos ni variables de entorno. El enrutado Traefik usa el router `uptime_kuma` en el entrypoint `websecure`, con TLS vía `letsencrypt` y los middlewares `seguridadHeaders@file,compresionHeaders@file`.

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `FQDN` | entorno systemd (`~/.config/environment.d/fqdn.conf`) | `<tu-dominio>` | Dominio raíz; se usa como `uptime.${FQDN}` en la label Traefik |

## Cómo habilitar / desplegar

1. `cd .config/containers/available/uptime-kuma && qctl install`
2. `systemctl --user daemon-reload`

(No requiere secretos.)

## Follow-ups

- No define `HealthCmd`; añadir uno permitiría a systemd/podman reflejar el estado real.
- No aplica hardening (`ReadOnly`, `NoNewPrivileges`, `User`/`Group`); evaluar añadirlo.
