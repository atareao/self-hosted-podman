# miniflux — Lectores de noticias RSS

## Qué es
- **Aplicación:** miniflux
- **Imagen:** docker.io/miniflux/miniflux:latest
- **Consola contenedores:** 3 (miniflux, miniflux-postgresql, miniflux-reactflux)
- **Redes:** proxy.network, miniflux.network
- **Dominio:** `miniflux.${FQDN}` (subdominio)
- **Puerto interno:** 8080 (traefik.http.services.miniflux.loadbalancer.server.port)

## Ficheros
- **Quadlet(s):**
  - .config/containers/available/miniflux/miniflux.container
  - .config/containers/available/miniflux/miniflux-postgresql.container
  - .config/containers/available/miniflux/miniflux-reactflux.container
- **Volumen(es):**
  - .config/containers/available/miniflux/miniflux-data.volume
  - .config/containers/available/miniflux/miniflux-postgresql.volume
- **Config no secreta:** .config/miniflux/miniflux.env
- **Secretos:** miniflux_database_url, miniflux_admin_password, miniflux_postgres_password

## Cómo funciona
- **Redes:** Proxy y red interna de Miniflux
- **Volúmenes:** Persistencia de datos y BBDD PostgreSQL
- **Secretos:** `DATABASE_URL`, `ADMIN_PASSWORD`, `POSTGRES_PASSWORD`
- **EnvironmentFile:** carga variables públicas desde `.config/miniflux/miniflux.env` y `.config/miniflux/miniflux.env.local`
- **Healthcheck:** PostgreSQL tiene healthcheck, Miniflux y Reactflux no definen ninguno
- **Traefik:** enruta al puerto 8080 con host `miniflux.${FQDN}` y middlewares de seguridad
- **User:** no especificado (se ejecuta como root en el quadlet)

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| RUN_MIGRATIONS | Environment | $RUN_MIGRATIONS | Ejecuta migraciones
| CREATE_ADMIN | Environment | $CREATE_ADMIN | Crea usuario admin
| ADMIN_USERNAME | Environment | $ADMIN_USERNAME | Nombre de administrador
| POSTGRES_USER | .config/miniflux/miniflux.env | miniflux | Usuario de BBDD

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store):
   - `printf '%s' '\u003cvalor\u003e' | podman secret create miniflux_database_url -`
   - `printf '%s' '\u003cvalor\u003e' | podman secret create miniflux_admin_password -`
   - `printf '%s' '\u003cvalor\u003e' | podman secret create miniflux_postgres_password -`
2. `cd .config/containers/available/miniflux && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
