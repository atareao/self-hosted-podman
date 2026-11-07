# planka — Aplicación de gestión de tableros Kanban basada en Docker

## Qué es
Planka, basado en la imagen `ghcr.io/plankanban/planka:latest`. Número de contenedores: 2 (planka y planka-postgresql). Red(es): `proxy.network`, `planka.network`. Dominio(s): `planka.${FQDN}` subdominio (label `traefik.http.routers.planka.rule`). Puerto interno: 1337 (label `traefik.http.services.planka.loadbalancer.server.port`).

## Ficheros
- Quadlet(s):
  - `/data/self-hosted-podman/planka.container`
  - `/data/self-hosted-podman/planka-postgresql.container`
- Volumen(es):
  - `/data/self-hosted-podman/planka-db-data.volume`
  - `/data/self-hosted-podman/planka-attachments.volume`
  - `/data/self-hosted-podman/planka-project-background-images.volume`
  - `/data/self-hosted-podman/planka-user-avatars.volume`
- Config no secreta: (no dispone de .env)
- Secretos:
  - planka_secret_key

## Cómo funciona
Utiliza la red `proxy.network` para la exposición a Traefik y la red `planka.network` para comunicación interna. Los volúmenes persisten los datos de la base de datos y archivos de usuario. La variable de entorno `BASE_URL` apunta a `http://planka.${FQDN}` y `DATABASE_URL` referencia a la base de datos PostgreSQL. La unidad se ejecuta como usuario no root y con `Restart=always`. Traefik enruta el tráfico a través del puerto interno 1337. No requiere puertos expuestos directamente.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| BASE_URL | Environment | `"http://planka.${FQDN}"` | URL base de la aplicación |
| TRUST_PROXY | Environment | `0` | Desactiva proxy de confianza |
| DATABASE_URL | Environment | `postgresql://postgres@postgres/planka` | Cadena de conexión a PostgreSQL |

## Cómo habilitar / desplegar
1. Secretos (solo si existen):
   ```bash
   printf '%s' '<valor>' | podman secret create planka_secret_key -
   ```
2. `cd .config/containers/available/planka && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
