# dozzle — Visualizador de logs de contenedores

## Qué es

Dozzle es un visor web en tiempo real de los logs de los contenedores (Podman/Docker).

- **App / imagen (`Image=`):** `docker.io/amir20/dozzle:latest`, contenedor `dozzle`.
- **Nº contenedores:** 1.
- **Red:** `proxy.network` (sin `NetworkAlias`).
- **Dominio:** `dozzle.${FQDN}` (router Traefik `dozzle`).
- **Puerto interno (Traefik):** `8080`.
- No hay `PublishPort`: el acceso es solo vía Traefik.

## Ficheros

- Quadlet: `.config/containers/available/dozzle/dozzle.container`
- Volumen: bind inline `%t/podman/podman.sock:/var/run/docker.sock:ro` (socket del daemon Podman; NO existe unidad `.volume`).
- Config no secreta: — (ninguna).
- Secretos:
  - `dozzle_username` (env target `DOZZLE_USERNAME`)
  - `dozzle_password` (env target `DOZZLE_PASSWORD`)

## Cómo funciona

- **Red:** `proxy.network`.
- **Volumen:** monta el socket de Podman en `/var/run/docker.sock` (ro) para leer los logs de todos los contenedores del usuario.
- **Autenticación:** usuario/contraseña simple vía los secretos `dozzle_username`/`dozzle_password` (variables `DOZZLE_USERNAME`/`DOZZLE_PASSWORD`).
- **Enrutado Traefik:** servicio `dozzle` puerto `8080`, router `dozzle` con `Host(`dozzle.${FQDN}`)`, `websecure`, `certresolver=letsencrypt`, middlewares `seguridadHeaders@file,compresionHeaders@file`.
- **Secretos / EnvironmentFile:** secretos sí; no hay `EnvironmentFile`.
- **Healthcheck:** no define `Health*`.
- **Hardening:** sección vacía (sin `User` ni `NoNewPrivileges`).
- **AutoUpdate:** `AutoUpdate=registry`; `PodmanArgs=--init`.
- **Arranque:** `After=network-online.target traefik.service`, `Restart=always`, `RestartSec=10s`, `StartLimitIntervalSec=300` y `StartLimitBurst=3` (van en `[Unit]`), `TimeoutStartSec=60`, `WantedBy=default.target`.

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `DOZZLE_USERNAME` | `Secret=dozzle_username,type=env` | *secreto* | Usuario de acceso a la UI |
| `DOZZLE_PASSWORD` | `Secret=dozzle_password,type=env` | *secreto* | Contraseña de acceso a la UI |
| `FQDN` | label del router | *(inyectada por systemd)* | Dominio raíz; el stack usa `dozzle.${FQDN}` |

## Cómo habilitar / desplegar

1. Crear los secretos (NUNCA `crypta store`):
   - `printf '%s' '<usuario>' | podman secret create dozzle_username -`
   - `printf '%s' '<password>' | podman secret create dozzle_password -`
2. `cd .config/containers/available/dozzle && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups

- Sin healthcheck ni hardening (`User`/`NoNewPrivileges`).
- Credenciales únicas (un solo usuario).

## Estado de despliegue

Desplegado y verificado en producción (`new_atareao`) el 2026-11-09 (PLAN-011, issue #5), y
**desinstalado ese mismo día**: units desenlazados (`qctl uninstall`), volúmenes, secretos y datos
eliminados. Estado actual: **no desplegado**.
