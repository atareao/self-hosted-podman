# firefly — Firefly III es un gestor de finanzas personales

## Qué es
App: Firefly III (web), cron y MariaDB
Imagen(es):
- web: docker.io/fireflyiii/core:latest
- croni: docker.io/atareao/croni:v1.1
- mariadb: docker.io/yobasystems/alpine-mariadb:latest
Nº contenedores: 3
Red(s): proxy.network, firefly.network
Dominio: subdominio `firefly.${FQDN}`
Puerto interno: 8080 (web)

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/firefly/firefly.container
  - /data/self-hosted-podman/.config/containers/available/firefly/firefly-croni.container
  - /data/self-hosted-podman/.config/containers/available/firefly/firefly-mariadb.container
- Volumen(es):
- Config no secreta:
- Secretos:
  - firefly_mysql_random_root_password
  - firefly_mysql_password

## Cómo funciona
Red proxy.network (proxy) y firefly.network (interno). Volúmenes bind mounts a host: upload, db. Socket del daemon (none). Healthcheck (none). Enrutado Traefik a puerto 8080. User/UserNS/NoNewPrivileges: none.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| MYSQL_USER | firefly-mariadb.container | firefly | Usuario DB |
| MYSQL_DATABASE | firefly-mariadb.container | firefly | Base de datos |
| | | | |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store):
  - `printf '%s' '<valor>' | podman secret create firefly_mysql_random_root_password -`
  - `printf '%s' '<valor>' | podman secret create firefly_mysql_password -`
2. `cd .config/containers/available/firefly && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)