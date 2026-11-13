# PLAN-038 — Ronda E2E lote 10a: crowdsec, miniflux, nitter, dev, firefly

- **Issue:** #33
- **Fecha:** 2026-11-13
- **Estado:** COMPLETADO

## Objetivo

Continuar las rondas de verificación E2E en producción (`new_atareao`, usuario `runner`, rootless
Podman) con la primera mitad del lote 10 (los 5 stacks críticos): corregir los bugs latentes
detectados en la auditoría estática, alinear con el patrón repo-wide (apps tras Traefik, BD
pinnada, dependencias reales, healthchecks), desplegar, verificar los cinco puntos E2E y purgar
cada stack (salvo `crowdsec`), dejando `docs/` y `docs/estado-verificacion-e2e.md` actualizados.

## Contexto

- Repo de dotfiles (yadm), no aplicación: sin build/test/lint. El equivalente a verificación es la
  comprobación E2E por CLI, como en los lotes 1–9.
- Inventario de partida: 127 = 100 verificados + 4 en producción + 3 bloqueados + 20 sin verificar.
  Al cerrar el lote 10a: **127 = 104 verificados + 5 en producción + 3 bloqueados + 15 sin verificar**.
- El lote 10 se partió en dos rondas: **10a** críticos (este plan) y **10b** resto
  (`gitea`, `open-webui`, `pinepods`, `vector`).
- Flujo de despliegue/purga: `docs/gestion-stacks-qctl.md`. Producción **solo** como `runner` vía
  wrapper `rr`. Secretos de quadlet con `podman secret create`; la **única** excepción a `crypta
  store` es la clave de plantillas `.jinja` (p. ej. `crowdsec_bouncer_key`).

## Alcance

| Stack | Por qué entra |
|---|---|
| `firefly` | La app no tenía `APP_KEY` ni `DB_*` (no arrancaba); solo estaba en `proxy.network` (no resolvía la BD); `yobasystems/alpine-mariadb:latest`; el crontab de croni se montaba en `/crontab` (debe ser `/crontab.txt`) y el origen no existía. |
| `dev` | Bind a `.config/dev/wp-config.php` inexistente (Podman creaba un directorio) y volumen en `/var/www/html`; phpMyAdmin sin `PMA_HOST`; MariaDB `latest` + `AutoUpdate`; dos secretos para la misma BD. |
| `miniflux` | `postgres:18-alpine` con volumen en `/var/lib/postgresql/data` → **pérdida de datos**; env `$RUN_MIGRATIONS`/`$CREATE_ADMIN`/`$ADMIN_USERNAME` indefinidas; sin dependencias de la BD. |
| `nitter` | App y redis en redes disjuntas (no se resolvían); `.config/nitter/nitter.conf` no existía en el repo (Podman habría creado un directorio); healthcheck con endpoint de Twitter; imagen bajo `latest`. |
| `crowdsec` | No estaba en `proxy.network` (el bouncer de Traefik no alcanzaba el LAPI); el volumen `/etc/crowdsec` tapaba el bind de `acquis.yaml`; `latest` + `AutoUpdate`. |

## Cambios aplicados

- **firefly**: `APP_KEY` (secreto `firefly_app_key`) y `DB_*`; app añadida a `firefly.network`
  (alias `fireflyiii`); `library/mariadb:11` con volumen nombrado `firefly-mariadb.volume` y alias
  `db_for_firefly`; crontab versionado en `.config/firefly/crontab` montado en `/crontab.txt`;
  `TRUSTED_PROXIES=10.89.0.0/24`; `After=`/`Requires=` y healthchecks; imagen `version-6.7.9`.
- **dev**: fuera el bind de `wp-config.php` y volumen único en `/var/www/html/wp-content` (patrón
  `wordpress`); `PMA_HOST=mariadb`; secreto de BD unificado `dev_wordpress_db_password`; `mariadb:11`,
  `wordpress:6`, `phpmyadmin:5` pinned; expuesto tras Traefik en `dev.${FQDN}` y `dev-pma.${FQDN}`
  (phpMyAdmin protegido con `oidc-auth@file`); `WP_REDIS_HOST=redis`; healthchecks.
- **miniflux**: `postgres:17-alpine` con volumen en `/var/lib/postgresql/data`; `RUN_MIGRATIONS=1`,
  `CREATE_ADMIN=1`, `ADMIN_USERNAME=admin` literales; `After=`/`Requires=` a `miniflux-postgresql`;
  `miniflux:2.3.5` y `reactflux:2026.11.07`; healthchecks.
- **nitter**: app añadida a `nitter.network` y `Requires=`/`After=` a `nitter-redis`; imagen pinned a
  tag de commit inmutable; `nitter.conf.jinja` versionado (render con `unjinja`); `sessions.jsonl`
  placeholder obligatorio (nitter aborta sin él); healthcheck a `127.0.0.1:8080`.
- **crowdsec**: `v1.8.2` (sin `AutoUpdate`); añadido a `proxy.network`; el `acquis.yaml` se monta en
  `/etc/crowdsec/acquis.d/local.yaml` (no superpuesto con el volumen).
- **Extra (bouncer de Traefik, fuera del alcance inicial)**: el middleware `crowdsec-bouncer@file`
  tenia la clave placeholder `TU_API_KEY_GENERADA_CON_CSCLI`, no había bouncer registrado y no estaba
  enganchado a ningún router. Se generó y registró `traefik-bouncer` (`cscli bouncers add --key`),
  se guardó la clave como `crowdsec_bouncer_key` en el store, `.config/traefik/dynamic/crowdsec.yml`
  pasó a `crowdsec.yml.jinja` (`{{ env.CROWDSEC_BOUNCER_KEY }}`, renderizado por `unjinja`) y el
  middleware se aplica globalmente en el entrypoint `websecure` de `traefik.yml`.

## Verificación E2E (producción `new_atareao`)

| Stack | unit | contenedores | HTTP | cert LE |
|---|---|---|---|---|
| crowdsec | active | healthy | LAPI `{"status":"up"}` | — |
| miniflux | active | healthy (app, pg, reactflux) | 200 | sí |
| nitter | active | healthy (app, redis) | 200 | sí |
| dev | active | healthy (mariadb, redis, wordpress, phpmyadmin) | 302 → 200 (install.php) | sí |
| firefly | active | healthy (app, mariadb, croni) | 302 → 200 (/register) | sí |

Bouncer de Traefik: `traefik-bouncer` **validado** por el LAPI (`last_pull` activo, 0 errores en
Traefik).

## Purga

`miniflux`, `nitter`, `dev` y `firefly` purgados con `qctl purge --secrets --images -y` (0
contenedores, 0 secretos, 0 symlinks). **`crowdsec` no se purga**: queda en producción como motor
de seguridad global del que depende el bouncer de Traefik.

## Notas / follow-ups

- `nitter` sin tokens de sesión de X sirve la portada pero no consulta la API (limitación externa).
- Lección de rate-limit de Let's Encrypt: 50 certs/168h por dominio; el router de un stack nuevo
  puede tardar en obtener cert hasta que expire la ventana (afectó a `nitter`).
