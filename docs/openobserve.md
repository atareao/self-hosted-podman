# openobserve — Plataforma de observabilidad y análisis de logs

## Qué es
- **App:** OpenObserve
- **Imagen:** public.ecr.aws/zinclabs/openobserve:latest
- **Número de contenedores:** 1 (openobserve)
- **Red(es):** proxy.network, security.network
- **Dominio:** subdominio `openobserve.${FQDN}`
- **Puerto interno:** 5080

## Ficheros
- Quadlet(s):
  - .config/containers/available/openobserve/openobserve.container
- Volumen(es):
  - .config/containers/available/openobserve/openobserve-data.volume
- Config no secreta:
  - .config/openobserve/openobserve.env
- Secretos: openobserve_root_password

## Cómo funciona
- **Redes:** `proxy.network` para Traefik; `security.network` para comunicación interna segura.
- **Volumes:** persistencia de datos de la plataforma.
- **Secrets:** contraseña raíz requerida por OpenObserve.
- **EnvironmentFile:** lee `.config/openobserve/openobserve.env` y `.config/openobserve/openobserve.env.local`.
- **Healthcheck:** no definido.
- **Traefik:** ruta `openobserve.${FQDN}` con puerto 5080.
- **User:** no se establece explícitamente.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| ZO_ROOT_USER_EMAIL | .config/openobserve/openobserve.env | admin@example.com | Email del usuario root |
| ZO_LOCAL_MODE | .config/openobserve/openobserve.env | true | Modo local |
| ZO_DATA_RETENTION_DAYS | .config/openobserve/openobserve.env | 30 | Retención de datos |

## Cómo habilitar / desplegar
1. Secretos:
   ```bash
   printf '%s' '<valor>' | podman secret create openobserve_root_password -
   ```
2. `cd .config/containers/available/openobserve && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-019, issue #14): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP 200) y **purgado ese mismo día**. Estado actual: **no desplegado**.

**Nota**: el quadlet usa `Network=security.network`, que vive en el stack **`vector`**
(`.config/containers/available/vector/security.network`). Para desplegar openobserve aislado hay que
enlazar `security.network` en `~/.config/containers/systemd/` (el generador omite el unit si falta la red).
Requiere el secreto `openobserve_root_password` (crear con `podman secret create`).
