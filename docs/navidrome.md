# navidrome — Reproductor de música self-hosted (API Subsonic)

## Qué es

Navidrome es un servidor de música autoalojado compatible con la API Subsonic.

- **App / imagen (`Image=`):** `docker.io/deluan/navidrome:latest`, contenedor `navidrome`.
- **Nº contenedores:** 1.
- **Red:** `proxy.network` (red edge de Traefik), alias `navidrome`.
- **Dominio:** `navidrome.${FQDN}` (router Traefik `navidrome`).
- **Puerto interno (Traefik):** `4533` (`traefik.http.services.navidrome.loadbalancer.server.port=4533`).
- No hay `PublishPort`: el acceso es solo vía Traefik.

## Ficheros

- Quadlet: `.config/containers/available/navidrome/navidrome.container`
- Bind mounts (no hay unidades `.volume`):
  - `%h/.config/navidrome/music` → `/music` (ro): biblioteca de música.
  - `%h/.config/navidrome/data` → `/data` (rw): base de datos SQLite y caché.
- Config no secreta: no existe `.env` de stack (no hay `.config/navidrome/navidrome.env`).
- Secretos: ninguno.

## Cómo funciona

- **Red:** se une a `proxy.network`; Traefik lo descubre y enruta.
- **Enrutado Traefik:** `traefik.enable=true`, servicio `navidrome` puerto `4533`, router `navidrome` con `Host(`navidrome.${FQDN}`)`, entrypoint `websecure`, `certresolver=letsencrypt` y middlewares `seguridadHeaders@file,compresionHeaders@file`.
- **Volúmenes (binds):** `/music` (ro) con la biblioteca y `/data` con la BD. Navidrome lee su configuración solo de variables de entorno (no hay fichero de config): usa los defaults `/music` y `/data`, que coinciden con los binds.
- **Secretos / EnvironmentFile:** ninguno.
- **Socket del daemon:** no monta `podman.sock`.
- **Healthcheck:** no define `Health*`.
- **Hardening:** solo `User=1000:1000` (sin `NoNewPrivileges` ni `ReadOnly`).
- **AutoUpdate:** `AutoUpdate=registry` (imagen `latest`).
- **Arranque:** `After=network-online.target traefik.service`, `Restart=always`, `RestartSec=10s`, `StartLimitIntervalSec=300`, `StartLimitBurst=3`, `TimeoutStartSec=60`, `WantedBy=default.target`.

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `FQDN` | label del router | *(inyectada por systemd desde `~/.config/environment.d/fqdn.conf`)* | Dominio raíz; el stack usa `navidrome.${FQDN}` |

No hay `.env` de stack ni variables propias; Navidrome usa sus defaults (`/music`, `/data`).

## Cómo habilitar / desplegar

1. Crear los directorios de los binds y darles propietario uid 1000 (la imagen corre como uid 1000; si no, falla con «Database could not be opened»):
   - `mkdir -p ~/.config/navidrome/music ~/.config/navidrome/data`
   - `podman unshare chown -R 1000:1000 ~/.config/navidrome/data ~/.config/navidrome/music`
2. (Opcional) Copiar música a `~/.config/navidrome/music`.
3. `cd .config/containers/available/navidrome && qctl install`
4. `systemctl --user daemon-reload`

## Follow-ups

- Arranca con biblioteca vacía si `~/.config/navidrome/music` está vacío.
- Sin healthcheck ni `NoNewPrivileges`.
- Imagen `latest` con `AutoUpdate=registry`.
- Falta `PodmanArgs=--init` respecto al esqueleto canónico.

## Estado de despliegue

Desplegado y verificado en producción (`new_atareao`) el 2026-11-09 (PLAN-011, issue #5), y
**desinstalado ese mismo día**: units desenlazados (`qctl uninstall`), volúmenes, secretos y datos
eliminados. Estado actual: **no desplegado**.
