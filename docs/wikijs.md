# wikijs — Wiki de conocimiento basada en Markdown

## Qué es
wikijs, ghcr.io/requarks/wiki:2, 2 contenedores, redes: proxy.network, wikijs.network, dominio: wikijs.${FQDN}, puerto interno: 80

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/wikijs/wikijs.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/wikijs/wikijs-postgresql.container
- Volumen(es): N/A
- Config no secreta: N/A
- Secretos: wikijs_postgres_password, wikijs_db_pass

## Cómo funciona
- Red: proxy.network y wikijs.network vinculadas a los contenedores
- Volúmenes: N/A (se usan bind mounts)
- Secretos: wikijs_postgres_password se inyecta en POSTGRES_PASSWORD, wikijs_db_pass en DB_PASS
- EnvironmentFile: N/A
- Socket del daemon: N/A
- Healthcheck: N/A
- Enrutado Traefik: Host wikijs.${FQDN} apunta al servicio 80
- User/UserNS/NoNewPrivileges: N/A

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|-----|-------|-------|-------------|
| POSTGRES_DB | wikijs.container | wiki | 
| POSTGRES_USER | wikijs.container | wikijs | 
| DB_TYPE | wikijs.container | postgres | 
| DB_HOST | wikijs.container | postgres | Alias de red real del contenedor PostgreSQL | 
| DB_PORT | wikijs.container | 5432 | 
| DB_USER | wikijs.container | wikijs | 
| DB_NAME | wikijs.container | wiki | 
| WS_POSTGRES_DB | wikijs-postgresql.container | wiki | 
| WS_POSTGRES_USER | wikijs-postgresql.container | wikijs | 
| DB_DB_TYPE | wikijs-postgresql.container | postgres | 
| DB_HOST | wikijs-postgresql.container | postgres | Alias de red real (`NetworkAlias=postgres`) | 
| DB_PORT | wikijs-postgresql.container | 5432 | 
| DB_USER | wikijs-postgresql.container | wikijs | 
| DB_NAME | wikijs-postgresql.container | wiki | |

## Cómo habilitar / desplegar
1. Secretos: `printf '%s' '<valor>' | podman secret create wikijs_postgres_password -`
`printf '%s' '<valor>' | podman secret create wikijs_db_pass -`
2. `cd .config/containers/available/wikijs && qctl install`
3. `systemctl --user daemon-reload`

El bind del PostgreSQL (`~/.config/wikijs/data` → `/var/lib/postgresql/data`) debe pertenecer al uid 70
(usuario `postgres` de la imagen `postgres:14-alpine`); si el contenedor arranca en bucle con
`chmod: changing permissions of '/var/lib/postgresql/data': Operation not permitted`, ejecutar:

```bash
podman unshare chown -R 70:70 ~/.config/wikijs/data
```

## Follow-ups
- Verificado E2E el 2026-11-11 (PLAN-030, issue #25): corregido `DB_HOST` (`db` → `postgres`, alias real del contenedor PostgreSQL); el bind `~/.config/wikijs/data` debe pertenecer a uid 70 (`podman unshare chown -R 70:70`).
