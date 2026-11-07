# snibox — Gestor self-hosted de snippets de código

## Qué es

Snibox es una aplicación web para guardar y organizar fragmentos de código (snippets), escrita en Ruby on Rails. En este repo se despliega con **3 contenedores**:

| Contenedor (`ContainerName=`) | Imagen (`Image=`) | Rol |
|---|---|---|
| `snibox` | `docker.io/snibox/nginx-puma:1.15.9` | nginx que sirve los estáticos y hace de entrada HTTP (punto de entrada de Traefik) |
| `snibox-backend` | `docker.io/snibox/snibox:latest` | Aplicación Rails/Puma, escucha en `3000` (`-p 3000 -b 0.0.0.0`) |
| `snibox-postgresql` | `docker.io/library/postgres:10.7-alpine` | Base de datos PostgreSQL 10.7 |

- **Red(es):** `snibox.network` (interna del stack: backend ↔ PostgreSQL, alias `backend` y `database`) y `proxy.network` (solo el contenedor `snibox`, alias `snibox`).
- **Dominio:** `snibox.${FQDN}` → **subdominio** `snibox` (router Traefik `snibox`).
- **Puerto interno (Traefik):** `80` (`traefik.http.services.snibox.loadbalancer.server.port=80`).
- No hay `PublishPort`: nada se expone directamente al host; el acceso es solo vía Traefik.

## Ficheros

- Quadlet(s):
  - `.config/containers/available/snibox/snibox.container`
  - `.config/containers/available/snibox/snibox-backend.container`
  - `.config/containers/available/snibox/snibox-postgresql.container`
- Volumen(es):
  - `.config/containers/available/snibox/snibox-static-files.volume`
  - `.config/containers/available/snibox/snibox-pg-data.volume`
- Red(es): `.config/containers/available/snibox/snibox.network` (+ `proxy.network`, definida en el stack `traefik`)
- Config no secreta: no existe `.env` de stack (no hay `.config/snibox/`).
- Secretos: `snibox_db_pass`, `snibox_mailgun_smtp_password`, `snibox_mailgun_api_key`, `snibox_mailgun_public_key`, `snibox_secret_key_base`.

## Cómo funciona

- **Redes:** el stack define su propia red `snibox` (`snibox.network`, `NetworkName=snibox`) para la comunicación interna. Solo el contenedor `snibox` se une además a `proxy.network` (la red edge de Traefik), de forma que Traefik puede alcanzarlo y el backend/BD quedan aislados del exterior.
- **Enrutado Traefik:** el contenedor `snibox` declara `traefik.enable=true`, servicio `snibox` con puerto `80`, router `snibox` con `Host(\`snibox.${FQDN}\`)`, entrypoint `websecure`, `certresolver=letsencrypt` y los middlewares `seguridadHeaders@file,compresionHeaders@file`.
- **Volúmenes:** `snibox-static-files.volume` se monta compartido entre `snibox` (`/var/www/html`) y `snibox-backend` (`/app/public`), de modo que Rails genera los assets y nginx los sirve. `snibox-pg-data.volume` persiste los datos de PostgreSQL en `/var/lib/postgresql/data`.
- **Secretos:** los 5 secretos se inyectan como variables de entorno con `Secret=<nombre>,type=env,target=<VAR>` (driver `crypta`, configurado en `containers.conf`). No hay `EnvironmentFile`: toda la config no secreta va como `Environment=` en el quadlet.
- **Orden de arranque:** `snibox-backend` y `snibox-postgresql` solo declaran `After=network-online.target`; `snibox` añade `After=... traefik.service`. No hay `Requires=` entre contenedores.
- **Healthcheck:** ninguno de los tres contenedores define `Health*`.
- **Hardening:** ninguna sección `Hardening` está poblada (sin `User`, sin `NoNewPrivileges`, sin `ReadOnly`).
- **AutoUpdate:** solo `snibox-backend` (`AutoUpdate=registry`); nginx y PostgreSQL quedan con tag fijo (`1.15.9`, `10.7-alpine`) sin auto-actualización.
- **Arranque:** `Restart=always`, `RestartSec=10s`, `StartLimitIntervalSec=300`, `StartLimitBurst=3`, `TimeoutStartSec=60`, `WantedBy=default.target`.

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `DB_NAME` | `snibox-backend.container` (`Environment=`) | `postgres` | Nombre de la base de datos |
| `DB_USER` | `snibox-backend.container` (`Environment=`) | `postgres` | Usuario de PostgreSQL |
| `DB_HOST` | `snibox-backend.container` (`Environment=`) | `database` | Host de la BD (alias de red de `snibox-postgresql`) |
| `DB_PORT` | `snibox-backend.container` (`Environment=`) | `5432` | Puerto de PostgreSQL |
| `FORCE_SSL` | `snibox-backend.container` (`Environment=`) | `false` | Forzar SSL en la app (el TLS lo termina Traefik) |
| `MAILGUN_SMTP_PORT` | `snibox-backend.container` (`Environment=`) | `587` | Puerto SMTP de Mailgun |
| `MAILGUN_SMTP_SERVER` | `snibox-backend.container` (`Environment=`) | `smtp.mailgun.org` | Servidor SMTP de Mailgun |
| `MAILGUN_SMTP_LOGIN` | `snibox-backend.container` (`Environment=`) | *(vacío)* | Login SMTP de Mailgun |
| `MAILGUN_DOMAIN` | `snibox-backend.container` (`Environment=`) | *(vacío)* | Dominio de Mailgun |
| `DB_PASS` | `snibox-backend.container` (`Secret=snibox_db_pass`) | *(secreto)* | Password de PostgreSQL |
| `MAILGUN_SMTP_PASSWORD` | `snibox-backend.container` (`Secret=snibox_mailgun_smtp_password`) | *(secreto)* | Password SMTP de Mailgun |
| `MAILGUN_API_KEY` | `snibox-backend.container` (`Secret=snibox_mailgun_api_key`) | *(secreto)* | API key de Mailgun |
| `MAILGUN_PUBLIC_KEY` | `snibox-backend.container` (`Secret=snibox_mailgun_public_key`) | *(secreto)* | Clave pública de Mailgun |
| `SECRET_KEY_BASE` | `snibox-backend.container` (`Secret=snibox_secret_key_base`) | *(secreto)* | Clave de firma de sesiones de Rails |
| `FQDN` | `snibox.container` (label `traefik.http.routers.snibox.rule`) | *(inyectada por systemd desde `~/.config/environment.d/fqdn.conf`)* | Dominio raíz del host; el stack usa el subdominio `snibox.${FQDN}` |

No hay `.env` de stack para este servicio.

## Cómo habilitar / desplegar

1. Crear los secretos (con `podman secret create`, **nunca** `crypta store`):

```bash
printf '%s' '<valor>' | podman secret create snibox_db_pass -
printf '%s' '<valor>' | podman secret create snibox_mailgun_smtp_password -
printf '%s' '<valor>' | podman secret create snibox_mailgun_api_key -
printf '%s' '<valor>' | podman secret create snibox_mailgun_public_key -
printf '%s' '<valor>' | podman secret create snibox_secret_key_base -
```

2. `cd .config/containers/available/snibox && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups

- No hay `After=`/`Requires=` del backend sobre `snibox-postgresql.container`: el backend puede arrancar antes de que la BD esté lista (Rails reintentará la conexión).
- `MAILGUN_SMTP_LOGIN` y `MAILGUN_DOMAIN` están vacíos en el quadlet; el envío de correo no funcionará hasta rellenarlos.
- Imágenes antiguas: `nginx-puma:1.15.9` y `postgres:10.7-alpine` están fijadas a versiones EOL; no tienen `AutoUpdate`.
- Sin healthchecks ni hardening (`User`, `NoNewPrivileges`, `ReadOnly`) en ninguno de los tres contenedores.
