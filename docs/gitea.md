# gitea — Gitea - Self-hosted Git Service

## Qué es
- app: Gitea
- imagen: docker.io/gitea/gitea:1.19
- nº contenedores: 2
- red: gitea.network, proxy.network
- dominio: gitea.${FQDN} (`DOMAIN`, `SSH_DOMAIN` y `ROOT_URL` alineados con el router)
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
- red: gitea.network (BD) y proxy.network (borde Traefik)
- volúmenes: `gitea-data.volume` en `/data` y bind de solo lectura `/etc/localtime` (**no** se monta `/etc/timezone`: no existe en el host Arch y el bind fallaba)
- secretos: `gitea_db_password` (tipo env; target `GITEA__database__PASSWD` en la app y `POSTGRES_PASSWORD` en `gitea-db`)
- EnvironmentFile: ninguno
- socket del daemon: ninguno
- healthcheck: `curl -fsS http://127.0.0.1:3000/api/healthz` (30 s, 5 reintentos, `HealthStartPeriod=30s`)
- Traefik enrutado: router "gitea" sobre Host(`gitea.${FQDN}`) con entrada websecure
- trusted-proxy: `GITEA__security__REVERSE_PROXY_TRUSTED_PROXIES=10.89.0.0/24`; Traefik termina la conexión, así que sin esto Gitea no ve la IP real del cliente
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
| GITEA__server__DOMAIN | Environment= | gitea.${FQDN} | alineado con ROOT_URL y el router |
| GITEA__server__SSH_DOMAIN | Environment= | gitea.${FQDN} | |
| GITEA__server__ROOT_URL | Environment= | https://gitea.${FQDN} | |
| GITEA__server__DISABLE_SSH | Environment= | false | |
| GITEA__server__SSH_PORT | Environment= | 2222 | |
| GITEA__server__SSH_LISTEN_PORT | Environment= | 22 | |
| GITEA__service__DISABLE_REGISTRATION | Environment= | true | |
| GITEA__service__REQUIRE_SIGNIN_VIEW | Environment= | true | |
| GITEA__service__DEFAULT_ALLOW_CREATE_ORGANIZATION | Environment= | false | |
| GITEA__security__REVERSE_PROXY_TRUSTED_PROXIES | Environment= | 10.89.0.0/24 | subred de `proxy.network` (IP real del cliente) |

## Cómo habilitar / desplegar
1. Secretos (NUNCA `crypta store`): `printf '%s' '<valor>' | podman secret create gitea_db_password -` (el mismo valor que espera la BD `gitea-db`).
2. `cd /data/self-hosted-podman/.config/containers/available/gitea && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- **Bump del pin**: la imagen sigue en `gitea:1.19` (tarea A4 sin cerrar); evaluar el salto a una versión estable actual.
- **Cert LE**: `gitea.servidorlinux.es` verificado E2E con `letsencrypt-staging` (cert con `issuer=Let's Encrypt, CN=(STAGING) …`); el resolver de producción (`letsencrypt`) se deja configurado para cuando la cuota de LE lo permita (50 certs/168 h, agotada). Ver `docs/estado-verificacion-e2e.md`.