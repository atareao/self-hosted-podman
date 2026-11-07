# glass-keep — glass-keep

## Qué es
- app: glass-keep
- imagen: docker.io/nikunjsingh/glass-keep:latest
- nº contenedores: 1
- red: proxy.network
- dominio: raíz ${FQDN}, subdominio keep.${FQDN}
- puerto interno: 8080

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/glass-keep/glass-keep.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/glass-keep/glass-keep-data.volume
- Config no secreta: /data/self-hosted-podman/.config/glass-keep/glass-keep.env
- Secretos:
  - glass_keep_jwt_secret

## Cómo funciona
- red: proxy.network
- volúmenes: host path %h/.config/glass-keep/... dentro de la aplicación
- secretos: glass_keep_jwt_secret (tipo env, target JWT_SECRET)
- EnvironmentFile: %h/.config/glass-keep/glass-keep.env y .env.local (si existe)
- socket del daemon: ninguno
- healthcheck: ninguno
- Traefik enrutado: router "keep" sobre Host(`keep.${FQDN}`) con entrada websecure
- User/UserNS/NoNewPrivileges: no se especifica, se ejecuta como root

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| ADMIN_EMAILS | EnvironmentFile | admin@example.com | |
| NODE_ENV | Environment= | production | |
| API_PORT | Environment= | 8080 | |
| DB_FILE | Environment= | /app/data/notes.db | |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store): `printf '%s' '<valor>' | podman secret create <nombre> -`
2. `cd /data/self-hosted-podman/.config/containers/available/glass-keep && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)