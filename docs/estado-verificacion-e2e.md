# Estado de verificación E2E de los stacks

Última actualización: 2026-11-10.

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
| Verificados E2E (probados y purgados) | 55 |
| En producción (desplegados y corriendo) | 4 (el stack `headscale` lleva 2 contenedores) |
| **Sin verificar E2E** | **68** |

## Verificados E2E (probados y purgados)

Todos entre el **2026-11-09** y el **2026-11-10**: desplegados, verificados end-to-end y **purgados** el mismo día (unit
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
| microbin | `docs/microbin.md` | PLAN-022 / #17 | 401 | 2 secretos; volumen nombrado `microbin-microbin` |
| pastebin | `docs/pastebin.md` | PLAN-022 / #17 | 303→200 | imagen `atareao/pastebin` desaparecida → upstream `mkaczanowski/pastebin` |

## En producción (desplegados y corriendo)

| Stack | Doc | Estado |
|---|---|---|
| errserve | `docs/errserve.md` | healthy |
| headscale | `docs/headscale.md` | healthy — 2 contenedores: `headscale` + `headscale-headplane` (doc en `docs/headplane.md`) |
| pocketid | `docs/pocketid.md` | healthy — proveedor OIDC |
| traefik | `docs/traefik.md` | healthy — edge |

## Sin verificar E2E (68)

Quadlet y doc existen, pero **nunca se han desplegado ni verificado en el host real**:

alloy, apimail, atuin, authentik, beszel, bookstack, caddy, cells,
chevereto, codimd, couchdb, crowdsec, dev, dim,
dnote, facturascripts, firefly,
focalboard, ghost, gitea, grafana-influx-telegraf, hedgedoc, huginn,
immich, invidious, jellystat, kanboard, matrix, matrixmail,
miniflux, miniflux-client, mtproxy, mumble, mysteryshack, nextcloud, nitter,
odoo, open-webui, photoprism,
pinepods, planka, plausible, postgres, publirs, rabbitmq, radicale,
registry, simple-torrent, snibox, socks5,
tick, umami, unbound, vector, vscode, wakapi,
wallabag, watchbeat, weaviate, webdav, wger, whisper, wikijs, wordpress, wordpress-wp1, wordpress-wp2,
zennotes, zincsearch.

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
