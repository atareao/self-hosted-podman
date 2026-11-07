# codimd — editor de documentos colaborativos con PostgreSQL

## Qué es
*Imagen*:
- codimd: docker.io/hackmdio/hackmd:2.4.2-cjk
- codimd-postgresql: docker.io/library/postgres:11.6-alpine
*nº contenedores*: 2
*Red*: proxy.network, codimd.network
*Dominio*: Host(`codimd.${FQDN}`)
*Puerto interno*: 3000 (codimd)

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/codimd/codimd.container
  - /data/self-hosted-podman/.config/containers/available/codimd/codimd-postgresql.container
- Volumen(es):
  - /data/self-hosted-podman/.config/containers/available/codimd/codimd.volume
  - Volume mount inside codimd-postgresql: %h/.config/codimd/codimddb to /var/lib/postgresql/data
- Config no secreta: N/A
- Secretos: N/A

## Cómo funciona
Red: proxy.network y internal codimd.network.
Volúmenes: codimd.volume -> /home/hackmd/app/public/uploads, codimddb -> /var/lib/postgresql/data.
Healthcheck: N/A
Enrutado Traefik: Host(`codimd.${FQDN}`), puerto 3000, middleware seguridadHeaders@file, compresionHeaders@file.
User/UserNS/NoNewPrivileges: N/A

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| N/A | N/A | N/A | N/A |

## Cómo habilitar / desplegar
1. `cd .config/containers/available/codimd && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)