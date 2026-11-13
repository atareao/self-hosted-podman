# planka — Aplicación de gestión de tableros Kanban basada en Docker

## Qué es
Planka, basado en la imagen `ghcr.io/plankanban/planka:latest`. Número de contenedores: 2 (planka y planka-postgresql). Red(es): `proxy.network`, `planka.network`. Dominio(s): `planka.${FQDN}` subdominio (label `traefik.http.routers.planka.rule`). Puerto interno: 1337 (label `traefik.http.services.planka.loadbalancer.server.port`).

## Ficheros
- Quadlet(s):
  - `/data/self-hosted-podman/.config/containers/available/planka/planka.container`
  - `/data/self-hosted-podman/.config/containers/available/planka/planka-postgresql.container`
- Volumen(es):
  - `/data/self-hosted-podman/.config/containers/available/planka/planka-db-data.volume`
  - `/data/self-hosted-podman/.config/containers/available/planka/planka-attachments.volume`
  - `/data/self-hosted-podman/.config/containers/available/planka/planka-project-background-images.volume`
  - `/data/self-hosted-podman/.config/containers/available/planka/planka-user-avatars.volume`
- Config no secreta: (no dispone de .env)
- Secretos:
  - planka_secret_key

## Cómo funciona
Utiliza la red `proxy.network` para la exposición a Traefik y la red `planka.network` para comunicación
interna: **app y PostgreSQL están ambas** en `planka.network` y la app declara `Requires=`/`After=` sobre
`planka-postgresql.service`. Los volúmenes persisten la base de datos y los archivos de usuario.
`BASE_URL` apunta a `https://planka.${FQDN}`, `TRUST_PROXY=true` (Traefik termina TLS y envía
`X-Forwarded-For`) y `DATABASE_URL` referencia a PostgreSQL. Traefik enruta el tráfico a través del puerto
interno 1337. No requiere puertos expuestos directamente.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| BASE_URL | Environment | `https://planka.${FQDN}` | URL base de la aplicación |
| TRUST_PROXY | Environment | `true` | Confía en el proxy de Traefik (IP real del cliente) |
| DATABASE_URL | Environment | `postgresql://postgres@postgres/planka` | Cadena de conexión a PostgreSQL |

## Cómo habilitar / desplegar
1. Secretos (solo si existen):
   ```bash
   printf '%s' '<valor>' | podman secret create planka_secret_key -
   ```
2. `cd .config/containers/available/planka && qctl install`
3. `systemctl --user daemon-reload`

## Verificación E2E (2026-11-13)

Verificado en producción (`new_atareao`, usuario `runner`) con certificado `letsencrypt-staging`
(purgado después):

1. Units `planka` y `planka-postgresql` → `active`.
2. Contenedores arrancados (`podman ps`).
3. Router `planka` registrado en Traefik.
4. Certificado staging válido para `planka.servidorlinux.es`.
5. `https://planka.servidorlinux.es` → **200**; `/api/config` responde JSON y la app queda conectada a PostgreSQL.

Bugs corregidos para llegar hasta aquí:

- La app **no estaba en `planka.network`** → `getaddrinfo EAI_AGAIN postgres`.
- No dependía de su BD → añadidos `Requires=`/`After=planka-postgresql.service`.
- `BASE_URL` era `http://` → debe ser `https://`.
- `TRUST_PROXY=0` rompía la IP real del cliente detrás de Traefik → `true`.

## Follow-ups
- `latest` + `AutoUpdate` en un stack cuyo salto 1.x→2.x cambia el esquema: **pinnear** la versión antes
  de que aparezca un major nuevo.
- `POSTGRES_HOST_AUTH_METHOD=trust` y `DATABASE_URL` sin contraseña son aceptables solo porque PostgreSQL
  únicamente es alcanzable desde `planka.network`; no exponer el puerto 5432.
