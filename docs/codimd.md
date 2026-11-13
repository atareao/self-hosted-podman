# codimd — editor de documentos colaborativos con PostgreSQL

## Qué es
*Imagen*:
- codimd: docker.io/hackmdio/hackmd:2.4.2-cjk
- codimd-postgresql: docker.io/library/postgres:17-alpine
*nº contenedores*: 2
*Red*: proxy.network, codimd.network
*Dominio*: Host(`codimd.${FQDN}`)
*Puerto interno*: 3000 (codimd)

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/codimd/codimd.container
  - /data/self-hosted-podman/.config/containers/available/codimd/codimd-postgresql.container
- Volumen(es):
  - /data/self-hosted-podman/.config/containers/available/codimd/codimd-uploads.volume
  - /data/self-hosted-podman/.config/containers/available/codimd/codimd-postgresql.volume
- Config no secreta: N/A
- Secretos: codimd_db_url, codimd_session_secret, codimd_postgres_password

## Cómo funciona
Red: proxy.network y la red interna codimd.network; app y BD están **ambas** en codimd.network (la app
resuelve `codimd-postgresql`). La app declara `Requires=`/`After=` sobre `codimd-postgresql.service`.

Volúmenes nombrados (antes binds a `~/.config/codimd/*`, que no existían): `codimd-uploads.volume` →
`/home/hackmd/app/public/uploads` y `codimd-postgresql.volume` → `/var/lib/postgresql/data`, ambos con `:U`.

Variables `CMD_*`: `CMD_DOMAIN=codimd.${FQDN}`, `CMD_PROTOCOL_USESSL=true`, `CMD_URL_ADDPORT=false`.
La conexión a la BD va por el secreto `codimd_db_url` → `CMD_DB_URL` (URL completa) y la sesión por
`codimd_session_secret` → `CMD_SESSION_SECRET`. Sin `CMD_DB_URL`, HackMD cae en Sequelize sin dialecto y muere.

Healthcheck: `pg_isready -U codimd -d codimd` en la BD.
Enrutado Traefik: Host(`codimd.${FQDN}`), puerto 3000, middleware seguridadHeaders@file, compresionHeaders@file.
User/UserNS/NoNewPrivileges: N/A

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| CMD_DOMAIN | Environment | `codimd.${FQDN}` | Dominio público de la app |
| CMD_PROTOCOL_USESSL | Environment | `true` | Fuerza HTTPS |
| CMD_URL_ADDPORT | Environment | `false` | No añadir puerto a las URLs |
| CMD_DB_URL | `Secret=codimd_db_url` | URL de PG | Conexión completa a PostgreSQL |
| CMD_SESSION_SECRET | `Secret=codimd_session_secret` | aleatorio | Firma de sesiones |
| POSTGRES_USER / POSTGRES_DB | Environment | `codimd` | Usuario y base de datos |
| POSTGRES_PASSWORD | `Secret=codimd_postgres_password` | aleatorio | Contraseña de PostgreSQL |
| POSTGRES_HOST_AUTH_METHOD | Environment | `md5` | Auth del host (cliente `pg` antiguo, ver follow-ups) |
| POSTGRES_INITDB_ARGS | Environment | `--auth-host=md5` | Inicializa el datadir con auth md5 |

## Cómo habilitar / desplegar
1. Secretos (nunca `crypta store`):
   ```bash
   PG_PASS="$(openssl rand -base64 24)"
   printf '%s' "$PG_PASS" | podman secret create codimd_postgres_password -
   printf '%s' "postgresql://codimd:${PG_PASS}@codimd-postgresql:5432/codimd" | podman secret create codimd_db_url -
   printf '%s' "$(openssl rand -base64 32)" | podman secret create codimd_session_secret -
   ```
   `codimd_db_url` se guarda **entera** y debe llevar la misma contraseña que `codimd_postgres_password`.
2. `cd .config/containers/available/codimd && qctl install`
3. `systemctl --user daemon-reload`

## Verificación E2E (2026-11-13)

Verificado en producción (`new_atareao`, usuario `runner`) con certificado `letsencrypt-staging`
(purgado después):

1. Unit `codimd` y `codimd-postgresql` → `active`.
2. Contenedores → `healthy`.
3. Router `codimd` registrado en Traefik.
4. Certificado staging válido para `codimd.servidorlinux.es`.
5. `https://codimd.servidorlinux.es` → **200**; tablas creadas en PostgreSQL (p. ej. `Users`).

Bugs corregidos para llegar hasta aquí:

- La app **no estaba en `codimd.network`**: no resolvía la BD.
- **Cero variables `CMD_*`** → sin `CMD_DB_URL`, HackMD cae en Sequelize sin dialecto y muere.
- `postgres:11.6-alpine` (EOL) sin `POSTGRES_PASSWORD` no inicializa → `postgres:17-alpine` + secreto.
- Comilla huérfana en el volumen (`data":Z`).
- Binds a `~/.config/codimd/*` inexistentes → volúmenes nombrados con `:U`.

**Hallazgo (PG17 + HackMD 2.4.2):** el cliente `pg` antiguo de HackMD 2.4.2 no soporta SCRAM y falla
con `Unknown authenticationOk message type ... length 23`. Se fuerza `POSTGRES_HOST_AUTH_METHOD=md5` +
`POSTGRES_INITDB_ARGS=--auth-host=md5`; válido **solo porque el datadir estaba vacío** (con datos habría
que resetear las contraseñas).

## Follow-ups
- HackMD `2.4.2` es antiguo y PostgreSQL 19 eliminará la autenticación `md5`: actualizar la imagen a una
  versión con cliente `pg` compatible con SCRAM antes de subir de major en la BD.
