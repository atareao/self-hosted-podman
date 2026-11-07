# bookstack — documentación Markdown alojada

## Qué es
- Aplicación: documentación Markdown alojada
- Imagen: `lscr.io/linuxserver/bookstack`
- Contenedores: 2 (bookstack + bookstack-mariadb)
- Red: `proxy.network`
- Dominio: `bookstack.${FQDN}`
- Puerto interno: 80

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/bookstack/bookstack.container
  - /data/self-hosted-podman/.config/containers/available/bookstack/bookstack-mariadb.container
- Volumen(es): (ninguno)
- Config no secreta: (ninguna)
- Secretos:
  - `bookstack_db_pass`
  - `bookstack_mysql_root_password`
  - `bookstack_mysql_password`

## Cómo funciona
- Se conecta a la red `proxy.network` y se expone vía Traefik en `bookstack.${FQDN}`.
- Los datos de la aplicación se guardan en el bind `/config` dentro del contenedor.
- La base de datos MariaDB monta el volumen de configuración dentro del contenedor de MariaDB.
- Healthcheck no definido en el quadlet.
- El contenedor principal no corre como root, usa UID/GID no privilegiado.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| PUID | Environment= | 1000 | UID del usuario de la aplicación |
| PGID | Environment= | 1000 | GID del grupo de la aplicación |
| APP_URL | Environment= | `https://bookstack.${FQDN}` | URL pública del servicio |
| DB_HOST | Environment= | `bookstack_db` | Host de la BD |
| DB_USER | Environment= | `bookstack` | Usuario DB |
| DB_DATABASE | Environment= | `bookstackapp` | Base de datos |

## Cómo habilitar / desplegar
1. Secretos (si existen):
   - `printf '%s' '\u003cvalor\u003e' | podman secret create bookstack_db_pass -`
   - `printf '%s' '\u003cvalor\u003e' | podman secret create bookstack_mysql_root_password -`
   - `printf '%s' '\u003cvalor\u003e' | podman secret create bookstack_mysql_password -`
2. `cd .config/containers/available/bookstack && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
