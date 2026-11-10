# publirs — Servicio de publicación de contenido

## Qué es
- **App**: publirs
- **Imagen**: docker.io/atareao/publirs:latest
- **Nº contenedores**: 2 (publirs, publirs-croni)
- **Red**: publirs.network (alias publirs y croni)
- **Dominio**: ninguno definido en Traefik labels
- **Puerto interno**: ninguno definido en Traefik labels

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/publirs/publirs.container, /data/self-hosted-podman/.config/containers/available/publirs/publirs-croni.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/publirs/publirs-db.volume
- Config no secreta: ninguno
- Secretos: publirs_token

## Cómo funciona
- **Red**: publirs.network
- **Volúmenes**: publirs-db.volume -> /app/db
- **Secretos**: publirs_token
- **Healthcheck**: ninguno
- **Routing Traefik**: ninguno
- **User/UserNS/NoNewPrivileges**: ninguno

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| LOG_LEVEL | Environment | debug | nivel de log |
| DB_URL | Environment | sqlite:/app/db/publirs.db | URL de la BD |
| PORT | Environment | 8080 | Puerto interno |
| ENVIRONMENT | Environment | PRODUCTION | entorno |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store): `printf '%s' '<valor>' | podman secret create publirs_token -`
2. `cd .config/containers/available/publirs && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- **Sin enrutado por diseño**: el stack no declara labels de Traefik (igual que en el repo origen `atareao/self-hosted`); si hay que exponerlo, se añaden labels `Host(`<subdominio>.${FQDN}`)` propias. Ver los invariantes de enrutado en `docs/traefik.md`.