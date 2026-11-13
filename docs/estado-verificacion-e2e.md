# Estado de verificación E2E de los stacks

Última actualización: 2026-11-13.

Inventario de fiabilidad del repo: distingue lo que ya se ha **probado end-to-end en producción**
de lo que sólo existe como quadlet + doc sin validar en el host real.

## Qué significa «verificado E2E»

Un stack se considera verificado E2E cuando se ha desplegado en producción (`new_atareao`, usuario
`runner`) y se comprueban los cinco puntos:

1. El unit systemd queda `active`.
2. El contenedor arranca (`podman ps`).
3. Traefik registra el router (label `traefik.enable=true`).
4. El certificado Let's Encrypt es válido para el dominio.
5. La URL responde con el HTTP esperado.

Verificado E2E **no** garantiza que el stack no tenga bugs latentes: dos de ellos (gokapi y dufs)
sólo aparecieron al ejecutarlo de verdad.

## Resumen

| Categoría | Nº |
|---|---|
| Stacks en `.config/containers/available/` | 127 |
| Verificados E2E (probados y purgados) | 104 |
| Bloqueados / hallazgos (ver sección) | 3 |
| En producción (desplegados y corriendo) | 9 (el stack `headscale` lleva 2 contenedores) |
| **Sin verificar E2E** | **11** |

## Verificados E2E (probados y purgados)

Todos entre el **2026-11-09** y el **2026-11-13** (el **lote 3** — `bookstack`, `dnote`,
`focalboard`, `snibox`, `umami` y `hedgedoc` — es del **2026-11-11**; el **lote 4** — `wallabag`,
`vscode`, `whisper`, `unbound`, `watchbeat` y `publirs` —, del **2026-11-11/12**; el **lote 5** —
`mtproxy`, `simple-torrent`, `socks5`, `webdav`, `miniflux-client` y `zennotes` — se verificó y
purgó el **2026-11-12**; el **lote 6** — `tick`, `mumble`, `cells`, `chevereto` y `jellystat` — se
verificó y purgó el **2026-11-12**; el **lote 7** — `photoprism`, `rabbitmq`, `weaviate` y
`wordpress` —, el **2026-11-13**; el **lote 8** — `codimd`, `huginn`, `planka`, `facturascripts` y
`postgres` —, el **2026-11-13**; el **lote 9** — `wordpress-wp1`, `wordpress-wp2` y `registry` —, el **2026-11-13**; el **lote 10a** — `crowdsec`, `miniflux`, `nitter`, `dev` y `firefly` —, el **2026-11-13**): desplegados,
verificados end-to-end y
**purgados** el mismo día (unit
desenlazado, volúmenes/binds/secretos e imágenes eliminados). Estado actual: **no desplegados**.

| Stack | Doc | Plan / Issue | HTTP | Notas |
|---|---|---|---|---|
| dozzle | `docs/dozzle.md` | PLAN-011 / #5 | 200 | secretos `dozzle_username` / `dozzle_password` |
| navidrome | `docs/navidrome.md` | PLAN-011 / #5 | 302 | uid 1000: binds con `podman unshare chown/rm` |
| stirling-pdf | `docs/stirling-pdf.md` | PLAN-011 / #5 | 200 | |
| memos | `docs/memos.md` | PLAN-011 / #5 | 200 | imagen correcta `:stable` (no `latest`) |
| ittools | `docs/ittools.md` | PLAN-012 / #6 | 200 | sin almacenamiento |
| metube | `docs/metube.md` | PLAN-012 / #6 | 200 | volumen nombrado |
| shaarli | `docs/shaarli.md` | PLAN-012 / #6 | 302 | |
| gokapi | `docs/gokapi.md` | PLAN-012 / #6 | 200 | fix: service port Traefik 80 → 8080 |
| freshrss | `docs/freshrss.md` | PLAN-013 / #7 | 200 | bind `~/.config/freshrss/…` |
| gotify | `docs/gotify.md` | PLAN-013 / #7 | 200 | bind `~/.config/gotify/data` |
| kavita | `docs/kavita.md` | PLAN-013 / #7 | 200 | tarda ~40 s en migrar (502 temporal) |
| otterwiki | `docs/otterwiki.md` | PLAN-013 / #7 | 200 | dominio `wiki.${FQDN}` |
| dufs | `docs/dufs.md` | #8 | 401/200 | fix: `DUFS_AUTH` por `Secret=` + booleanos `true` |
| uptime-kuma | `docs/uptime-kuma.md` | PLAN-014 / #9 | 200 | volumen nombrado |
| trilium | `docs/trilium.md` | PLAN-014 / #9 | 200 | volumen nombrado |
| audiobookshelf | `docs/audiobookshelf.md` | PLAN-014 / #9 | 200 | 3 volúmenes nombrados |
| pairdrop | `docs/pairdrop.md` | PLAN-014 / #9 | 200 | sin almacenamiento |
| readeck | `docs/readeck.md` | PLAN-014 / #9 | 200 | volumen nombrado |
| bentopdf | `docs/bentopdf.md` | PLAN-014 / #9 | 200 | sin almacenamiento |
| cloudbeaver | `docs/cloudbeaver.md` | PLAN-015 / #10 | 200 | volumen nombrado |
| custom-code-server | `docs/custom-code-server.md` | PLAN-015 / #10 | 200 | servía HTTP en 8443; no hizo falta scheme=https |
| logseq | `docs/logseq.md` | PLAN-015 / #10 | 200 | sin almacenamiento |
| phpmyadmin | `docs/phpmyadmin.md` | PLAN-015 / #10 | 200 | sin almacenamiento |
| sftpgo | `docs/sftpgo.md` | PLAN-015 / #10 | 200 | 2 volúmenes nombrados |
| nginx | `docs/nginx.md` | PLAN-015 / #10 | 200 | sin almacenamiento |
| ferrishare | docs/ferrishare.md | #11 | 200 | requiere provisioning previo del volumen (ferrishare-init.py) |
| homepage | `docs/homepage.md` | PLAN-017 / #12 | 200 | bind podman.sock (ro) |
| portainer | `docs/portainer.md` | PLAN-017 / #12 | 200 | bind podman.sock (ro) |
| jellyfin | `docs/jellyfin.md` | PLAN-017 / #12 | 302→200 | 3 volúmenes nombrados |
| zincobserve | `docs/zincobserve.md` | PLAN-017 / #12 | 307→200 | corregido: ZO_ROOT_USER_EMAIL/PASSWORD |
| yopass | `docs/yopass.md` | PLAN-017 / #12 | 200 | corregido: puerto 80→1337 (rootless) |
| searxng | `docs/searxng.md` | PLAN-017 / #12 | 200 | corregido: volumen :rw:Z→:Z |
| flame | `docs/flame.md` | PLAN-018 / #13 | 200 | secreto flame_password |
| flatnotes | `docs/flatnotes.md` | PLAN-018 / #13 | 200 | corregido: dominio + service port 8080 |
| notemark | `docs/notemark.md` | PLAN-018 / #13 | 200 | JWT_SECRET debe ser largo (≥64) |
| picoshare | `docs/picoshare.md` | PLAN-018 / #13 | 200 | secreto ps_shared_secret |
| podmixer | `docs/podmixer.md` | PLAN-018 / #13 | 200 | 2 volúmenes nombrados |
| glass-keep | `docs/glass-keep.md` | PLAN-018 / #13 | 200 | dominio `keep.*`; INITIAL_ADMIN_USERNAME/PASSWORD |
| dagu | `docs/dagu.md` | PLAN-019 / #14 | 200 | corregido: imagen dagucloud + base path |
| semaphore | `docs/semaphore.md` | PLAN-019 / #14 | 200 | corregido: dialecto sqlite + service port 3000 |
| rustfs | `docs/rustfs.md` | PLAN-019 / #14 | 200 | corregido: healthcheck exec; console en /rustfs/console |
| storyteller | `docs/storyteller.md` | PLAN-019 / #14 | 200 | corregido: volumen :rw:Z→:Z |
| pdfding | `docs/pdfding.md` | PLAN-019 / #14 | 200 | 2 volúmenes |
| openobserve | `docs/openobserve.md` | PLAN-019 / #14 | 200 | requiere security.network (stack vector) |
| ntfy | `docs/ntfy.md` | PLAN-021 / #16 | 200 | corregido: imagen oficial + `Exec=serve` |
| opengist | `docs/opengist.md` | PLAN-021 / #16 | 302 | router/servicio `gist`; secretos Gitea obligatorios |
| filebrowser | `docs/filebrowser.md` | PLAN-021 / #16 | 200 | layout v2.63 (`/config`,`/database`); puerto 8080 |
| silverbullet | `docs/silverbullet.md` | PLAN-021 / #16 | 200 | secreto `silverbullet_sb_user`; imagen no oficial |
| yacht | `docs/yacht.md` | PLAN-021 / #16 | 200 | corregido: service port 3000→8000 |
| dasherr | `docs/dasherr.md` | PLAN-021 / #16 | 401 | dominio `nginx.${FQDN}` (no colisiona: `nginx` sirve `web.${FQDN}`) |
| homer | `docs/homer.md` | PLAN-022 / #17 | 200 | bind `~/.config/homer/assets` (chown 1000:1000) |
| dockge | `docs/dockge.md` | PLAN-022 / #17 | 200 | bind podman.sock (ro); healthcheck `/app/extra/healthcheck` |
| vaultwarden | `docs/vaultwarden.md` | PLAN-022 / #17 | 200 | secreto `vaultwarden_admin_token` |
| microbin | `docs/microbin.md` | PLAN-022 / #17 | 401 | 2 secretos; volumen nombrado `microbin-data` |
| pastebin | `docs/pastebin.md` | PLAN-022 / #17 | 303→200 | imagen `atareao/pastebin` desaparecida → upstream `mkaczanowski/pastebin` |
| couchdb | `docs/couchdb.md` | PLAN-027 / #22 | 200 | 2 contenedores; `COUCHDB_USER`/`COUCHDB_PASSWORD` en el primer arranque |
| dim | `docs/dim.md` | PLAN-027 / #22 | 200 | bind `~/.config/dim/config` + volumen `dim-media` |
| ghost | `docs/ghost.md` | PLAN-027 / #22 | 200 | corregido: `url` con `https://` y bind `/var/lib/ghost/content` (errata `lig`→`lib`) |
| kanboard | `docs/kanboard.md` | PLAN-027 / #22 | 302 | corregido: bind `/var/www/app/data` (errata `bar`→`var`) |
| atuin | `docs/atuin.md` | PLAN-030 / #25 | 200 | fix: imagen oficial `ghcr.io/atuinsh/atuin` + `Exec=start`; `postgres:18-alpine` con volumen en `/var/lib/postgresql`; atuin en `atuin.network` |
| beszel | `docs/beszel.md` | PLAN-030 / #25 | 200 | fix: hub sin `DISABLE_PASSWORD_AUTH` (bloqueaba el login); agente en modo SSH/TCP `LISTEN=45876` con `beszel_key` = clave pública generada por el hub (`beszel_data/id_ed25519`); eliminado el volumen `beszel-socket` |
| radicale | `docs/radicale.md` | PLAN-030 / #25 | 200 | fix: router/servicio Traefik `expulsabot` → `radicale`; binds deben ser uid 1000 (`podman unshare chown`) y `.htpasswd-users` en `apr1/md5` (`htpasswd -m`) |
| wakapi | `docs/wakapi.md` | PLAN-030 / #25 | 200 | sin cambios; secretos DB con el mismo valor |
| wikijs | `docs/wikijs.md` | PLAN-030 / #25 | 200 | fix: `DB_HOST` `db` → `postgres` (alias real) y service port Traefik 80 → 3000; bind de datos uid 70 |
| zincsearch | `docs/zincsearch.md` | PLAN-030 / #25 | 200 | sin cambios; `/` → 302 a `/ui/` |
| bookstack | `docs/bookstack.md` | PLAN-031 / #26 | 302 (/), 200 (/login) | fix: app añadida a `bookstack.network` y binds separados (`config` app / `mariadb` BD); `APP_KEY` por secreto `bookstack_app_key`; imagen LSNG espera `DB_USERNAME`/`DB_PASSWORD` (no `DB_USER`/`DB_PASS`) |
| dnote | `docs/dnote.md` | PLAN-031 / #26 | 302 | fix: app añadida a `dnote.network` (resolvía `postgres`), secreto único `dnote_postgres_password`; service port interno 3001 (no 3000) |
| focalboard | `docs/focalboard.md` | PLAN-031 / #26 | 200 | fix: `postgres:18-alpine` con volumen en `/var/lib/postgresql`; secretos `focalboard_postgres_password` + `focalboard_database_url` (`FOCALBOARD_DBCONFIG`); bind `config.json` → `FOCALBOARD_DBTYPE=postgres` |
| snibox | `docs/snibox.md` | PLAN-031 / #26 | 302 | fix: nginx añadido a `snibox.network` (daba 502) y `snibox_postgres_password` compartido app/BD |
| umami | `docs/umami.md` | PLAN-031 / #26 | 200 (/ y /login) | fix: `Requires=`/`After=` apuntaban a `umamidb.service` → `umami-postgresql.service` (la unit no cargaba) |
| hedgedoc | `docs/hedgedoc.md` | PLAN-031 / #26 | 200 | fix: faltaban `Requires=`/`After=` hacia MariaDB; sin `PodmanArgs=--init` (imagen LSNG/s6-overlay exige PID 1) |
| wallabag | `docs/wallabag.md` | PLAN-032 / #27 | 302 (/), 200 (/login) | fix: quitado el placeholder sin sustituir de `SYMFONY__ENV__SERVER_NAME`; las migraciones del 1.er arranque crean `~/.config/wallabag/data/db/wallabag.sqlite` (SQLite); sin reinicios |
| vscode | `docs/vscode.md` | PLAN-032 / #27 | 302 (/), 200 (/login) | imagen LSNG sin `--init` (correcto); login con el secreto `vscode_password` |
| whisper | `docs/whisper.md` | PLAN-032 / #27 | 200 (/docs), 307 (/) | **interno, sin Traefik** (excepción); fix: imagen `:latest` (prod sin GPU NVIDIA), modelo `small`, host 9001→contenedor 9000 (colisión con authentik); 1.er arranque ~200 s (pull de 5,31 GB) |
| unbound | `docs/unbound.md` | PLAN-032 / #27 | n/a | **interno, sin Traefik** (excepción); fix: publica **5353** (rootless no puede enlazar el 53) y monta la config por el include real de la imagen; recursión verificada (`NOERROR` con `ad`); ACL de la IP de host pendiente (comentada) |
| watchbeat | `docs/watchbeat.md` | PLAN-032 / #27 | 200 (/), 200 (/health), 303 (/auth/login) | fix: issuer OIDC real de PocketID + redirect al **subdominio**; healthcheck en `127.0.0.1` + `AddHost=auth.${FQDN}:host-gateway`; **OIDC pendiente** (no existe cliente `watchbeat` en PocketID y `watchbeat_oidc_client_secret` quedó con placeholder) |
| publirs | `docs/publirs.md` | PLAN-032 / #27 | 200 (/api/v1/status) | 2 units (`publirs` + `publirs-croni`); fix: expuesto por Traefik en `publirs.${FQDN}`, `crontab.txt` montado en croni, quitado el bind a `/etc/timezone`; croni carga las 3 tareas; `publirs_token` **placeholder** (envío a Telegram no probado) |
| mtproxy | `docs/mtproxy.md` | PLAN-033 / #28 | n/a | **interno, sin Traefik** (excepción); fix: `--nat-info` formado con IPv6 → override `IP=<IPv4>` en `mtproxy.env.local`; publica 8388→8889 |
| simple-torrent | `docs/simple-torrent.md` | PLAN-033 / #28 | 401 | **interno, sin Traefik** (excepción); fix: imagen `boypt/cloud-torrent` retirada de Docker Hub → `docker.io/jpillora/cloud-torrent:latest` (config `cloud-torrent.json` JSON, `PORT=50012`); `AUTH` por secreto |
| socks5 | `docs/socks5.md` | PLAN-033 / #28 | n/a | **interno, sin Traefik** (excepción); fix: quitado bind inexistente y publica 8389 (8388 reservado a mtproxy); verificado por puerto |
| webdav | `docs/webdav.md` | PLAN-033 / #28 | 401 | cert LE real; bind `htpasswd` (bcrypt, user `admin`) + `share/` |
| zennotes | `docs/zennotes.md` | PLAN-033 / #28 | 200 | cert LE real; secreto `zennotes_auth_token`; contenedor `healthy` |
| miniflux-client | `docs/miniflux-client.md` | PLAN-033 / #28 | n/a | **interno, sin Traefik** (excepción); solo **arranque** verificado: arranca y hace panic al no alcanzar `miniflux.servidorlinux.es` (dependencia `miniflux`/`matrix` no desplegadas) → **bloqueado por dependencia** |
| tick | `docs/tick.md` | PLAN-034 / #29 | 302 (/), 200 (influxdb) | 3 contenedores; `telegraf.conf` creado; InfluxDB 2.7; certs LE reales |
| mumble | `docs/mumble.md` | PLAN-034 / #29 | n/a | **interno TCP/UDP** (excepción); puerto 64738; certs autofirmados |
| cells | `docs/cells.md` | PLAN-034 / #29 | 200 | 2 contenedores; `MYSQL_DATABASE`/`MYSQL_USER` por `cells.env`; dependencia app→MySQL |
| chevereto | `docs/chevereto.md` | PLAN-034 / #29 | 302 | service port 8080; `User=0`; healthcheck con `curl` |
| jellystat | `docs/jellystat.md` | PLAN-034 / #29 | 200 | 2 contenedores; `POSTGRES_*` por `jellystat.env`; dependencia app→PostgreSQL |
| photoprism | `docs/photoprism.md` | PLAN-035 / #30 | 307 (/), 200 (login) | fix: sin `--init` (la imagen ya trae s6-overlay), secreto `photoprism_admin_password` + `SITE_URL`, healthcheck por `curl` a `127.0.0.1:2342`, `HealthStartPeriod=120s` |
| rabbitmq | `docs/rabbitmq.md` | PLAN-035 / #30 | 200 | fix: volumen `mnseia`→`mnesia` + `:U`, secreto `rabbitmq_default_pass` inexistente, usuario `admin`, healthcheck; **`User=rabbitmq`** porque el healthcheck (root) creaba `.erlang.cookie` como root |
| weaviate | `docs/weaviate.md` | PLAN-035 / #30 | n/a | **interno, sin Traefik** (excepción); fix: deja de publicar 8080/50051 sin auth → red propia `weaviate.network` + `NetworkAlias`; healthcheck `/v1/.well-known/ready`; gRPC validado con `grpc_health_probe` |
| wordpress | `docs/wordpress.md` | PLAN-035 / #30 | 302 (/), 200 (/wp-login.php) | fix: `Requires=` a units inexistentes (`mariadb`/`valkey` → `wordpress-*`), router `wp`→`wordpress`, `service.port=80`, secretos `type=env`, `WP_CONFIG_EXTRA` unificado; 3 contenedores healthy; será plantilla de wp1/wp2 |
| codimd | `docs/codimd.md` | PLAN-036 / #31 | 200 | fix: app añadida a `codimd.network`; `CMD_*` (sin `CMD_DB_URL` HackMD muere en Sequelize), secretos `codimd_db_url`/`codimd_session_secret`; PG 11.6→17-alpine con `pg_isready`; bind con comilla huérfana → volúmenes nombrados `:U`; PG17 fuerza auth `md5` (cliente `pg` antiguo) |
| huginn | `docs/huginn.md` | PLAN-036 / #31 | 200 (login) | fix: web añadida a `huginn.network`; `DATABASE_HOST`/`ADAPTER`/`PORT` (sin host `setup_env` arranca un MySQL interno), `APP_SECRET_TOKEN` por secreto; `Requires=`/`After=` hacia MariaDB; 13 tablas |
| planka | `docs/planka.md` | PLAN-036 / #31 | 200 | fix: app añadida a `planka.network` (`EAI_AGAIN postgres`); `Requires=`/`After=planka-postgresql.service`; `BASE_URL` https y `TRUST_PROXY=true`; `/api/config` JSON |
| facturascripts | `docs/facturascripts.md` | PLAN-036 / #31 | 200 (login) | fix: app añadida a `facturascripts.network`; MariaDB con `MARIADB_ROOT_PASSWORD` + `MYSQL_*`; `FS_DB_*`/`FS_INITIAL_*`/`FS_LANG`; binds → volúmenes `:U`; **instalación desatendida por POST a `/`** (302 → `/login`) |
| postgres | `docs/postgres.md` | PLAN-036 / #31 | 302 (pgAdmin) | fix: pgAdmin añadido a `postgres.network`; **pérdida de datos** con `postgres:latest` (18.x, `VOLUME` en `/var/lib/postgresql`) → pin `17-alpine` con volumen en `/var/lib/postgresql/data`; sin `AutoUpdate`; PG healthy y TCP `postgres:5432` desde pgAdmin |
| wordpress-wp1 | `docs/wordpress-wp1.md` | PLAN-037 / #32 | 302 | volumen en `/var/www/html/wp-content` (sin bind de `wp-config.php`); secreto de BD compartido app/BD (`wordpress_wp1_wordpress_db_password`); MariaDB 11 pinnada + healthchecks |
| wordpress-wp2 | `docs/wordpress-wp2.md` | PLAN-037 / #32 | 302 | ídem `wordpress-wp1` con `wp2` |
| registry | `docs/registry.md` | PLAN-037 / #32 | 401/200 | fix: `registry:latest` (v3.1.2) lee el config en `/etc/distribution/config.yml` (el htpasswd no se aplicaba: 200 sin auth); login+push+catálogo OK |
| dev | `docs/dev.md` | PLAN-038 / #33 | 302 (dev), 401 (dev-pma) | fix: fuera el bind a `wp-config.php` inexistente (Podman creaba un directorio) → volumen único en `/var/www/html/wp-content`; phpMyAdmin con `PMA_HOST=mariadb`; secreto de BD unificado `dev_wordpress_db_password`; `mariadb:11`/`wordpress:6`/`phpmyadmin:5` pinned; expuesto en `dev.${FQDN}` y `dev-pma.${FQDN}` (phpMyAdmin con `oidc-auth@file`); `WP_REDIS_HOST=redis`; healthchecks |
| firefly | `docs/firefly.md` | PLAN-038 / #33 | 302 → 200 (/register) | fix: faltaban `APP_KEY`/`DB_*` (no arrancaba); app añadida a `firefly.network` (la BD no resolvía); `yobasystems/alpine-mariadb:latest` → `library/mariadb:11` con volumen nombrado; crontab de croni montado en `/crontab.txt`; `TRUSTED_PROXIES`; healthchecks |
| miniflux | `docs/miniflux.md` | PLAN-038 / #33 | 200 | fix: **pérdida de datos** con `postgres:18-alpine` (VOLUME en `/var/lib/postgresql`) → pin `17-alpine` con volumen en `/var/lib/postgresql/data`; `RUN_MIGRATIONS`/`CREATE_ADMIN`/`ADMIN_USERNAME` con `$VAR` inexistentes → literales; `After=`/`Requires=` a postgres; app 2.3.5 y reactflux pinned |
| nitter | `docs/nitter.md` | PLAN-038 / #33 | 200 | fix: app y redis en redes disjuntas → app en `nitter.network`; `Requires=` a redis; imagen pinned a tag de commit; `sessions.jsonl` obligatorio (placeholder versionado); `nitter.conf.jinja` versionado; healthcheck sin endpoint de Twitter |

## Bloqueados / hallazgos

Desplegados y funcionales a nivel de servicio, pero **no verificados E2E completos** por un bloqueo externo:

| Stack | Motivo | Referencia |
|---|---|---|
| apimail | Sirve OK (`/api/health` → 200 JSON, cert LE staging), pero **no arranca en frío**: el healthcheck de conmon sale con exit 125 por el bug de secretos con driver externo (`shell`) + `type=env` (afecta a 13 units). | Issue #23 / `plans/PLAN-028.md` |
| alloy | Requiere un cliente **OIDC real** en PocketID (`OIDC_ISSUER_URL`, `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`, `OIDC_REDIRECT_URL`); sin él la discovery falla y el contenedor sale con `exit=1` (crash-loop). | — |
| mysteryshack | La imagen `docker.io/atareao/mysteryshack:v1.0` no existe en Docker Hub ni en GHCR (404); nunca se publicó. El repo origen la construía con `ubuntu:18.04`/`libssl1.0.0` (EOL). | `docs/mysteryshack.md` |

Hallazgo transversal (PLAN-031 / #26): `PodmanArgs=--init` es **incompatible** con las imágenes LinuxServer.io
(`lscr.io/linuxserver/*`): usan s6-overlay y exigen ser PID 1, y abortan con
`s6-overlay-suexec: fatal: can only run as pid 1`. Se omitió `--init` en los quadlets afectados. Ver
`docs/bookstack.md` y `docs/hedgedoc.md`.

Hallazgo transversal (PLAN-035 / #30): el patrón **no es exclusivo de LinuxServer.io**. La imagen
oficial `photoprism/photoprism:latest` (26.04, Ubuntu 26.04) también pasó a **s6-overlay** y rompe
igual con `PodmanArgs=--init`. Antes de añadir `--init`, comprobar si la imagen trae s6-overlay.

Hallazgo transversal (PLAN-035 / #30): **healthchecks que corren como root** en imágenes con
`gosu`/`su-exec` (`rabbitmq`, y candidatos del mismo patrón como `postgres`, `redis`/`valkey`,
`mongo`). El healthcheck se ejecuta con el usuario del contenedor (root), no con el de servicio, y
crea ficheros en el HOME del usuario de servicio (`/var/lib/rabbitmq/.erlang.cookie` como
`root:root 400`). El proceso real, ya sin privilegios, falla con `eacces` y entra en crash-loop.
Fix: `User=<usuario-de-servicio>` en `[Container]` **y** volumen con `:U` para que el `chown` cuadre.
Ver `docs/rabbitmq.md`.

Hallazgo transversal (PLAN-036 / #31): **app y BD en redes distintas**. Siete stacks del inventario
declaraban la red interna de la BD pero no unían la app a ella (la app solo estaba en `proxy.network`), así
que la resolución del host de la BD fallaba (`EAI_AGAIN`, `getaddrinfo`, `no such host`). Regla: la app debe
estar en la red de su BD **y** declarar `Requires=`/`After=` sobre el unit de la BD.

Hallazgo transversal (PLAN-036 / #31): **`postgres:latest` = 18.x cambia la ruta del volumen**. Desde
PostgreSQL 18 la imagen declara `VOLUME /var/lib/postgresql` (no `/var/lib/postgresql/data`); un volumen
montado en la ruta antigua queda **sin usar** y los datos viven en la capa del contenedor (se pierden al
recrear). Pin de major (`postgres:17-alpine` + `/var/lib/postgresql/data`) y sin `AutoUpdate` en BDs.

Hallazgo transversal (PLAN-036 / #31): **clientes PG antiguos necesitan md5**. El cliente `pg` de HackMD
2.4.2 no soporta SCRAM y falla con `Unknown authenticationOk message type ... length 23` contra PG 17;
forzar `POSTGRES_HOST_AUTH_METHOD=md5` + `POSTGRES_INITDB_ARGS=--auth-host=md5` (solo válido con datadir
vacío; con datos hay que resetear contraseñas).

Hallazgo transversal (PLAN-037 / #32): **`registry:latest` = 3.x lee el config en otra ruta**. La
imagen 3.1.2 usa `/etc/distribution/config.yml` por defecto; montar el config en la ruta antigua
`/etc/docker/registry/config.yml` hace que se **ignore**: el registry arranca con su config de fábrica
(sin `auth` ni CORS) y la API queda **abierta** (el htpasswd no se aplica). Fix: bind a
`/etc/distribution/config.yml`.

Hallazgo transversal (PLAN-037 / #32): **recrear `registry` deja `registry-ui` en 502**. La nginx de
`joxit/docker-registry-ui` cachea el upstream (`registry:5000`) al arrancar; si se recrea solo el
contenedor `registry`, la UI devuelve 502 en `/v2/` hasta reiniciar `registry-ui`. Y, como siempre,
tras recrear contenedores puede hacer falta `systemctl --user restart traefik`.

### Pendientes abiertos del lote 4 (PLAN-032 / #27)

Los seis stacks del lote 4 quedaron **verificados E2E y purgados**, pero con follow-ups abiertos (no bloquean la ronda):

- **watchbeat:** falta registrar el cliente OIDC `watchbeat` en PocketID; `watchbeat_oidc_client_secret` quedó con **placeholder**, así que el login no funciona de extremo a extremo.
- **publirs:** `publirs_token` quedó con **placeholder** → el envío a Telegram no se ha probado.
- **publirs (croni):** las 3 tareas del `crontab.txt` invocan `publish_tip`/`publish_poll` por **GET** y la API responde 404/405 (probablemente requiera **POST**) → esos jobs fallarán.
- **unbound:** la ACL de la IP del host sigue **comentada**; el puerto **53 del host queda sin cubrir a propósito** (limitación rootless, ver nota abajo).

## En producción (desplegados y corriendo)

| Stack | Doc | Estado |
|---|---|---|
| errserve | `docs/errserve.md` | healthy |
| headscale | `docs/headscale.md` | healthy — 2 contenedores: `headscale` + `headscale-headplane` (doc en `docs/headplane.md`) |
| pocketid | `docs/pocketid.md` | healthy — proveedor OIDC |
| traefik | `docs/traefik.md` | healthy — edge |
| crowdsec | `docs/crowdsec.md` | healthy — Security Engine global; LAPI up y bouncer de Traefik `traefik-bouncer` validado (middleware global en `websecure`) |
| gitea | `docs/gitea.md` | healthy — router `gitea.servidorlinux.es` respondiendo (HTTP 200, «Installation - Gitea»); **cert LE pendiente** por rate limit (ver nota PLAN-039) |
| open-webui | `docs/open-webui.md` | healthy — 2 contenedores (`open-webui` + `open-webui-ollama`); **sin Traefik por diseño** |
| pinepods | `docs/pinepods.md` | healthy — 3 contenedores (app + PostgreSQL + Valkey); router `podcasts.servidorlinux.es` (HTTP 200 PinePods); **cert LE pendiente** por rate limit |
| vector | `docs/vector.md` | healthy — log shipper, sin Traefik; sigue apuntando a `openobserve`, no desplegado (el sink reintenta) |

## Sin verificar E2E (11)

Quadlet y doc existen, pero **nunca se han desplegado ni verificado en el host real**:

authentik, caddy,
grafana-influx-telegraf,
immich, invidious, matrix, matrixmail,
nextcloud,
odoo, plausible,
wger.

## Notas

- Este documento se actualiza al cerrar cada ronda de verificación (añadir el stack a «Verificados
  E2E» y quitarlo de «Sin verificar»).
- Referencia del flujo de despliegue/purga: `docs/gestion-stacks-qctl.md`.
- Infraestructura de producción: usuario `runner` (uid 1002) en `new_atareao`, FQDN `servidorlinux.es`.
- ferrishare: el `--init` interactivo se automatizó con `ferrishare-init.py` (issue #11); ya no bloquea el despliegue.
- Certificados de las rondas E2E: desde PLAN-022 se usa el resolver `letsencrypt-staging` (CA staging de Let's Encrypt) para no consumir la cuota de producción (50 certs/dominio/168 h). Ver `docs/traefik.md`.
- PLAN-023 (issue #18): limpieza de follow-ups. Eliminados `dingpdf` (duplicado de `pdfding`) y `laverna` (abandonado); resueltas las colisiones de enrutado del apex `${FQDN}` (zennotes, umami, watchbeat, alloy → subdominio propio), del nombre global `grafana` (tick) y de host sin path (tick, matrix, miniflux).
- PLAN-024 (issue #19): auditados los 45 stacks multi-contenedor y documentados los invariantes de enrutado en `docs/traefik.md` (host único por router, nombres de router/servicio globales, apex `${FQDN}` sin dueño — lo atiende el catch-all de `errserve` —, y stacks sin router por diseño). Sin cambios de código; `huginn` no era un duplicado (es web + worker).
- PLAN-025 (issue #20): `errserve` pasa a poseer el apex `${FQDN}` con router propio (`errserve-apex`, `tls.certresolver=letsencrypt`) → `https://servidorlinux.es` sirve la página de error con **certificado LE válido** (antes: autofirmado). Corregido de paso el catch-all (`HostRegexp(.)&&!Path(/metrics)`: las labels de quadlet no admiten espacios). Volumen `huginn-huginn_mariadb` → `huginn-mariadb`. Docs: invariantes de enrutado #3 y #6.
- PLAN-026 (issue #21): el apex `${FQDN}` pasa de servir a **redirigir** (302) a la página de error (`errserve-apex` → `https://${FQDN}/404`, con `!Path(/404)` para evitar bucle). Además, 40 volúmenes normalizados a la convención `<stack>-<rol>` (fichero, `VolumeName=` y `Volume=`), sin cambios en prod. Sin cambios de cifras (127 / 55 / 68).
- PLAN-027 (issue #22): ronda E2E lote 1 (alloy, apimail, couchdb, dim, ghost, kanboard). Verificados y purgados: couchdb, dim, ghost, kanboard. Corregidos bugs latentes de `ghost` (url + bind `lig`→`lib`) y `kanboard` (bind `bar`→`var`). `apimail` funcional pero bloqueado por #23; `alloy` bloqueado por OIDC. Cifras: 127 = 59 verificados + 4 en producción + 2 bloqueados + 62 sin verificar.
- PLAN-030 (issue #25): ronda E2E lote 2 **completada** — verificados y purgados: `atuin`, `beszel`, `radicale`, `wakapi`, `wikijs` y `zincsearch`. Bugs latentes corregidos: atuin (imagen oficial + `Exec=start`, PG 18 con volumen en `/var/lib/postgresql`, red de BD), beszel (login por contraseña, agente SSH/TCP con clave del hub, volumen `beszel-socket` eliminado), radicale (router `expulsabot`→`radicale`, binds uid 1000, htpasswd apr1/md5), wikijs (`DB_HOST` `db`→`postgres`, service port 80→3000). Cifras: 127 = 65 verificados + 4 en producción + 2 bloqueados + 56 sin verificar.
- PLAN-031 (issue #26): ronda E2E lote 3 **completada** — verificados y purgados: `bookstack`, `dnote`, `focalboard`, `snibox`, `umami` y `hedgedoc`. Bugs latentes corregidos: umami (`Requires=`/`After=` → `umami-postgresql.service`), focalboard (PG 18 con volumen en `/var/lib/postgresql`, secretos `focalboard_postgres_password` + `focalboard_database_url`, bind `config.json` → `FOCALBOARD_DBTYPE=postgres`), bookstack (app en `bookstack.network`, binds separados app/BD, `APP_KEY` por secreto, `DB_USERNAME`/`DB_PASSWORD`), dnote (app en `dnote.network`, secreto único de BD, service port 3001), snibox (nginx en `snibox.network`, `snibox_postgres_password` compartido) y hedgedoc (`Requires=`/`After=` hacia MariaDB). Regla nueva: sin `PodmanArgs=--init` en imágenes LinuxServer.io (s6-overlay exige PID 1). Certificados con el resolver `letsencrypt-staging` (revertido después; producción sin labels staging). Cifras: 127 = 71 verificados + 4 en producción + 2 bloqueados + 50 sin verificar.
- PLAN-032 (issue #27): ronda E2E lote 4 **completada** — verificados y purgados: `wallabag`, `vscode`, `whisper`, `unbound`, `watchbeat` y `publirs`. Bugs latentes corregidos: wallabag (placeholder `SYMFONY__ENV__SERVER_NAME`), whisper (imagen `:latest` sin GPU + modelo `small` + host 9000→9001), unbound (publica 5353 y config por el include real de la imagen), watchbeat (issuer OIDC real + redirect al subdominio, healthcheck en `127.0.0.1` + `AddHost`), publirs (Traefik en `publirs.${FQDN}`, `crontab.txt` en croni, sin bind a `/etc/timezone`). Excepciones internas sin Traefik: `whisper` y `unbound`. Pendientes abiertos en la sección «Bloqueados / hallazgos». Certificados con el resolver `letsencrypt-staging` (revertido después; producción sin labels staging). Cifras: 127 = 77 verificados + 4 en producción + 2 bloqueados + 44 sin verificar.
- PLAN-035 (issue #30): ronda E2E lote 7 **completada** — verificados y purgados: `photoprism`, `rabbitmq`, `weaviate` y `wordpress`. Bugs latentes corregidos: photoprism (sin secretos ni `SITE_URL`; se añadió `photoprism_admin_password` + `SITE_URL`/`TZ`; sin `--init` porque la imagen ya trae s6-overlay; healthcheck por `curl` porque `photoprism status` no conecta), rabbitmq (volumen `mnseia`→`mnesia` con `:U`, secreto inexistente, usuario `admin`, healthcheck), weaviate (dejaba de publicar 8080/50051 sin auth: red propia + `NetworkAlias` y sin `PublishPort`) y wordpress (`Requires=` a units inexistentes, router `wp`→`wordpress` + `service.port=80`, secretos `type=env`, `WP_CONFIG_EXTRA` unificado; plantilla de wp1/wp2). `weaviate` es la excepción interna sin Traefik. Dos patrones nuevos documentados en «Bloqueados / hallazgos»: healthchecks que corren como root en imágenes con `gosu`/`su-exec`, e imágenes que migran a s6-overlay y rompen con `PodmanArgs=--init`. Certificados con el resolver `letsencrypt-staging` (revertido después; producción sin labels staging). Cifras: 127 = 92 verificados + 4 en producción + 3 bloqueados + 28 sin verificar.
- PLAN-036 (issue #31): ronda E2E lote 8 **completada** — verificados y purgados: `codimd`, `huginn`, `planka`, `facturascripts` y `postgres`. Bugs latentes corregidos: codimd (app en `codimd.network`, `CMD_*` + `CMD_DB_URL` por secreto, PG 17-alpine con healthcheck, comilla huérfana y binds → volúmenes `:U`), huginn (`DATABASE_HOST`/`ADAPTER`/`PORT`, `APP_SECRET_TOKEN` estable y dependencia de MariaDB), planka (app en `planka.network`, `Requires=`/`After=`, `BASE_URL` https y `TRUST_PROXY=true`), facturascripts (app en su red, MariaDB con root/BD, `FS_DB_*`/`FS_INITIAL_*`, volúmenes `:U` e instalación desatendida por POST a `/`) y postgres (pgAdmin en `postgres.network`; **pérdida de datos** de `postgres:latest` 18.x → pin `17-alpine` con `/var/lib/postgresql/data` y sin `AutoUpdate`). Tres patrones nuevos en «Bloqueados / hallazgos»: app y BD en redes distintas, `postgres:latest` = 18.x cambia la ruta del volumen, y clientes PG antiguos que necesitan `md5`. `grafana-influx-telegraf` se **aplaza a un plan propio** (solape con `openobserve` + `vector` + `alloy`). Certificados con el resolver `letsencrypt-staging` (revertido después; producción sin labels staging). Cifras: 127 = 97 verificados + 4 en producción + 3 bloqueados + 23 sin verificar.
- PLAN-037 (issue #32): ronda E2E lote 9 **completada** — verificados y purgados: `wordpress-wp1`, `wordpress-wp2` y `registry`. Bugs latentes corregidos: wordpress-wp1/wp2 (bind a un `wp-config.php` inexistente, volumen en `/var/www/html` en vez de `/var/www/html/wp-content`, **dos secretos distintos para el mismo password de BD**, sin `Requires=`/`After=` ni healthchecks, MariaDB sin pinnear) y registry (faltaban `config.yml` y `htpasswd`, host de Traefik placeholder `tu.${FQDN}`, `NGINX_PROXY_PASS_URL` como secreto). Dos patrones nuevos en «Bloqueados / hallazgos»: ruta del config de `registry` v3 y el 502 de `registry-ui` al recrear el registry. Certificados con el resolver de **producción** `letsencrypt` (CN reales para wp1/wp2/registry). Cifras: 127 = 100 verificados + 4 en producción + 3 bloqueados + 20 sin verificar.
- PLAN-039 (issue #33, sub-lote **10b**): `gitea`, `open-webui`, `pinepods` y `vector` **desplegados y corriendo** (units `active`, contenedores `healthy`; `open-webui-ollama` sin healthcheck). Routers registrados: `gitea.servidorlinux.es` y `podcasts.servidorlinux.es` (ambos HTTP 200); `open-webui` **sin Traefik por diseño** y `vector` es un log shipper (sin router). El **cert LE** de gitea/pinepods quedó pendiente por el **rate limit** de Let's Encrypt (50 certs/168 h, HTTP 429; bloqueante **externo**, no de configuración): Traefik sirve su cert por defecto hasta el reset (~20:05 UTC del 2026-11-13). Secretos creados: `gitea_db_password`, `open_webui_secret_key`, `pinepods_db_password`, `openobserve_root_password`. Follow-ups: el sink de `vector` apunta a `openobserve` (no desplegado → el sink reintenta) y queda pendiente el ingest de CrowdSec. Pendiente: purga de los stacks de ejemplo tras verificar el cert y decisión de conservar `vector`. Cifras: 127 = 104 verificados + 9 en producción + 3 bloqueados + 11 sin verificar.
