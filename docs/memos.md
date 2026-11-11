# memos — Notas rápidas self-hosted (timeline tipo microblog)

## Qué es

Memos es un servicio de anotaciones rápidas (notas tipo *timeline*), autoalojado.

- **App / imagen (`Image=`):** `docker.io/neosmemo/memos:stable`, contenedor `memos`.
- **Nº contenedores:** 1.
- **Red:** `proxy.network`, alias `memos`.
- **Dominio:** `memos.${FQDN}` (router Traefik `memos`).
- **Puerto interno (Traefik):** `5230`.
- No hay `PublishPort`: el acceso es solo vía Traefik.

## Ficheros

- Quadlet: `.config/containers/available/memos/memos.container`
- Volumen: `.config/containers/available/memos/memos-data.volume` (`VolumeName=memos-data`) → `/var/opt/memos` (datos + SQLite).
- Config no secreta: — (ninguna).
- Secretos: ninguno.

## Cómo funciona

- **Red:** `proxy.network`.
- **Volumen:** `memos-data` en `/var/opt/memos` (base de datos y datos de la app).
- **Enrutado Traefik:** servicio `memos` puerto `5230`, router `memos` con `Host(`memos.${FQDN}`)`, `websecure`, `certresolver=letsencrypt`, middlewares `seguridadHeaders@file,compresionHeaders@file`.
- **Secretos / EnvironmentFile:** ninguno.
- **Socket del daemon:** no monta `podman.sock`.
- **Healthcheck:** no define `Health*`.
- **Hardening:** sección vacía (sin `User` ni `NoNewPrivileges`).
- **AutoUpdate:** `AutoUpdate=registry`; `PodmanArgs=--init`.
- **Arranque:** `After=network-online.target traefik.service`, `Restart=always`, `RestartSec=10s`, `StartLimitIntervalSec=300`, `StartLimitBurst=3`, `TimeoutStartSec=60`, `WantedBy=default.target`.

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `FQDN` | label del router | *(inyectada por systemd)* | Dominio raíz; el stack usa `memos.${FQDN}` |

No hay `.env` de stack ni variables propias.

## Cómo habilitar / desplegar

1. No requiere secretos.
2. `cd .config/containers/available/memos && qctl install`
3. `systemctl --user daemon-reload`
4. Primer acceso: crear el usuario admin desde la UI.

## Follow-ups

- Imagen anclada a `stable` (el tag `latest` no existe en Docker Hub).
- Sin healthcheck ni hardening.

## Estado de despliegue

Desplegado y verificado en producción (`new_atareao`) el 2026-11-09 (PLAN-011, issue #5), y
**desinstalado ese mismo día**: units desenlazados (`qctl uninstall`), volúmenes, secretos y datos
eliminados. Estado actual: **no desplegado**.
