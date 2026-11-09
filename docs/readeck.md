# readeck — Aplicación web de lectura

## Qué es
- **App**: readeck
- **Imagen**: codeberg.org/readeck/readeck
- **Nº contenedores**: 1 (readeck)
- **Red**: proxy.network
- **Dominio**: readeck.${FQDN} (subdominio "readeck")
- **Puerto interno**: 8000 (traefik http.services readeck loadbalancer.port)

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/readeck/readeck.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/readeck/readeck-data.volume
- Config no secreta: ninguno
- Secretos: ninguno

## Cómo funciona
- **Red**: proxy.network
- **Volúmenes**: readeck-data.volume -> /readeck
- **Secretos**: ninguno
- **Healthcheck**: ninguno
- **Routing Traefik**: Host(`readeck.${FQDN}`), puerto 8000
- **User/UserNS/NoNewPrivileges**: ninguno

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| (ninguna) | | | |

## Cómo habilitar / desplegar
1. `cd .config/containers/available/readeck && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-014, issue #9): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP OK) y **purgado ese mismo día** (unit desenlazado,
volumen/binds e imagen eliminados). Estado actual: **no desplegado**.