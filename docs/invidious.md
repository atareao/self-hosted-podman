# invidious — Front‑end de YouTube

## Qué es
Aplicación invidious para ver videos de YouTube.
- Imagen principal: docker.io/sriegler/invidious-auth:latest
- Número de contenedores: 2
- Red(es) usadas: proxy.network, invidious.network
- Dominio(s): invidious.${FQDN}
- Puerto interno: 3000 (traefik.http.services.invidious.loadbalancer.server.port)

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/invidious/invidious.container, /data/self-hosted-podman/.config/containers/available/invidious/invidious.network, /data/self-hosted-podman/.config/containers/available/invidious/invidious-postgresql.container, /data/self-hosted-podman/.config/containers/available/invidious/invidious-postgresdata.volume
- Volumen(es): /data/self-hosted-podman/.config/containers/available/invidious/invidious-postgresdata.volume
- Config no secreta: N/A
- Secretos: invidious_postgres_password

## Cómo funciona
Red proxy.network + invidious.network, volumen invidious-postgresdata para datos del Postgres, secretos via podman secret, EnvironmentFile no usado, socket del daemon (none), healthcheck no definido, enrutamiento Traefik con TLS, User/NoNewPrivileges not set (runs as root by default).

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| INVIDIOUS_CONFIG | Environment= | "{admins: [], captcha_enabled: false, channel_threads: 1, check_tables: true, db: {dbname: invidious, host: postgres, password: kemal, port: 5432, user: kemal}, disable_proxy: false, domain: 'invidious.${FQDN}', external_port: 443, feed_threads: 1, full_refresh: false, geo_bypass: false, https_only: false, popular_enabled: false, registration_enabled: false, statistics_enabled: false}" | Config global de Invidious |

## Cómo habilitar / desplegar
1. Secretos (si existen; NUNCA crypta store): `printf '%s' '<valor>' | podman secret create invidious_postgres_password -`
2. `cd .config/containers/available/invidious && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)