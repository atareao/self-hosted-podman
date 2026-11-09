# semaphore — interfaz web para la gestión de tareas en equipos

## Qué es
- **Aplicación**: semaphore (Imagen: `docker.io/semaphoreui/semaphore:latest`)
- **Nº de contenedores**: 1 (semaphore)
- **Red**: `proxy.network`
- **Dominio**: subdominio `semaphore.${FQDN}`
- **Puerto interno**: `5005` (traefik.http.services.semaphore.loadbalancer.server.port)

## Ficheros
- **Quadlet(s)**:
  - /data/self-hosted-podman/.config/containers/available/semaphore/semaphore.container
- **Volumen(es)**:
  - /data/self-hosted-podman/.config/containers/available/semaphore/semaphore-config.volume
  - /data/self-hosted-podman/.config/containers/available/semaphore/semaphore-data.volume
- **Config no secreta**: N/A
- **Secretos**:
  - semaphore_admin_password

## Cómo funciona
- **Red**: `proxy.network`
- **Volúmenes**: `/etc/semaphore` y `/var/lib/semaphore` mapeados a los volúmenes `semaphore-config.volume` y `semaphore-data.volume` respectivamente
- **Secrets**: `semaphore_admin_password` inyectado como variable de entorno `SEMAPHORE_ADMIN_PASSWORD`
- **EnvironmentFile**: N/A
- **Socket del daemon**: N/A
- **Healthcheck**: N/A
- **Enrutado Traefik**: etiquetas especificadas en la sección `Labels` del quadlet
- **User/NoNewPrivileges**: N/A

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| SEMAPHORE_DB_DIALECT | semaphore.container | bolt | Dialecto de la base de datos (BoltDB) |
| SEMAPHORE_ADMIN_NAME | semaphore.container | admin | Nombre del usuario administrador |
| SEMAPHORE_ADMIN_EMAIL | semaphore.container | admin@localhost | Email del administrador |
| SEMAPHORE_ADMIN | semaphore.container | admin | Valor literal usado al crear la cuenta administrativa |

## Cómo habilitar / desplegar
1. Secretos (solo si existen): `printf '%s' '<valor>' | podman secret create <nombre> -`
2. `cd /data/self-hosted-podman/.config/containers/available/semaphore && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-019, issue #14): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP 200) y **purgado ese mismo día**. Estado actual: **no desplegado**.

**Bugs corregidos**:
- `SEMAPHORE_DB_DIALECT=bolt` → `Unknown database dialect: bolt`. BoltDB fue **retirado en Semaphore 2.19**
  (solo `sqlite`/`mysql`/`postgres`). Corregido a `sqlite` + `SEMAPHORE_DB=/var/lib/semaphore/semaphore.db`
  (el volumen `semaphore-data.volume:/var/lib/semaphore` ya existía).
- El service de Traefik usaba `port=5005`, pero Semaphore escucha por defecto en **3000** (`Port :3000`) → 502.
  Corregido a 3000.
- Requiere el secreto `semaphore_admin_password` (crear con `podman secret create`).
