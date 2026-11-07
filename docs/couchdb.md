# couchdb — base de datos NoSQL en Docker

## Qué es
*Imagen*: docker.io/library/couchdb
*nº contenedores*: 1
*Red*: proxy.network
*Dominio*: Host(`couchdb.${FQDN}`)
*Puerto interno*: 5984

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/couchdb/couchdb.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/couchdb/couchdb-data.volume
- Config no secreta: N/A
- Secretos: couchdb_password

## Cómo funciona
Red: proxy.network
Volúmenes: couchdb-data.volume mounted at /opt/couchdb/data
Healthcheck: N/A
Enrutado Traefik: Host(`couchdb.${FQDN}`), puerto 5984, middleware seguridadHeaders@file, compresionHeaders@file.
User/UserNS/NoNewPrivileges: N/A

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| COUCHDB_USER | Environment | usuario | Usuario base de datos.

## Cómo habilitar / desplegar
1. `printf '%s' '<valor>' | podman secret create couchdb_password -`
2. `cd .config/containers/available/couchdb && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)