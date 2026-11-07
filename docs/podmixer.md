# podmixer — Servidor de mezcla de podcasts y noticias RSS

## Qué es
Podmixer, basado en la imagen `docker.io/atareao/podmixer:v0.2.0`. Número de contenedores: 1 (podmixer). Red(es): `proxy.network`. Dominio(s): `podmixer.${FQDN}` subdominio (label `traefik.http.routers.podmixer2.rule`). Puerto interno: 3000 (label `traefik.http.services.podmixer2.loadbalancer.server.port`).

## Ficheros
- Quadlet(s):
  - `/data/self-hosted-podman/podmixer.container`
- Volumen(es):
  - `/data/self-hosted-podman/podmixer-db.volume`
  - `/data/self-hosted-podman/podmixer-rss.volume`
- Config no secreta: (no dispone de .env)
- Secretos:
  - podmixer_secret

## Cómo funciona
Utiliza la red `proxy.network` para la exposición a Traefik. Los volúmenes persisten la base de datos SQLite y las fuentes RSS. La variable de entorno `DB_URL` apunta a `/app/db/podmixer.db`. Se ejecuta como usuario no root con `Restart=always`. Traefik enruta el tráfico a través del puerto interno 3000.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| RUST_LOG | Environment | `info` | Nivel de logging de Rust |
| RUST_BACKTRACE | Environment | `full` | Stack trace completo en errores |
| RUST_ENV | Environment | `production` | Entorno de ejecución |
| DB_URL | Environment | `/app/db/podmixer.db` | Ruta de la base de datos SQLite |
| PORT | Environment | `3000` | Puerto interno del servidor |
| SLEEP_TIME | Environment | `900` | Tiempo de espera de recolección de noticias |
| OLDER_THAN | Environment | `30` | Periodicidad de eliminación de noticias viejas |

## Cómo habilitar / desplegar
1. Secretos (solo si existen):
   ```bash
   printf '%s' '<valor>' | podman secret create podmixer_secret -
   ```
2. `cd .config/containers/available/podmixer && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
