# trilium — Notas jerárquicas autoalojadas (Trilium Notes)

## Qué es

Trilium Notes: aplicación de toma de notas jerárquica y autoalojada (imagen `docker.io/zadam/trilium:latest`). Un único contenedor (`trilium`). Red: `proxy.network` (red del *edge* Traefik). Dominio: subdominio `trilium.${FQDN}` (`${FQDN}` es la raíz del host; aquí se sirve como subdominio). Puerto interno expuesto a Traefik: `8080`.

## Ficheros

- Quadlet(s): `.config/containers/available/trilium/trilium.container`
- Volumen(es): `.config/containers/available/trilium/trilium-data.volume`
- Config no secreta: — (no existe `.env` de stack)
- Secretos: — (ninguno)

## Cómo funciona

Contenedor sin privilegios propios de red: se une a `proxy.network` con `NetworkAlias=trilium`, de modo que Traefik lo alcanza por el puerto interno `8080`. Los datos persisten en el volumen nombrado `trilium-data.volume` montado en `/home/node/trilium-data` (con sufijo `:Z` para SELinux), y el directorio se pasa a la app con `TRILIUM_DATA_DIR`. Se arranca con `PodmanArgs=--init` (init mínimo para reapear zombies) y `Restart=always`. No define healthcheck, ni hardening (`ReadOnly`, `NoNewPrivileges`, `User`/`UserNS`), ni secretos. El enrutado Traefik usa el router `trilium` en el entrypoint `websecure`, con TLS vía `letsencrypt` y los middlewares `seguridadHeaders@file,compresionHeaders@file`.

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `TRILIUM_DATA_DIR` | `trilium.container` (`Environment=`) | `/home/node/trilium-data` | Directorio de datos de Trilium dentro del contenedor |
| `FQDN` | entorno systemd (`~/.config/environment.d/fqdn.conf`) | `<tu-dominio>` | Dominio raíz; aquí se usa como `trilium.${FQDN}` en la label Traefik |

## Cómo habilitar / desplegar

1. `cd .config/containers/available/trilium && qctl install`
2. `systemctl --user daemon-reload`

(No requiere secretos.)

## Follow-ups

- No define `HealthCmd`; si se quiere que `qctl status`/systemd refleje el estado real, añadir un healthcheck HTTP sobre `http://localhost:8080`.
- No aplica hardening (`ReadOnly`, `NoNewPrivileges`, `User`/`Group`); evaluar añadirlo.

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-014, issue #9): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP OK) y **purgado ese mismo día** (unit desenlazado,
volumen/binds e imagen eliminados). Estado actual: **no desplegado**.
