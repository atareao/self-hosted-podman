# Estado de verificación E2E de los stacks

Última actualización: 2026-11-09.

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
| Stacks en `.config/containers/available/` | 129 |
| Verificados E2E (probados y purgados) | 38 |
| En producción (desplegados y corriendo) | 4 (el stack `headscale` lleva 2 contenedores) |
| **Sin verificar E2E** | **87** |

## Verificados E2E (probados y purgados)

Todos el **2026-11-09**: desplegados, verificados end-to-end y **purgados** el mismo día (unit
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

## En producción (desplegados y corriendo)

| Stack | Doc | Estado |
|---|---|---|
| errserve | `docs/errserve.md` | healthy |
| headscale | `docs/headscale.md` | healthy — 2 contenedores: `headscale` + `headscale-headplane` (doc en `docs/headplane.md`) |
| pocketid | `docs/pocketid.md` | healthy — proveedor OIDC |
| traefik | `docs/traefik.md` | healthy — edge |

## Sin verificar E2E (87)

Quadlet y doc existen, pero **nunca se han desplegado ni verificado en el host real**:

alloy, apimail, atuin, authentik, beszel, bookstack, caddy, cells,
chevereto, codimd, couchdb, crowdsec, dagu, dasherr, dev, dim,
dingpdf, dnote, dockge, facturascripts, filebrowser, firefly,
focalboard, ghost, gitea, grafana-influx-telegraf, hedgedoc, homer, huginn,
immich, invidious, jellystat, kanboard, laverna, matrix, matrixmail, microbin,
miniflux, miniflux-client, mtproxy, mumble, mysteryshack, nextcloud, nitter, ntfy,
odoo, opengist, openobserve, open-webui, pastebin, pdfding, photoprism,
pinepods, planka, plausible, postgres, publirs, rabbitmq, radicale,
registry, rustfs, semaphore, silverbullet, simple-torrent, snibox, socks5,
storyteller, tick, umami, unbound, vaultwarden, vector, vscode, wakapi,
wallabag, watchbeat, weaviate, webdav, wger, whisper, wikijs, wordpress, wordpress-wp1, wordpress-wp2,
yacht, zennotes, zincsearch.

## Notas

- Este documento se actualiza al cerrar cada ronda de verificación (añadir el stack a «Verificados
  E2E» y quitarlo de «Sin verificar»).
- Referencia del flujo de despliegue/purga: `docs/gestion-stacks-qctl.md`.
- Infraestructura de producción: usuario `runner` (uid 1002) en `new_atareao`, FQDN `servidorlinux.es`.
- ferrishare: el `--init` interactivo se automatizó con `ferrishare-init.py` (issue #11); ya no bloquea el despliegue.
