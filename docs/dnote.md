# dnote — Gestor de notas multiusuario

## Qué es
**Aplicación**: dnote (image: `docker.io/dnote/dnote:latest`)
**Número de contenedores**: 2
**Red**: `proxy.network` (entrada Traefik) y `dnote.network` (interna app ↔ postgres). El contenedor `dnote` se une a **ambas**; `dnote-postgres` solo a `dnote.network`.
**Dominio**: `dnote.${FQDN}`
**Puerto interno**: `3001`

## Ficheros
- Quadlet(s):
  - `/data/self-hosted-podman/.config/containers/available/dnote/dnote.container`
  - `/data/self-hosted-podman/.config/containers/available/dnote/dnote-postgres.container`
- Volumen(es):
  - **No existe ningún quadlet `.volume`** para esta stack. Los datos de PostgreSQL persisten en un **bind de host** definido directamente en `dnote-postgres.container`:
    `Volume=%h/.config/dnote/dnote_data:/var/lib/postgresql/data:Z`
    (el directorio host `~/.config/dnote/dnote_data` debe existir/estar backed up; no hay `dnote-postgres.data-volume`).
- Config no secreta: —
- Secretos:
  - `dnote_postgres_password` (**único** secreto de contraseña de BD; se comparte entre app y PostgreSQL)

## Cómo funciona
- Redes: `dnote` en `proxy.network` (lo alcanza Traefik) y en `dnote.network` para hablar con la BD. `dnote-postgres` está en `dnote.network` con alias `postgres`, que es justo el valor de `DBHost=postgres` de la app.
- Orden de arranque: `dnote` declara `After=... dnote-postgres.service` y `Requires=dnote-postgres.service`; `dnote-postgres` solo `After=network-online.target`.
- Volúmenes: datos de PostgreSQL en el bind `%h/.config/dnote/dnote_data` (ver arriba), montado en `/var/lib/postgresql/data`.
- Secretos: **un solo** secreto `dnote_postgres_password`, inyectado con `type=env` en dos targets distintos del mismo valor:
  - `dnote` → `DBPassword`
  - `dnote-postgres` → `POSTGRES_PASSWORD`
  Así la contraseña de la app y la de la BD nunca se desincronizan.
- Healthcheck: no
- Enrutado Traefik: reglas en las Labels
  - **Puerto real de la app: 3001.** El contenedor `docker.io/dnote/dnote:latest` (v3.0.0) arranca migrando la BD y su log lo confirma: `{"msg":"Dnote server starting","port":"3001",...}`. El label `traefik.http.services.dnote.loadbalancer.server.port` apuntaba a `3000`, por lo que Traefik enviaba el tráfico a un puerto sin escucha y `https://dnote.${FQDN}` devolvía **502**.
  - **Fix aplicado**: label Traefik `3000` → `3001` en `dnote.container`, para que coincida con el puerto interno real. No se cambia nada más en el quadlet.
- User/UserNS/NoNewPrivileges: no especificado

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `GO_ENV` | Environment | `PRODUCTION` | Entorno de ejecución |
| `DBSkipSSL` | Environment | `true` | Desactiva SSL en BD |
| `DBHost` | Environment | `postgres` | Host de BD |
| `DBPort` | Environment | `5432` | Puerto de BD |
| `DBName` | Environment | `dnote` | Nombre de BD |
| `DBUser` | Environment | `dnote` | Usuario BD |
| `WebURL` | Environment | `https://dnote.${FQDN}` | URL pública |
| `OnPremise` | Environment | `true` | Alojamiento local |
| `SmtpHost` | Environment | `` | SMTP host |
| `SmtpPort` | Environment | `` | SMTP port |
| `SmtpUsername` | Environment | `` | SMTP username |
| `SmtpPassword` | Environment | `` | SMTP password |
| `DisableRegistration` | Environment | `false` | Permitir registro |
| `DBPassword` | `Secret=dnote_postgres_password` (`type=env`) | *(secreto)* | Contraseña de la app para PostgreSQL |
| `POSTGRES_USER` | Environment (postgres) | `dnote` | Usuario BD |
| `POSTGRES_DB` | Environment (postgres) | `dnote` | BD nombre |
| `POSTGRES_PASSWORD` | `Secret=dnote_postgres_password` (`type=env`, postgres) | *(secreto)* | Contraseña de la BD (mismo secreto que `DBPassword`) |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store). Hay **un único** secreto, compartido por app y BD:
   `printf '%s' '<valor>' | podman secret create dnote_postgres_password -`
2. `cd .config/containers/available/dnote && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- **PostgreSQL 11 EOL**: `dnote-postgres` usa `docker.io/library/postgres:11-alpine` (rama 11 sin soporte desde nov-2023). Se ha fijado el tag tal cual (no se sube a ciegas) y se le ha añadido `AutoUpdate=registry` para el día que se decida migrar. dnote **no está probado con PostgreSQL moderno**: antes de subir de versión hay que hacer un dump/restore y validar la app. No cambiar el tag sin pruebas.
- El bind de datos `~/.config/dnote/dnote_data` no tiene backup automatizado propio; incluirlo en la política de copias.
- **Verificado E2E el 2026-11-11 (PLAN-031 / issue #26)**: HTTP final 302 (`https://dnote.${FQDN}`); **purgado** tras la verificación.