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
- Config no secreta: /data/self-hosted-podman/.config/jellystat/jellystat.env (POSTGRES_DB, POSTGRES_USER)
- Secretos: jellystat_postgres_password, jellystat_jwt_secret

## Cómo funciona
Conecta a proxy.network y jellystat.network, volúmenes back-up y base de datos, secrets via podman secret, EnvironmentFile .config/jellystat/jellystat.env, healthcheck: jellystat (`wget -q --spider http://127.0.0.1:3000/`) y PostgreSQL (`pg_isready -h 127.0.0.1 -U postgres`), enrutamiento Traefik con TLS, User/NoNewPrivileges not set.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| POSTGRES_DB | EnvironmentFile | jfstat | Nombre de la base de datos |
| POSTGRES_USER | EnvironmentFile | postgres | Nombre de usuario de DB |
| POSTGRES_IP | Environment | jellystat-db | Host interno del DB |
| POSTGRES_PORT | Environment | 5432 | Puerto del DB |

## Cómo habilitar / desplegar
1. Secretos (si existen; NUNCA crypta store):
   - `printf '%s' '<valor>' | podman secret create jellystat_postgres_password -`
   - `printf '%s' '<valor>' | podman secret create jellystat_jwt_secret -`
2. `cd .config/containers/available/jellystat && qctl install`
3. `systemctl --user daemon-reload`

## Verificación E2E (2026-11-12)

Verificado en producción (`new_atareao`, usuario `runner`) y después purgado:

1. Units `jellystat-db` y `jellystat` → `active`.
2. Contenedores `jellystat-db` y `jellystat` → `Up (healthy)`.
3. Router `jellystat` registrado en Traefik.
4. Certificado Let's Encrypt válido para `jellystat.${FQDN}`.
5. `https://jellystat.${FQDN}` → `200` (interfaz de Jellystat).

Bugs latentes corregidos para llegar hasta aquí:

- Faltaba la dependencia `Requires=`/`After=` de `jellystat` hacia `jellystat-db`.
- `POSTGRES_USER`/`POSTGRES_DB` se declaraban en `Environment=` sin `EnvironmentFile`; se movieron a `jellystat.env`.
- No había healthchecks en ninguno de los dos contenedores.

Purga: `qctl purge --secrets --images`. Sin restos.

## Follow-ups
- (ninguno)