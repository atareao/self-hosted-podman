# jellystat — Monitor de Jellyfin

## Qué es
Aplicación de monitorización Jellystat para backend de Jellyfin.
- Imagen principal: docker.io/cyfershepard/jellystat:latest
- Número de contenedores: 2
- Red(es) usadas: proxy.network, jellystat.network
- Dominio(s): jellystat.${FQDN}
- Puerto interno: 3000

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/jellystat/jellystat.container, /data/self-hosted-podman/.config/containers/available/jellystat/jellystat-db.container, /data/self-hosted-podman/.config/containers/available/jellystat/jellystat.network, /data/self-hosted-podman/.config/containers/available/jellystat/jellystat-backup-data.volume, /data/self-hosted-podman/.config/containers/available/jellystat/jellystat-postgres-data.volume
- Volumen(es): /data/self-hosted-podman/.config/containers/available/jellystat/jellystat-backup-data.volume, /data/self-hosted-podman/.config/containers/available/jellystat/jellystat-postgres-data.volume
- Config no secreta: N/A
- Secretos: jellystat_postgres_password, jellystat_jwt_secret

## Cómo funciona
Conecta a proxy.network y jellystat.network, volúmenes back‑up y base de datos, secrets via podman secret, EnvironmentFile no usado, socket del daemon (none), healthcheck none, enrutamiento Traefik con TLS, User/NoNewPrivileges not set.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| POSTGRES_USER | Environment= | postgres | Nombre de usuario de DB |
| POSTGRES_IP | Environment= | jellystat-db | Host interno del DB |
| POSTGRES_PORT | Environment= | 5432 | Puerto del DB |

## Cómo habilitar / desplegar
1. Secretos (si existen; NUNCA crypta store):
   - `printf '%s' '<valor>' | podman secret create jellystat_postgres_password -`
   - `printf '%s' '<valor>' | podman secret create jellystat_jwt_secret -`
2. `cd .config/containers/available/jellystat && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)