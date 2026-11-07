# dockge — Frontend de Docker Compose

## Qué es
**Aplicación**: dockge (image: `docker.io/louislam/dockge`)
**Número de contenedores**: 1
**Red**: `proxy.network`
**Dominio**: `dockge.${FQDN}`
**Puerto interno**: `5001`

## Ficheros
- Quadlet(s):
  - `/data/self-hosted-podman/.config/containers/available/dockge/dockge.container`
- Volumen(es):
  - `/data/self-hosted-podman/.config/containers/available/dockge/dockge.sock-volume`  *(bind: `%t/podman/podman.sock:/var/run/docker.sock:ro`)*
  - `/data/self-hosted-podman/.config/containers/available/dockge/dockge-stacks-volume`  *(bind: `%h/.config/dockge/stacks:/opt/stacks:Z`)*
  - `/data/self-hosted-podman/.config/containers/available/dockge/dockge-data-volume`  *(bind: `%h/.config/dockge/data:/app/data:Z`)*
- Config no secreta: —
- Secretos: —

## Cómo funciona
- Red `proxy.network`
- Volúmenes: socket de podman, directorio de stacks y datos de dockge
- Secretos: ninguno
- Healthcheck:
  - `HealthCmd=/app/extra/healthcheck`
  - `HealthInterval=60s`
  - `HealthTimeout=30s`
  - `HealthStartPeriod=60s`
  - `HealthRetries=5`
- Enrutado Traefik: reglas en las Labels
- User/UserNS/NoNewPrivileges: no especificado
- Socket de daemon de podman expuesto en el contenedor (`%t/podman/podman.sock`)

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| N/A | — | — | — |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store): —
2. `cd .config/containers/available/dockge && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)