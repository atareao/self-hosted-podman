# storyteller — Plataforma de audiolibros y sincronización de texto/voz

## Qué es

Storyteller es una plataforma autoalojada para generar y servir audiolibros sincronizados con el texto (alineación texto↔audio).

- **App / imagen (`Image=`):** `registry.gitlab.com/storyteller-platform/storyteller:latest`, contenedor `storyteller`.
- **Nº contenedores:** 1.
- **Red:** `proxy.network` (red edge de Traefik), alias `storyteller`.
- **Dominio:** `storyteller.${FQDN}` → **subdominio** `storyteller` (router Traefik `storyteller`).
- **Puerto interno (Traefik):** `8001` (`traefik.http.services.storyteller.loadbalancer.server.port=8001`).
- No hay `PublishPort`: el acceso es solo vía Traefik.

## Ficheros

- Quadlet(s): `.config/containers/available/storyteller/storyteller.container`
- Volumen(es): `.config/containers/available/storyteller/storyteller-data.volume`
- Config no secreta: no existe `.env` de stack (no hay `.config/storyteller/`).
- Secretos: `storyteller_secret_key`.

## Cómo funciona

- **Red:** el contenedor se une a `proxy.network` (alias `storyteller`), por lo que Traefik lo descubre y enruta; no hay red interna propia (servicio único).
- **Enrutado Traefik:** `traefik.enable=true`, servicio `storyteller` en el puerto `8001`, router `storyteller` con `Host(\`storyteller.${FQDN}\`)`, entrypoint `websecure`, `certresolver=letsencrypt` y middlewares `seguridadHeaders@file,compresionHeaders@file`.
- **Volúmenes:** `storyteller-data.volume` se monta en `/data` con `rw` (`Volume=storyteller-data.volume:/data:rw:Z`); contiene la biblioteca y los datos generados.
- **Secretos:** `storyteller_secret_key` se inyecta como variable de entorno con `Secret=storyteller_secret_key,type=env,target=STORYTELLER_SECRET_KEY` (driver `crypta`). No hay `EnvironmentFile`.
- **Socket del daemon:** no monta `podman.sock`.
- **Healthcheck:** no define `Health*`.
- **Hardening:** sección `Hardening` vacía (sin `User`, `NoNewPrivileges` ni `ReadOnly`).
- **AutoUpdate:** `AutoUpdate=registry` (imagen `latest`).
- **Arranque:** `After=network-online.target traefik.service`, `Restart=always`, `RestartSec=10s`, `StartLimitIntervalSec=300`, `StartLimitBurst=3`, `TimeoutStartSec=60`, `WantedBy=default.target`.

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `STORYTELLER_SECRET_KEY` | `storyteller.container` (`Secret=storyteller_secret_key`) | *(secreto)* | Clave de firma/sesión de la aplicación |
| `FQDN` | `storyteller.container` (label `traefik.http.routers.storyteller.rule`) | *(inyectada por systemd desde `~/.config/environment.d/fqdn.conf`)* | Dominio raíz del host; el stack usa `storyteller.${FQDN}` |

No hay `.env` de stack para este servicio.

## Cómo habilitar / desplegar

1. Crear el secreto (con `podman secret create`, **nunca** `crypta store`):

```bash
printf '%s' '<valor>' | podman secret create storyteller_secret_key -
```

2. `cd .config/containers/available/storyteller && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups

- Es el único quadlet del grupo sin `PodmanArgs=--init`; el resto de stacks lo usan para reapear hijos. Valorar añadirlo por consistencia.
- Sin healthcheck ni hardening (`User`, `NoNewPrivileges`, `ReadOnly`).
- Imagen `latest` con `AutoUpdate=registry`: las actualizaciones pueden introducir cambios de comportamiento sin aviso.
