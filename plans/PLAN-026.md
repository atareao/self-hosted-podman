# PLAN-026 — Apex: redirect temporal + renombrar volúmenes a `<stack>-<rol>`

- **Issue:** #21
- **Estado:** en curso
- **Fecha:** 2026-11-11

## Contexto

Cierra los dos puntos abiertos tras PLAN-025: (1) el apex debe **redirigir** (no solo servir) a la
página de error «por el momento», dejando montado el mecanismo para reapuntar a un servicio real
cambiando 1 label; (2) normalizar el resto de volúmenes a `<stack>-<rol>`.

## Objetivos

- [ ] `errserve.container`: router `errserve-apex` con `redirectregex` → 302 a `https://${FQDN}/404`.
- [ ] Renombrar 40 volúmenes (22 stacks) a `<stack>-<rol>` (fichero, `VolumeName=`, `Volume=`).
- [ ] Actualizar referencias en `docs/`.
- [ ] `docs/traefik.md`: invariante 3 describe el redirect.
- [ ] Verificar (dryrun + grep), desplegar en prod (solo cambia `errserve`) y comprobar el 302.
- [ ] Inventario + HANDOFF; archivar como `plans/PLAN-026-ARCHIVED.md`.

## Apex (errserve)

Labels del router del apex:

```
Label=traefik.http.routers.errserve-apex.rule=Host(`${FQDN}`)&&!Path(`/404`)
Label=traefik.http.routers.errserve-apex.entrypoints=websecure
Label=traefik.http.routers.errserve-apex.service=errserve
Label=traefik.http.routers.errserve-apex.middlewares=errserve-apex-redirect
Label=traefik.http.routers.errserve-apex.tls.certresolver=letsencrypt
Label=traefik.http.middlewares.errserve-apex-redirect.redirectregex.regex=^https?://[^/]+/.*
Label=traefik.http.middlewares.errserve-apex-redirect.redirectregex.replacement=https://${FQDN}/404
Label=traefik.http.middlewares.errserve-apex-redirect.redirectregex.permanent=false
```

`/404` se excluye del router del apex para que lo sirva el catch-all (`errserve`) y no haya bucle.

## Mapeo de volúmenes (`<old>` → `<new>`)

| stack | old | new |
|---|---|---|
| caddy | caddy-caddy_data | caddy-data |
| cells | cells-cellsdir | cells-app |
| cells | cells-mysqldir | cells-mysql |
| chevereto | chevereto-chevereto | chevereto-data |
| chevereto | chevereto-chevereto_mariadb | chevereto-mariadb |
| cloudbeaver | cloudbeaver-cloudbeaver | cloudbeaver-data |
| custom-code-server | custom-code-server-code_server_data | custom-code-server-data |
| custom-code-server | custom-code-server-code_server_workspace | custom-code-server-workspace |
| dev | dev-dev_mariadb | dev-mariadb |
| dev | dev-dev_redis | dev-redis |
| dev | dev-dev_wordpress | dev-wordpress |
| flame | flame-flame | flame-data |
| focalboard | focalboard-focalboard | focalboard-data |
| focalboard | focalboard-focalboarddb | focalboard-db |
| grafana-influx-telegraf | grafana-influx-telegraf-data_grafana | grafana-influx-telegraf-grafana |
| grafana-influx-telegraf | grafana-influx-telegraf-data_influxdb | grafana-influx-telegraf-influxdb |
| homepage | homepage-homepage_config | homepage-config |
| memos | memos-memos | memos-data |
| metube | metube-metube | metube-data |
| microbin | microbin-microbin | microbin-data |
| nitter | nitter-nitter-redis | nitter-redis |
| odoo | odoo-odoo | odoo-data |
| open-webui | open-webui-open-webui | open-webui-data |
| pdfding | pdfding-sqlite_data | pdfding-db |
| picoshare | picoshare-picoshare | picoshare-data |
| postgres | postgres-postgres_data | postgres-data |
| rabbitmq | rabbitmq-rabbitmq | rabbitmq-data |
| tick | tick-grafana_data | tick-grafana |
| tick | tick-influxdb_data | tick-influxdb |
| trilium | trilium-trilium | trilium-data |
| wakapi | wakapi-pg_data | wakapi-pg |
| wakapi | wakapi-wakapi | wakapi-data |
| weaviate | weaviate-weaviate_data | weaviate-data |
| wordpress | wordpress | wordpress-data |
| wordpress-wp1 | wordpress-wp1-wp1 | wordpress-wp1-data |
| wordpress-wp1 | wordpress-wp1-wp1_mariadb | wordpress-wp1-mariadb |
| wordpress-wp1 | wordpress-wp1-wp1_redis | wordpress-wp1-redis |
| wordpress-wp2 | wordpress-wp2-wp2 | wordpress-wp2-data |
| wordpress-wp2 | wordpress-wp2-wp2_mariadb | wordpress-wp2-mariadb |
| wordpress-wp2 | wordpress-wp2-wp2_redis | wordpress-wp2-redis |

Ninguno está desplegado en producción → sin migración de datos.

## Criterios de aceptación

- `https://servidorlinux.es` → **302** a `/404` (con certificado válido) y luego la página de error.
- 0 referencias a nombres de volumen viejos en quadlets y docs; 0 `Volume=` sin fichero `.volume` correspondiente.
- `quadlet -user -dryrun` sobre los stacks afectados → 0 errores; auditoría de duplicados limpia (salvo `headscale`+`headplane`).
- Prod sana (5 contenedores; `auth`/`headscale` 200).

## Follow-ups

- Reapuntar el redirect del apex a un servicio real (1 label).
- `cells-cellsdir` → `cells-app` porque `cells-data` ya existe (monta `/var/cells/data`).

Verificación: pega la salida real de `wc -l plans/PLAN-026.md` y `grep -c '^| ' plans/PLAN-026.md`.
