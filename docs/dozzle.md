# dozzle — Visualizador de logs de Podman

## Qué es
**Aplicación**: dozzle (image: `docker.io/amir20/dozzle:latest`)
**Número de contenedores**: 1
**Red**: `proxy.network`
**Dominio**: `dozzle.${FQDN}`
**Puerto interno**: `8080`

## Ficheros
- Quadlet(s):
  - `/data/self-hosted-podman/.config/containers/available/dozzle/dozzle.container`
- Volumen(es):
  - `/data/self-hosted-podman/.config/containers/available/dozzle/dozzle.sock-volume`  *(bind: `%t/podman/podman.sock:/var/run/docker.sock:ro`)*
- Config no secreta: —
- Secretos:
  - `dozzle_username`
  - `dozzle_password`

## Cómo funciona
- Red `proxy.network`
- Volumen: socket de podman (`%t/podman/podman.sock`)
- Secretos:
  - `dozzle_username` (env target `DOZZLE_USERNAME`)
  - `dozzle_password` (env target `DOZZLE_PASSWORD`)
- Healthcheck: no
- Enrutado Traefik: reglas en las Labels
- User/UserNS/NoNewPrivileges: no especificado

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| N/A | — | — | — |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store):
   - `printf '%s' '<valor>' | podman secret create dozzle_username -`
   - `printf '%s' '<valor>' | podman secret create dozzle_password -`
2. `cd .config/containers/available/dozzle && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)

## Estado de despliegue

Desplegado y verificado en producción (`new_atareao`) el 2026-11-09 (PLAN-011, issue #5).
URL: https://dozzle.servidorlinux.es — cert LE válido, router Traefik activo.
Requiere los secretos `dozzle_username`/`dozzle_password` (usuario `admin`).