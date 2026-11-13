# miniflux — Lectores de noticias RSS

## Qué es
- **Aplicación:** miniflux
- **Imagen:** docker.io/miniflux/miniflux:2.3.5
- **Consola contenedores:** 3 (miniflux, miniflux-postgresql, miniflux-reactflux)
- **Redes:** proxy.network, miniflux.network
- **Dominios:** `miniflux.${FQDN}` (Miniflux, router `miniflux`) y `reactflux.${FQDN}` (ReactFlux, router `reactflux`)
- **Puerto interno:** 8080 (traefik.http.services.miniflux.loadbalancer.server.port)

## Ficheros
- **Quadlet(s):**
  - .config/containers/available/miniflux/miniflux.container
  - .config/containers/available/miniflux/miniflux-postgresql.container
  - .config/containers/available/miniflux/miniflux-reactflux.container
  - .config/containers/available/miniflux/miniflux.network
- **Volumen(es):**
  - .config/containers/available/miniflux/miniflux-data.volume
- **Config no secreta:** .config/miniflux/miniflux.env
- **Secretos:** miniflux_database_url, miniflux_admin_password, miniflux_postgres_password

## Cómo funciona
- **Redes:** proxy.network (Miniflux y ReactFlux, tras Traefik) y la red interna miniflux.network (Miniflux y PostgreSQL)
- **Volúmenes:** `miniflux-data.volume:/var/lib/postgresql/data` para la BBDD PostgreSQL
- **Secretos:** `DATABASE_URL`, `ADMIN_PASSWORD` (Miniflux) y `POSTGRES_PASSWORD` (PostgreSQL)
- **EnvironmentFile:** PostgreSQL carga variables públicas desde `.config/miniflux/miniflux.env` y `.config/miniflux/miniflux.env.local`
- **Healthcheck:** los tres definen healthcheck — PostgreSQL (`pg_isready`), Miniflux (`wget … /health`) y ReactFlux (`wget … /`)
- **Dependencias:** Miniflux arranca tras PostgreSQL (`After=`/`Requires=`)
- **Traefik:** enruta Miniflux al puerto 8080 con host `miniflux.${FQDN}` y ReactFlux al puerto 2000 con host `reactflux.${FQDN}`.
- **User:** no especificado (se ejecuta como root en el quadlet)

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| RUN_MIGRATIONS | Environment | 1 | Ejecuta migraciones
| CREATE_ADMIN | Environment | 1 | Crea usuario admin
| ADMIN_USERNAME | Environment | admin | Nombre de administrador
| POSTGRES_USER | .config/miniflux/miniflux.env | miniflux | Usuario de BBDD

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store):
   - `printf '%s' '<valor>' | podman secret create miniflux_database_url -`
   - `printf '%s' '<valor>' | podman secret create miniflux_admin_password -`
   - `printf '%s' '<valor>' | podman secret create miniflux_postgres_password -`
2. `cd .config/containers/available/miniflux && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- ReactFlux en subdominio propio desde PLAN-023 (antes colisionaba con Miniflux en `miniflux.${FQDN}`).
- PostgreSQL fijado a `17-alpine`: la `18-alpine` cambia el `VOLUME` a `/var/lib/postgresql` y hacía perder los datos existentes.
