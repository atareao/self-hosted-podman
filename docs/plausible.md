# plausible — Herramienta de análisis de métricas y eventos web

## Qué es
Plauible, basado en la imagen `docker.io/plausible/analytics:latest`. Número de contenedores: 4 (plausible, plausible-clickhouse, plausible-mail, plausible-postgresql). Red(es): `proxy.network`, `plausible.network`. Dominio(s): `plausible.${FQDN}` subdominio (label `traefik.http.routers.plausible.rule`). Puerto interno: 8000 (label `traefik.http.services.plausible.loadbalancer.server.port`).

## Ficheros
- Quadlet(s):
  - `/data/self-hosted-podman/plausible.container`
  - `/data/self-hosted-podman/plausible-clickhouse.container`
  - `/data/self-hosted-podman/plausible-mail.container`
  - `/data/self-hosted-podman/plausible-postgresql.container`
- Volumen(es):
  - `/data/self-hosted-podman/plausible-db-data.volume`
  - `/data/self-hosted-podman/plausible-event-data.volume`
- Config no secreta: (no dispone de .env)
- Secretos:
  - plausible_postgres_password

## Cómo funciona
Utiliza la red `proxy.network` para la exposición a Traefik y la red `plausible.network` para la comunicación interna entre base de datos y ClickHouse. ClickHouse almacena eventos en `plausible-event-data.volume`. La variable de entorno `DATABASE_URL` no está configurada explícitamente en la unidad; el contenedor configura la DB internamente. La unidad se ejecuta con `Restart=always`. Traefik enruta el tráfico a través del puerto interno 8000.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| (ninguna) |

## Cómo habilitar / desplegar
1. Secretos (solo si existen):
   ```bash
   printf '%s' '<valor>' | podman secret create plausible_postgres_password -
   ```
2. `cd .config/containers/available/plausible && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
