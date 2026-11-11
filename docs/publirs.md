# publirs — Servicio de publicación de contenido

## Qué es
- **App**: publirs
- **Imagen**: docker.io/atareao/publirs:latest
- **Nº contenedores**: 2 (publirs, publirs-croni)
- **Red**: `publirs.network` (alias `publirs` y `croni`) + `proxy.network` (para Traefik)
- **Dominio**: `publirs.${FQDN}` (Traefik, router seguro)
- **Puerto interno**: `8080` (Traefik `loadbalancer.server.port=8080`)

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/publirs/publirs.container, /data/self-hosted-podman/.config/containers/available/publirs/publirs-croni.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/publirs/publirs-db.volume
- Config no secreta: ninguno
- Secretos: publirs_token

## Cómo funciona
- **Red**: `publirs.network` (comunicación `publirs` ↔ `publirs-croni`) + `proxy.network` (con `NetworkAlias=publirs`) para que Traefik alcance el contenedor
- **Volúmenes**: publirs-db.volume -> /app/db
- **Secretos**: publirs_token (→ `TOKEN` **solo** en `publirs`; croni no lo necesita, ver follow-ups)
- **Healthcheck**: ninguno
- **Routing Traefik**: `Host(\`publirs.${FQDN}\`)`, `entrypoints=websecure`, `tls.certresolver=letsencrypt`, middlewares `seguridadHeaders@file,compresionHeaders@file`; servicio `publirs` → puerto `8080`
- **User/UserNS/NoNewPrivileges**: ninguno

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| LOG_LEVEL | Environment | debug | nivel de log |
| DB_URL | Environment | sqlite:/app/db/publirs.db | URL de la BD (ruta **absoluta**; sqlx 0.6 la parsea tal cual → `/app/db/publirs.db`, dentro del volumen `publirs-db`) |
| PORT | Environment | 8080 | Puerto interno |
| ENVIRONMENT | Environment | PRODUCTION | entorno |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store): `printf '%s' '<valor>' | podman secret create publirs_token -`
2. `cd .config/containers/available/publirs && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- **Enrutado por Traefik**: servido en `publirs.${FQDN}` (puerto interno `8080`). Requiere `publirs_token` creado con `podman secret create` **antes** de arrancar.
- **`DB_URL` verificado**: el origen (`atareao/self-hosted/publirs/compose.yml`) usa exactamente `sqlite:/app/db/publirs.db`, y sqlx 0.6 (`SqliteConnectOptions::from_str`) toma todo lo que sigue a `sqlite:` como *filename* (al empezar por `/` es ruta absoluta) → `/app/db/publirs.db`. No se cambia.
- **croni sin `TOKEN`**: `publirs-croni` no necesita el secreto. Los endpoints que llama el crontab (`/api/v1/status`, `/api/v1/publish_tip`, `/api/v1/publish_poll`) son GET **sin autenticación**; el `TOKEN` solo lo usa la app para hablar con la API de Telegram.
- **croni sin `crontab.txt`**: el `compose.yml` original le inyecta un `crontab.txt` con las tres llamadas `curl` (vía `configs:`), pero el quadlet actual **no lo monta** → croni arranca sin tareas programadas. Pendiente decidir si se versiona `.config/publirs/crontab.txt` y se añade el bind.
- Sin healthcheck ni hardening (`ReadOnly`, `NoNewPrivileges`, `User`/`Group`); evaluar añadirlos (la imagen corre como uid 10001).
- El volumen `publirs-db` se monta en `/app/db`; si la app no puede escribir la BD, revisar el *ownership* del volumen (uid 10001).