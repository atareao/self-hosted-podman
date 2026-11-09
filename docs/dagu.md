# dagu — Scheduler y workflow en contenedor

## Qué es
Gestor de tareas cron basado en DAGs.
- **App**: dagu
- **Imagen**: ghcr.io/dagu-org/dagu:latest
- **Contenedores**: 1
- **Red**: proxy.network
- **Dominio**: `dagu.${FQDN}`
- **Puerto interno**: 8080

## Ficheros
- **Quadlet(s)**: /data/self-hosted-podman/.config/containers/available/dagu/dagu.container
- **Volumen(es)**: ninguno
- **Config no secreta**: ninguna
- **Secretos**:
  - dagu_basicauth_password (target: DAGU_BASICAUTH_PASSWORD)

## Cómo funciona
- **Red**: proxy.network
- **Volúmenes**: ninguno
- **EnvironmentFile**: ninguna
- **Socket del daemon**: ninguno
- **Healthcheck**: ninguno
- **Enrutado Traefik**: router `dagu` con puerto 8080
- **User/UserNS/NoNewPrivileges**: valores por defecto de container

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| DAGU_TZ | Environment | Europe/Madrid | Zona horaria |
| DAGU_BASE_PATH | Environment | /dagu | Ruta base de la API |
| DAGU_IS_BASICAUTH | Environment | 1 | Habilita autenticación básica |
| DAGU_BASICAUTH_USERNAME | Environment | usuario | Usuario de autenticación |

## Cómo habilitar / desplegar
1. `printf '%s' '<valor>' | podman secret create dagu_basicauth_password -`
2. `cd .config/containers/available/dagu && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-019, issue #14): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP 200) y **purgado ese mismo día**. Estado actual: **no desplegado**.

**Bugs corregidos**:
- La imagen era `ghcr.io/dagu-org/dagu:latest` y devolvía **403 Forbidden** (el proyecto se renombró de
  `dagu-org` a `dagucloud`). Corregido a `ghcr.io/dagucloud/dagu:latest`.
- Se eliminó `DAGU_BASE_PATH=/dagu`: con base path la UI se sirve bajo `/dagu` pero el router Traefik es
  `Host(dagu.${FQDN})` sin `PathPrefix`, así que `/` daba 404. Sirviendo en raíz coincide con el router.
- Requiere el secreto `dagu_basicauth_password` (crear con `podman secret create`).
