# homepage — Portada de servicios web

## Qué es
Homepage es una herramienta de landing page para administrar servicios web. Se ejecuta con la imagen `ghcr.io/benphelps/homepage:latest`. La stack está compuesta por 1 contenedor, utiliza la red `proxy.network` y expone el subdominio `homepage.${FQDN}` con el puerto interno `3000` gestionado por Traefik.

## Ficheros
- Quadlet(s):
  - `homepage.container`
- Volumen(es):
  - `homepage-homepage_config.volume`
- Config no secreta: *(ninguno)*
- Secretos: *(ninguno)*

## Cómo funciona
- Red: Conexión a `proxy.network` para acceso público.
- Volúmenes: Persistencia de la configuración en `homepage-homepage_config`.
- `EnvironmentFile`: No se usa.
- Healthcheck: No definido.
- User: Se ejecuta con la UID predeterminada (1000).
- NoNewPrivileges: No habilitado.

## Variables / configuración

(no variables definidas)

## Cómo habilitar / desplegar
1. `cd .config/containers/available/homepage && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-017, issue #12): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP 200) y **purgado ese mismo día**. Estado actual: **no desplegado**.
