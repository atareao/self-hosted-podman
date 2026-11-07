# gitea — Gitea - Self-hosted Git Service

## Qué es
- app: Gitea
- imagen: docker.io/gitea/gitea:1.19
- nº contenedores: 2
- red: gitea.network, proxy.network
- dominio: raíz ${FQDN}, subdominio gitea.${FQDN}
- puerto interno: 3000

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/gitea/gitea.container
  - /data/self-hosted-podman/.config/containers/available/gitea/gitea-db.container
- Volumen(es):
  - /data/self-hosted-podman/.config/containers/available/gitea/gitea-data.volume
  - /data/self-hosted-podman/.config/containers/available/gitea/gitea-db-data.volume
- Config no secreta: ninguno
- Secretos:
  - gitea_db_password

## Cómo funciona
- red: gitea.network y proxy.network
- volúmenes: host paths %h/.config/gitea/... y %h/.config/gitea/... dentro de los contenedores
- secretos: gitea_db_password (tipo env, target POSTGRES_PASSWORD)
- EnvironmentFile: ninguno
- socket del daemon: ninguno
- healthcheck: ninguno
- Traefik enrutado: router "gitea" sobre Host(`gitea.${FQDN}`) con entrada websecure
- User/UserNS/NoNewPrivileges: no se especifica, se ejecuta como root

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| USER_UID | Environment= | 1000 | |
| USER_GID | Environment= | 1000 | |
| GITEA__database__DB_TYPE | Environment= | postgres | |
| GITEA__database__HOST | Environment= | gitea-db:5432 | |
| GITEA__database__NAME | Environment= | gitea | |
| GITEA__database__USER | Environment= | gitea | |
| GITEA__repository__DEFAULT_BRANCH | Environment= | main | |
| GITEA__repository__ENABLE_PUSH_CREATE_ORG | Environment= | true | |
| GITEA__server__OFFLINE_MODE | Environment= | true | |
| GITEA__server__DOMAIN | Environment= | ${FQDN} | |
| GITEA__server__SSH_DOMAIN | Environment= | ${FQDN} | |
| GITEA__server__ROOT_URL | Environment= | https://gitea.${FQDN} | |
| GITEA__server__DISABLE_SSH | Environment= | false | |
| GITEA__server__SSH_PORT | Environment= | 2222 | |
| GITEA__server__SSH_LISTEN_PORT | Environment= | 22 | |
| GITEA__service__DISABLE_REGISTRATION | Environment= | true | |
| GITEA__service__REQUIRE_SIGNIN_VIEW | Environment= | true | |
| GITEA__service__DEFAULT_ALLOW_CREATE_ORGANIZATION | Environment= | false | |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store): `printf '%s' '<valor>' | podman secret create <nombre> -`
2. `cd /data/self-hosted-podman/.config/containers/available/gitea && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)