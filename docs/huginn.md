# huginn — Automización de tareas y workflows

## Qué es
Imagenes: docker.io/huginn/huginn-single-process (3000), docker.io/library/mariadb (no porta inter), docker.io/library/mariadb (no porta inter). 3 contenedores, red: huginn, dominio: Host(`huginn.${FQDN}`), puerto interno: 3000

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/huginn/huginn.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/huginn/huginn-threaded.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/huginn/huginn-huginn_mariadb.container
- Volume(s): /data/self-hosted-podman/.config/containers/available/huginn/huginn-huginn_mariadb.volume
- Config no secreta: NINGUNO
- Secretos: huginn_database_password, huginn_mysql_password, huginn_mariadb_root_password

## Cómo funciona
Red huginn; volúmenes: huginn-huginn_mariadb; secretos: tres. EnvironmentFile: ninguno; socket del daemon: no; healthcheck: ninguno; enrutado Traefik: router *huginn*. User: ninguno; NoNewPrivileges: habilitado.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| (ninguno) | | | |

## Cómo habilitar / desplegar
1. `cd .config/containers/available/huginn && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)