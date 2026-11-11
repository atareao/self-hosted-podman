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
- **Volúmenes**: publirs-db.volume -> /app/db; `publirs-croni` monta `%h/.config/publirs/crontab.txt:/crontab.txt:ro,Z` y `/etc/localtime:/etc/localtime:ro`. **No** monta `/etc/timezone`: ese fichero no existe en el host y el bind impedía arrancar el contenedor (`Error: statfs /etc/timezone: no such file or directory`); la TZ ya la cubre `/etc/localtime`.
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
- **`/etc/timezone` eliminado**: el bind `Volume=/etc/timezone:/etc/timezone:ro` hacía fallar el arranque de `publirs-croni` (`statfs /etc/timezone: no such file or directory`, fichero inexistente en el host). Se eliminó solo ese bind; `/etc/localtime` y el del `crontab.txt` se mantienen. Si en el futuro se necesita forzar TZ, la vía correcta en este repo es una variable `TZ` (en `.config/publirs/` o `Environment=` del quadlet), no un bind a un fichero inexistente.
- **`publirs_token` es un placeholder**: se creó con un valor de relleno (no hay token real de Telegram), así que **el envío a Telegram no se verificó**; queda pendiente sustituirlo por el token real.
- **Crontab GET vs POST (follow-up, pregunta abierta)**: las tareas `publish_tip` / `publish_poll` del `crontab.txt` (heredado del `compose.yml` de origen) se invocan por **GET** y la API responde **404/405**, lo que apunta a que el método correcto es **POST**. Por eso esos dos jobs fallarán. **No se cambia el crontab** (es el contenido autoritativo del `compose.yml` de origen); queda como follow-up confirmar el método/endpoint correcto.
- **Enrutado por Traefik**: servido en `publirs.${FQDN}` (puerto interno `8080`). Requiere `publirs_token` creado con `podman secret create` **antes** de arrancar.
- **`DB_URL` verificado**: el origen (`atareao/self-hosted/publirs/compose.yml`) usa exactamente `sqlite:/app/db/publirs.db`, y sqlx 0.6 (`SqliteConnectOptions::from_str`) toma todo lo que sigue a `sqlite:` como *filename* (al empezar por `/` es ruta absoluta) → `/app/db/publirs.db`. No se cambia.
- **croni sin `TOKEN`**: `publirs-croni` no necesita el secreto. Los endpoints que llama el crontab (`/api/v1/status`, `/api/v1/publish_tip`, `/api/v1/publish_poll`) son GET **sin autenticación**; el `TOKEN` solo lo usa la app para hablar con la API de Telegram.
- **`crontab.txt` montado**: el `compose.yml` original inyecta un `crontab.txt` (vía `configs:`); el quadlet lo monta en `/crontab.txt` desde `.config/publirs/crontab.txt` (ver el follow-up de GET/POST).
- Sin healthcheck ni hardening (`ReadOnly`, `NoNewPrivileges`, `User`/`Group`); evaluar añadirlos (la imagen corre como uid 10001).
- El volumen `publirs-db` se monta en `/app/db`; si la app no puede escribir la BD, revisar el *ownership* del volumen (uid 10001).