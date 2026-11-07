# Rename del usuario de producción `podman` → `runner` (new_atareao)

## Qué es

Nota de la operación (PLAN-008) por la que el usuario de contenedores del host de producción
`new_atareao` (hostname `vmi3651091`, Ubuntu 26.04) dejó de llamarse `podman` (uid 1002) y ahora se
llama **`runner`**, conservando el mismo UID 1002. El nombre de login y la ruta del home cambian;
el UID, el systemd de usuario, linger, el storage y los volúmenes no cambian.

## Ficheros/entidades implicados

- `/etc/passwd`, `/etc/group`, `/etc/subuid`, `/etc/subgid` (renombrados a `runner`).
- Home movido: `/home/podman` → `/home/runner` (storage podman 2.3G incluido).
- `~/.local/share/containers/storage/db.sql` (StaticDir/GraphRoot/VolumeDir → `/home/runner`).
- `~/.local/share/containers/storage/secrets/secrets.json` (driver file de `cf_dns_api_token`).
- Volúmenes `pocketid-data`, `traefik-certs`, `traefik-plugins`, `umami-db-data` (intactos, por UID).
- Repo yadm: `~/.local/share/yadm/repo.git` (corregido `core.worktree`), `~/.config/yadm/`.
- Unidades systemd user **generadas** por quadlet (se regeneran con `daemon-reload`).
- DB de pocketid `pocketid-data/_data/pocket-id.db` (tabla `kv`).

## Cómo funciona

El sistema es rootless podman con quadlets. Las unidades se generan a partir de
`~/.config/containers/available/` (124 stacks) a `~/.config/containers/systemd/` usando `%h`
(punto de home) y nombres de volumen relativos, por lo que **no dependen del nombre del usuario**
sino del UID y del home. El rename solo exige: `usermod -l/-d -m`, reconfigurar subuid/subgid,
migrar `db.sql` (DB de podman), relinkear los symlinks de systemd y hacer `daemon-reload`. Todo lo
demás (ownership, volúmenes, linger, unidades) sigue ligado al UID 1002.

El secreto de PocketID viaja por el driver **shell** de podman: resuelve `crypta lookup` → `sops -d
~/.secrets/secrets.yml` (clave age en `~/.secrets/sops/age/key.txt`). Por eso hay que exportar en
cada shell: `SOPS_AGE_KEY_FILE`, `XDG_RUNTIME_DIR=/run/user/1002` y `PATH` con `$HOME/.local/bin`.

## Variables / config relevantes

| Variable | Valor |
|---|---|
| Usuario / uid | `runner` / `1002` |
| Home | `/home/runner` |
| `XDG_RUNTIME_DIR` | `/run/user/1002` |
| Shell | fish |
| FQDN usado por quadlets | `servidorlinux.es` |
| Generador quadlet | `/usr/libexec/podman/quadlet` |
| qctl | `~/.local/bin/qctl` (0.6.2) |

## Cómo verificar / operar

- `id runner` → uid 1002, home `/home/runner`.
- `podman ps` → pocketid/traefik/errserve `healthy` (vía `systemctl --user`).
- `qctl check` → exit 0 (2 WARN no bloqueantes).
- `https://auth.servidorlinux.es/` → 200 (traefik → pocketid).
- Sesión remota: `sudo -n -u runner -H bash -lc "..."` (el shell de `new_atareao` es fish) con
  `XDG_RUNTIME_DIR=/run/user/1002` y `PATH` extendido.

## Decisiones / follow-ups

- **Decisión**: recuperar la clave original de pocketid era inviable (rotada en el almacén);
  se optó por regenerar `jwt_private_key`/`session_key` perdiendo solo sesiones/tokens. Backup de
  la DB conservado como `pocket-id.db.PLAN008.bak`.
- **Follow-up**: el repo yadm del host está en `ca217bb` pero `origin/main` en GitHub en
  `9c34c83` (divergencia pre-existente con commits de docs/PLAN-003 sin empujar). Reconciliar con
  `yadm pull` en sesión del dotfiles repo, sin force-push.
- **Follow-up**: `qctl` en `runner` mantiene la version 0.6.2 (binario de `~/.local/bin/qctl`).
