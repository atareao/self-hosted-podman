# PLAN-037 — Ronda E2E lote 9: wordpress-wp1, wordpress-wp2, registry

- **Issue:** #32
- **Fecha:** 2026-11-13
- **Estado:** COMPLETADO

## Objetivo

Continuar las rondas de verificación E2E en producción (`new_atareao`, usuario `runner`, rootless
Podman) con el lote 9: alinear `wordpress-wp1`/`wordpress-wp2` con la plantilla ya verificada
`wordpress`, completar `registry` (faltaban `config.yml` y `htpasswd`), desplegar, verificar los
puntos E2E y purgar cada stack, dejando `docs/` y `docs/estado-verificacion-e2e.md` actualizados.

## Contexto

- Repo de dotfiles (yadm), no aplicación: sin build/test/lint ni código de aplicación. El equivalente
  a verificación es la comprobación E2E por CLI, como en los lotes 1–8.
- Inventario de partida: 127 = 97 verificados + 4 en producción + 3 bloqueados + 23 sin verificar.
  Al cerrar: **127 = 100 verificados + 4 en producción + 3 bloqueados + 20 sin verificar**.
- Flujo de despliegue/purga: `docs/gestion-stacks-qctl.md`. Producción **solo** como `runner` vía
  wrapper `rr`. Secretos con `podman secret create`, **nunca** `crypta store`.

## Alcance

| Stack | Por qué entra en el lote |
|---|---|
| `wordpress-wp1` | Clon de `wordpress` sin alinear: bind a un `wp-config.php` inexistente (Podman creaba un directorio), volumen en `/var/www/html` en vez de `/var/www/html/wp-content`, **dos secretos distintos para el mismo password de BD** (app vs BD), sin `Requires=`/`After=` ni healthchecks, MariaDB sin pinnear. |
| `wordpress-wp2` | Idéntico a `wordpress-wp1`. |
| `registry` | Faltaban `config.yml` y `htpasswd`; host de Traefik placeholder `tu.${FQDN}`; `NGINX_PROXY_PASS_URL` como secreto (no lo es). |

## Correcciones aplicadas

### wordpress-wp1 / wordpress-wp2
- Volumen único `*-data.volume:/var/www/html/wp-content:Z`; fuera el bind de `wp-config.php` y los
  binds de `plugins`/`themes`/`uploads`.
- `After=network-online.target *-mariadb.service *-redis.service traefik.service` y
  `Requires=*-mariadb.service *-redis.service`.
- Secreto único `wordpress_wp{1,2}_wordpress_db_password` (`type=env`) para la app
  (`WORDPRESS_DB_PASSWORD`) **y** la BD (`MARIADB_PASSWORD`); `wordpress_wp{1,2}_mariadb_root_password`
  → `MARIADB_ROOT_PASSWORD`.
- `WORDPRESS_CONFIG_EXTRA` (Redis + HTTPS tras Traefik + `FORCE_SSL_ADMIN`), healthchecks (app
  `curl -f /wp-login.php`, MariaDB `mariadb-admin ping`, redis `redis-cli ping`), `mariadb:11` pinnada
  y sin `AutoUpdate`.

### registry
- `.config/registry/config.yml.jinja` (renderizado por `unjinja`, CORS al FQDN) + `.config/registry/.gitignore`
  (`config.yml`, `htpasswd`).
- Bind del config a **`/etc/distribution/config.yml`** (registry v3; la ruta antigua
  `/etc/docker/registry/config.yml` se ignoraba).
- `registry-ui`: Host `registry.${FQDN}`; `NGINX_PROXY_PASS_URL` movido de secreto a `Environment`.

## Secretos

`wordpress_wp1_wordpress_db_password`, `wordpress_wp1_mariadb_root_password`,
`wordpress_wp2_wordpress_db_password`, `wordpress_wp2_mariadb_root_password` (con `podman secret create`).
El `registry` no declara secretos: su `htpasswd` se genera con `htpasswd -Bbn`.

## Verificación E2E (2026-11-13)

Los 5 puntos por stack. `wordpress-wp1`/`wordpress-wp2`: `https://wp{1,2}.${FQDN}/` → 302 a
`/wp-admin/install.php` (200). `registry`: UI 200; `/v2/_catalog` → 401 sin credenciales y 200 con
ellas; login + push + catálogo con `podman` OK. Certificados Let's Encrypt reales (resolver
`letsencrypt`).

## Purga y cierre

`qctl purge --secrets --images` por stack; comprobado 0 contenedores / 0 volúmenes / 0 secretos / 0
symlinks. `docs/wordpress-wp1.md`, `docs/wordpress-wp2.md`, `docs/registry.md` y
`docs/estado-verificacion-e2e.md` actualizados. Plan archivado e issue #32 cerrado.

## Tareas

- [x] Alinear `wordpress-wp1` (volumen `wp-content`, sin bind de `wp-config.php`, secreto de BD compartido, `Requires=`/healthchecks, MariaDB 11 pinnada).
- [x] Alinear `wordpress-wp2` (ídem).
- [x] Completar `registry` (`config.yml.jinja`, `htpasswd`, host `registry.${FQDN}`, `NGINX_PROXY_PASS_URL` por env).
- [x] Commit de los fixes y push a `main`.
- [x] Crear los secretos y desplegar los 3 stacks.
- [x] Verificar los puntos E2E (incluido login+push+pull en `registry`).
- [x] Purgar los 3 stacks y comprobar estado limpio.
- [x] Actualizar docs y `docs/estado-verificacion-e2e.md`.
