# otterwiki — Wiki colaborativo basada en markdown

## Qué es
- **App:** Otterwiki
- **Imagen:** docker.io/redimp/otterwiki:2
- **Número de contenedores:** 1 (otterwiki)
- **Red(es):** proxy.network
- **Dominio:** subdominio `wiki.${FQDN}`
- **Puerto interno:** 80

## Ficheros
- Quadlet(s):
  - .config/containers/available/otterwiki/otterwiki.container
- Volumen(es):
  - .config/containers/available/otterwiki/otterwiki-data.volume
- Config no secreta: ninguno
- Secretos: ninguno

## Cómo funciona
- **Red proxy.network:** expone el servicio a través de Traefik.
- **Volumen:** almacenamiento persistente de contenido wiki.
- **Healthcheck:** no definido.
- **Traefik:** enrutado por `wiki.${FQDN}` y puerto 80.
- **User:** no se especifica.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| SITE_NAME | otterwiki.container | Wiki | Nombre del sitio |
| DISABLE_REGISTRATION | otterwiki.container | True | Deshabilita registro de usuarios |
| READ_ACCESS | otterwiki.container | REGISTERED | Acceso de lectura |
| WRITE_ACCESS | otterwiki.container | REGISTERED | Acceso de escritura |

## Cómo habilitar / desplegar
1. Secretos: ninguno.
2. `cd .config/containers/available/otterwiki && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-013, issue #7): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP OK) y **purgado ese mismo día** (units desenlazados,
volúmenes/binds e imágenes eliminados). Estado actual: **no desplegado**.

El dominio es `wiki.${FQDN}` (no `otterwiki.${FQDN}`).
