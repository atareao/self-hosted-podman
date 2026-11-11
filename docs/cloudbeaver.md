# cloudbeaver — gestor de bases de datos en Docker

## Qué es
*Imagen*: docker.io/dbeaver/cloudbeaver:latest
*nº contenedores*: 1
*Red*: proxy.network
*Dominio*: Host(`cloudbeaver.${FQDN}`)
*Puerto interno*: 8978

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/cloudbeaver/cloudbeaver.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/cloudbeaver/cloudbeaver-data.volume
- Config no secreta: N/A
- Secretos: N/A

## Cómo funciona
Red: proxy.network
Volúmenes: cloudbeaver-data.volume mounted at /opt/cloudbeaver/workspace
Healthcheck: N/A
Enrutado Traefik: Host(`cloudbeaver.${FQDN}`), puerto 8978, middleware seguridadHeaders@file, compresionHeaders@file.
User/UserNS/NoNewPrivileges: N/A

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| N/A | N/A | N/A | N/A |

## Cómo habilitar / desplegar
1. `cd .config/containers/available/cloudbeaver && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-015, issue #10): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP 200) y **purgado ese mismo día** (unit desenlazado,
volumenes/binds e imagen eliminados). Estado actual: **no desplegado**.