# dnote — Gestor de notas multiusuario

## Qué es
**Aplicación**: dnote (image: `docker.io/dnote/dnote:latest`)
**Número de contenedores**: 2
**Red**: `proxy.network` (dnote) y `dnote.network` (postgres)
**Dominio**: `dnote.${FQDN}`
**Puerto interno**: `3000`

## Ficheros
- Quadlet(s):
  - `/data/self-hosted-podman/.config/containers/available/dnote/dnote.container`
  - `/data/self-hosted-podman/.config/containers/available/dnote/dnote-postgres.container`
- Volumen(es):
  - `/data/self-hosted-podman/.config/containers/available/dnote/dnote-postgres.data-volume`  *(ruta de bind: `%h/.config/dnote/dnote_data:/var/lib/postgresql/data:Z`)*
- Config no secreta: —
- Secretos:
  - `dnote_postgres_password`

## Cómo funciona
- Red `proxy.network` (dnote) y `dnote.network` (postgres)
- Volúmenes: datos de PostgreSQL en `%h/.config/dnote/dnote_data`
- Secretos: `dnote_postgres_password` (env target `POSTGRES_PASSWORD`)
- Healthcheck: no
- Enrutado Traefik: reglas en las Labels
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
| `POSTGRES_USER` | Environment (postgres) | `dnote` | Usuario BD |
| `POSTGRES_DB` | Environment (postgres) | `dnote` | BD nombre |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store): `printf '%s' '<valor>' | podman secret create dnote_postgres_password -`
2. `cd .config/containers/available/dnote && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)