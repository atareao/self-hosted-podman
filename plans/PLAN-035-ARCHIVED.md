---
# PLAN-035 — Ronda E2E lote 7: photoprism, rabbitmq, weaviate, wordpress

- **Issue:** #30
- **Fecha:** 2026-11-13
- **Estado:** PENDIENTE

## Objetivo

Continuar las rondas de verificación E2E en producción (`new_atareao`, usuario `runner`, rootless
Podman) con el lote 7: revisar estáticamente los 4 stacks candidatos, corregir los bugs latentes
detectados, desplegar, verificar los 5 puntos E2E y purgar (unit, volúmenes, binds, secretos e
imágenes) cada stack, dejando `docs/` y `docs/estado-verificacion-e2e.md` actualizados.

## Contexto

- Repo de dotfiles (yadm), no aplicación: sin build/test/lint ni código de aplicación. Queda fuera
  del flujo OpenSpec/TDD global; el equivalente a verificación es la comprobación E2E por CLI (5
  puntos), como en los lotes 1–6.
- Inventario de partida: 127 stacks = 88 verificados + 4 en producción + 3 bloqueados/hallazgos +
  32 sin verificar. Al cerrar este lote, si los 4 pasan: 127 = 92 + 4 + 3 + 28.
- Flujo de despliegue/purga: `docs/gestion-stacks-qctl.md`. Invariantes de enrutado:
  `docs/traefik.md`.
- Producción **solo** como `runner` vía wrapper `rr` desde `lorenzo`. Secretos con
  `podman secret create`, **nunca** `crypta store`. TLS con el resolver `letsencrypt-staging`
  durante la verificación y revertir antes del `yadm pull`.
- Un stack que no se resuelva en tiempo razonable se documenta, se purga y queda como bloqueado;
  el lote no se bloquea por él.

## Alcance

| Stack | Por qué entra en el lote |
|---|---|
| `photoprism` | Quadlet sin secreto de admin ni `site-url`, sin `--init`, healthcheck lento sin `HealthStartPeriod` y orden de bloque `Image` incorrecto. |
| `rabbitmq` | Bug duro: el volumen apunta a `mnesia` mal escrito (`mnseia`) y no hay `AutoUpdate` ni healthcheck. |
| `weaviate` | Expone 8080/50051 en el host (colisión potencial) y ningún healthcheck; imagen de 2024 sin red propia. |
| `wordpress` | `[Unit]` con dependencias inexistentes, routers `wp`, falta `service.port`, secreto `/run/secrets` y `WORDPRESS_CONFIG_EXTRA` duplicado. Será la plantilla de `wordpress-wp1`/`wordpress-wp2` (lote 9). |

## Criterio de «verificado E2E» (5 puntos)

1. El unit systemd queda `active`.
2. El contenedor arranca (`podman ps`, estado `healthy`).
3. Traefik registra el router (`traefik.enable=true`, router visible en el API/dashboard).
4. El certificado sirve el dominio con cadena válida (CA staging de Let's Encrypt).
5. La URL responde con el HTTP esperado.

Excepción documentada: stacks sin router HTTP propio —o cuyo protocolo principal no es HTTP— se
verifican por puerto/API y se anota en su `docs/`. En este lote aplica a `weaviate` (gRPC 50051,
validado internamente) y al puerto AMQP de `rabbitmq` (5672, validado con `rabbitmq-diagnostics`).

## Correcciones a aplicar

### `photoprism/photoprism.container`

- `[Container] / Image`: reordenar el bloque al orden canónico → `Image`, `ContainerName`,
  `AutoUpdate=registry`, `PodmanArgs=--init`.
- Añadir `PodmanArgs=--init` (imagen oficial, no LinuxServer.io).
- `Secrets`: añadir `Secret=photoprism_admin_password,type=env,target=PHOTOPRISM_ADMIN_PASSWORD`.
- `Environment`: añadir
  - `Environment=PHOTOPRISM_ADMIN_USER=admin`
  - `Environment=PHOTOPRISM_SITE_URL=https://photoprism.${FQDN}/`
  - `Environment=TZ=Europe/Madrid`
- `Volumes`: `Volume=%h/.config/photoprism/Import:/photoprism/import:ro` (el import es de solo
  lectura; `Pictures` y `Storage` siguen `:Z` y escribibles).
- `Healthcheck`: añadir `HealthStartPeriod=120s` (el indexado inicial puede tardar >60 s).

### `rabbitmq/rabbitmq.container`

- `Volumes`: corregir el typo → `Volume=rabbitmq-data.volume:/var/lib/rabbitmq/mnesia:Z`
  (sin la `/` final y con `mnesia` bien escrito).
- `Image`: añadir `AutoUpdate=registry`.
- `Environment`: `RABBITMQ_DEFAULT_USER=admin` (sustituye a `usuario`).
- `Healthcheck`: añadir
  - `HealthCmd=rabbitmq-diagnostics -q ping`
  - `HealthInterval=30s`, `HealthRetries=5`, `HealthTimeout=10s`, `HealthStartPeriod=30s`.

### `weaviate/weaviate.container`

- `Ports`: **eliminar** `PublishPort=8080:8080` y `PublishPort=50051:50051`; se accede por la red
  interna y Traefik (8080) y por `weaviate.network` (gRPC 50051).
- Crear `weaviate/weaviate.network` y declarar en el quadlet `Network=weaviate.network` +
  `NetworkAlias=weaviate`.
- `Healthcheck`: añadir
  - `HealthCmd=wget -q -O /dev/null http://127.0.0.1:8080/v1/.well-known/ready`
  - `HealthInterval=30s`, `HealthRetries=5`, `HealthTimeout=5s`, `HealthStartPeriod=20s`.
- Dejar constancia en `docs/weaviate.md`: 50051 es **gRPC** y se valida con `grpc_health_probe`
  desde dentro del contenedor/red (no por HTTP desde el host).
- Follow-up abierto (no se corrige en este lote): instancia **sin autenticación**
  (`AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED=true`) y versión `1.23.0` (2024) desde el registry
  antiguo `docker.io/semitechnologies`; el registry nuevo es `cr.weaviate.io`.

### `wordpress/wordpress.container`

- `[Unit]`:
  - `After=network-online.target wordpress-mariadb.service wordpress-valkey.service traefik.service`
  - `Requires=wordpress-mariadb.service wordpress-valkey.service`
  (sustituye a `After=wordpress.network mariadb.service valkey.service` / `Requires=mariadb.service
  valkey.service`, que apuntan a units que no existen).
- `Labels`: añadir `Label=traefik.http.services.wordpress.loadbalancer.server.port=80` y renombrar
  todos los routers `wp` → `wordpress` (`routers.wordpress.rule`, `.entrypoints`,
  `.tls.certresolver`, `.middlewares`).
- `Secrets`: `Secret=wordpress_db_password,type=env,target=WORDPRESS_DB_PASSWORD`; eliminar
  `Environment=WORDPRESS_DB_PASSWORD_FILE=/run/secrets/wordpress_db_password`.
- `Environment`: fusionar los dos `WORDPRESS_CONFIG_EXTRA` en una sola línea:
  `Environment="WORDPRESS_CONFIG_EXTRA=define('WP_REDIS_HOST', 'valkey'); if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') { $_SERVER['HTTPS'] = 'on'; } define('FORCE_SSL_ADMIN', true);"`
- `Image`: añadir `PodmanArgs=--init`.
- `Healthcheck`: añadir `HealthTimeout=5s` (junto a los existentes `HealthInterval=10s`,
  `HealthRetries=3`, `HealthStartPeriod=30s`).
- `[Service]`: `TimeoutStartSec=300` (60 s es insuficiente en el primer arranque).
- Añadir **newline final** al fichero (hoy termina sin `\n` en `WantedBy=default.target`).

### Saneo de acompañantes (wordpress = plantilla de wp1/wp2, lote 9)

- `wordpress/wordpress-mariadb.container`:
  - Secretos a `type=env`: `Secret=mariadb_root_password,type=env,target=MARIADB_ROOT_PASSWORD` y
    `Secret=wordpress_db_password,type=env,target=MARIADB_PASSWORD`; quitar los
    `MARIADB_ROOT_PASSWORD_FILE` / `MARIADB_PASSWORD_FILE` y adaptar el `HealthCmd` para usar
    `$MARIADB_ROOT_PASSWORD` en lugar de `$(cat /run/secrets/...)`.
  - Añadir `[Unit]` con `After=network-online.target` y mantener `StartLimitIntervalSec`/
    `StartLimitBurst`.
- `wordpress/wordpress-valkey.container`:
  - `[Unit]`: añadir `After=network-online.target` + `StartLimitIntervalSec=300` /
    `StartLimitBurst=3` (hoy solo tiene `Description`).
  - `[Service]` completo: `Environment=SOPS_AGE_KEY_FILE=…`, `Environment=PATH=…`,
    `Restart=always`, `RestartSec=10s`, `TimeoutStartSec=60` (hoy solo `Restart` y `ExecStartPost`).
  - `HealthCmd=valkey-cli ping | grep PONG || exit 1` (la imagen es valkey, no redis) y completar
    intervalos: `HealthInterval=10s`, `HealthRetries=5`, `HealthTimeout=5s`,
    `HealthStartPeriod=10s`.

## Secretos a crear

Solo dos secretos nuevos. Ejecutar como `runner` (vía `rr`) antes de `qctl install`:

```bash
openssl rand -base64 32 | podman secret create photoprism_admin_password -
openssl rand -base64 32 | podman secret create rabbitmq_default_pass -
```

- `wordpress_db_password` y `mariadb_root_password` **ya existen** en producción: **no** se
  recrean (recrearlos rompería el volumen de MariaDB y el login de WordPress).
- `rabbitmq_default_pass` ya lo referencia el quadlet actual: se crea si no existe y se comprueba
  con `podman secret ls`.
- Recordatorio: **nunca** `crypta store` para estos nombres; el driver `shell` resuelve por ID.

## Despliegue E2E

Todo con `rr "<comando>"`. Antes de empezar, bajar el resolver a `letsencrypt-staging` en los
`.container` implicados (o parche temporal equivalente) y verificar `podman secret ls`.

1. Preparar árbol de datos de photoprism:
   ```bash
   mkdir -p ~/.config/photoprism/Pictures ~/.config/photoprism/Storage ~/.config/photoprism/Import
   ```
2. Renderizar plantillas si hiciera falta (`unjinja`) para que existan los `.container`/`.network`
   reales en `available/<stack>/` antes de enlazar.
3. Por stack, desde su directorio:
   ```bash
   cd ~/.config/containers/available/<stack> && qctl install
   ```
4. `systemctl --user daemon-reload` y `qctl status` en cada stack.
5. Seguir el arranque: `journalctl --user -u <unit> -f` (`jcu`/`jcf`) hasta `healthy`.
6. Verificación de los 5 puntos:
   ```bash
   systemctl --user is-active <unit>
   podman ps --filter name=<container>
   curl -sS -o /dev/null -w '%{http_code}\n' https://<host>/
   echo | openssl s_client -connect <host>:443 -servername <host> 2>/dev/null | openssl x509 -noout -dates -issuer
   ```
   (el emisor debe ser la CA *staging* de Let's Encrypt).
7. Si tras recrear el contenedor no enruta, `systemctl --user restart traefik` y reintentar el
   `curl`.

## Verificación específica por stack

- **photoprism** (`https://photoprism.<fqdn>/`): 200/302 en `/`; login web con el usuario `admin` y
  la contraseña de `photoprism_admin_password`; `/library/browse` responde autenticado.
- **rabbitmq** (`https://mq.<fqdn>/`): 200 en la UI de management (redirect a `/#/login`);
  `podman exec rabbitmq rabbitmq-diagnostics -q ping` → `Ping succeeded`; login con
  `admin` / `rabbitmq_default_pass`.
- **weaviate**: `curl` interno a `http://weaviate:8080/v1/.well-known/ready` → 200 y `/v1/meta` con
  versión `1.23.0`; `grpc_health_probe -addr=weaviate:50051` desde dentro del contenedor o de otro
  contenedor de `weaviate.network`.
- **wordpress** (`https://blog.<fqdn>/`): 200/302 en `/`, 200 en `/wp-login.php`; comprobar que el
  entrypoint generó `wp-config.php` (`podman exec wordpress test -f /var/www/html/wp-config.php`);
  sin `WORDPRESS_DB_PASSWORD_FILE` en `podman inspect`.

## Purga y cierre

1. Por stack, desde su directorio: `qctl purge --secrets --images` (**sin** `--data`: no se borran
   los binds de usuario, solo unit, volúmenes nombrados, secretos e imágenes).
2. Comprobar el estado limpio:
   ```bash
   podman ps -a --filter name=<stack>        # 0 contenedores
   podman volume ls | grep <stack>           # 0 volúmenes
   podman secret ls | grep -E 'photoprism_admin_password|rabbitmq_default_pass'
   ls -l ~/.config/containers/systemd/ | grep <stack>   # 0 symlinks
   ```
   `wordpress_db_password` y `mariadb_root_password` **no** deben purgarse si otros stacks futuros
   los reutilizan; documentar la decisión.
3. Revertir el resolver `letsencrypt-staging` → `letsencrypt` en los quadlets y `daemon-reload`.
4. Actualizar `docs/estado-verificacion-e2e.md`:
   - Añadir las 4 filas a «Verificados E2E».
   - Quitar los 4 nombres de «Sin verificar E2E».
   - Ajustar el resumen a **127 = 92 verificados + 4 en producción + 3 bloqueados + 28 sin
     verificar** (aritmética comprobada: 88+4=92; 32−4=28; 92+4+3+28=127).
   - Añadir la entrada de PLAN-035 en «Notas» con los bugs corregidos.
5. Actualizar `docs/photoprism.md`, `docs/rabbitmq.md`, `docs/weaviate.md` y `docs/wordpress.md` con
   los hallazgos (bugs corregidos, valores finales, follow-ups abiertos).
6. Renombrar este plan a `plans/PLAN-035-ARCHIVED.md` y marcar todas las tareas.

## Riesgos conocidos

- `docker.io/photoprism/photoprism:latest` pesa ~2 GB: el `podman pull` inicial puede tardar varios
  minutos; no confundirlo con un cuelgue.
- El primer arranque de photoprism supera los 60 s (migraciones + generación de thumbnails):
  `HealthStartPeriod=120s` y `TimeoutStartSec` suficiente.
- `weaviate` publicaba 8080 en el host: colisión con otros servicios resueltos moviéndolo a
  `weaviate.network` (ya no hay puerto en el host).
- `rabbitmq:3-management` está en EOL: la corrección es funcional, pero la migración a una rama
  soportada (4.x) queda como follow-up.
- `PodmanArgs=--init` **no** es aplicable a imágenes LinuxServer.io (s6-overlay exige PID 1). En
  este lote ninguna de las imágenes lo es, pero se revisa antes de añadirlo.
- El driver de secretos `crypta` exige `SOPS_AGE_KEY_FILE` y `~/.local/bin` en el entorno del
  systemd user manager para los healthchecks (ver `docs/secrets-healthcheck.md`).

## Tareas

- [ ] Comprobar estado de partida: `podman secret ls`, resolver actual de los 4 stacks e
      inventario de `docs/estado-verificacion-e2e.md`.
- [ ] Corregir `photoprism.container` (secreto admin, env, `--init`, orden `Image`, `:ro`,
      `HealthStartPeriod`).
- [ ] Corregir `rabbitmq.container` (`mnesia`, `AutoUpdate`, usuario `admin`, healthcheck).
- [ ] Crear `weaviate.network` y corregir `weaviate.container` (sin `PublishPort`, red + alias,
      healthcheck, notas en `docs/`).
- [ ] Corregir `wordpress.container` (`[Unit]`, `service.port`, routers, secreto env, config extra,
      `TimeoutStartSec`, `--init`, `HealthTimeout`, newline final).
- [ ] Sanear `wordpress-mariadb.container` y `wordpress-valkey.container`.
- [ ] Crear los secretos `photoprism_admin_password` y `rabbitmq_default_pass`.
- [ ] Preparar `~/.config/photoprism/{Pictures,Storage,Import}`.
- [ ] Desplegar los 4 stacks (`qctl install` + `daemon-reload` + `qctl status`).
- [ ] Verificar los 5 puntos E2E por stack + verificación específica (login, diagnostics, gRPC,
      `wp-config.php`).
- [ ] Purgar los 4 stacks (`qctl purge --secrets --images`) y comprobar 0 contenedores/volúmenes/
      symlinks.
- [ ] Revertir `letsencrypt-staging` y `daemon-reload`.
- [ ] Actualizar `docs/estado-verificacion-e2e.md` (92 / 4 / 3 / 28) y los 4 `docs/<stack>.md`.
- [ ] Renombrar a `plans/PLAN-035-ARCHIVED.md`.
