# PLAN-008 — Renombrar el usuario de producción `podman` → `runner`  ✦ COMPLETADO ✦

> **Estado: COMPLETADO y ARCHIVADO — 2026-11-07.** Todas las fases ejecutadas y verificadas en el host de producción `new_atareao`. Véase la sección **Ejecución** al final.

## Objetivo

Renombrar el usuario de contenedores del host de producción `new_atareao` (hostname `vmi3651091`,
Ubuntu 26.04) de `podman` a `runner`, **conservando el UID 1002** para no tocar el systemd de
usuario, los volúmenes, el storage ni los ficheros. Todo el ecosistema (quadlets, yadm, unidades
generadas, contenedores) sigue siendo propiedad del UID 1002; solo cambia el nombre de login y la
ruta del home.

## Principio rector

**El rename es del nombre de login, NO del UID.** `usermod -l` mantiene el UID; el systemd de
usuario, linger, ownership de ficheros, storage y volúmenes siguen intactos. Las unidades
generadas por quadlet NO se editan: se regeneran solas tras `daemon-reload`. Los quadlets
fuente usan `%h`, así que seguirán resolviendo al home nuevo tras `usermod -d -m`.

## Fases ejecutadas

### Fase 0-3 — Pre-flight, parada, rename, reactivación (resumen)

1. Pre-flight OK: 3 servicios activos (pocketid/traefik/errserve), uid 1002, home 2.3G, quadlets 0
   referencias a `/home/podman`.
2. `usermod -l runner podman` + `usermod -d /home/runner -m runner` (UID constante 1002).
3. subuid/subgid reconfigurados a mano (`runner:231072:65536` / `runner:100000:65536`).
4. 7 symlinks de `~/.config/containers/systemd/` relinkeados (ROTOS=0).
5. `db.sql` de podman (StaticDir/GraphRoot/VolumeDir) → `/home/runner`; backups `.bak-*`.
6. Linger migrado y `/run/user/1002` recreado; 4 volúmenes intactos.
7. `systemctl --user daemon-reload` (regenera unidades con `%h` → /home/runner) + start.

### Fase 4 — Verificación integral ✔

1. `qctl check 0.6.2` exit 0 (solo 2 WARN no bloqueantes de naming: proxy.network/traefik y
   security.network/vector).
2. Generador quadlet real `/usr/libexec/podman/quadlet` operativo.
3. Los 3 contenedores `healthy`: pocketid, traefik, errserve — vía `systemctl --user`.
4. HTTPS real: `https://auth.servidorlinux.es/` → **200 (HTTP/2)** (traefik → pocketid).
5. `podman volume inspect` OK (mountpoints bajo `/home/runner`).

### Fase 5 — Limpieza ✔

1. `grep -rln "/home/podman" /etc/systemd /etc/cron* /usr/local/bin /etc/passwd /etc/group` → vacío.
2. `/home/podman` inexistente (el `-m` movió todo el contenido).
3. `core.worktree` del repo yadm corregido (heredaba `/home/podman`) y `fish_user_paths` actualizado.
4. Scripts temporales de la sesión y restos root de tests (`/tmp/pkdata*`) eliminados.
5. Docs del repo y HANDOFF actualizados.

## Incidencias resueltas durante la ejecución

- **traefik caído tras el rename**: el secreto `cf_dns_api_token` del driver **file** de podman
  apuntaba al path viejo `/home/podman/.../filedriver` en `secrets.json`. Corregido →
  `~/.local/share/containers/storage/secrets/secrets.json` (backups `.bak`, `.bak2`). traefik Up.
- **pocketid `failed to decrypt key`**: la clave que cifra `jwt_private_key.json`/`session_key.json`
  en la tabla `kv` de la DB no es recuperable (rotada en el almacén de crypta el 5-Nov, contenedor
  sano muerto con la clave en memoria durante el rename). Solución aplicada (con backup de la DB
  `.PLAN008.bak`): `DELETE FROM kv` de `jwt_private_key.json` + `session_key.json`, dejando
  `instance_id`; pocketid **regeneró ambas** con la clave actual y arrancó healthy. Impacto: se
  invalidaron las sesiones/tokens existentes (el admin `atareao` debe re-autenticarse con su
  passkey; la cuenta y sus datos —users/oidc/webauthn— se conservan).

## Rollback

1. `sudo usermod -l podman runner && sudo usermod -d /home/podman -m runner` (inverso exacto).
2. `systemctl --user daemon-reload && systemctl --user start pocketid.service traefik.service errserve.service`.
3. Verificar `podman ps` healthy. El UID nunca cambió → ownership y storage intactos en cualquier
   dirección.

## Criterio de éxito (verificado)

- `id runner` = uid 1002, home `/home/runner`; `id podman` → ya no existe. ✔
- Los 3 contenedores healthy vía systemd user. ✔
- `qctl check` (auditoría + fichero) exit 0. ✔
- yadm operativo (`yadm status` limpio, `core.worktree` corregido). ✔
- `/home/podman` sin restos; docs del repo actualizadas. ✔

## Referencias

- Repo `self-hosted-podman` / `plans/PLAN-008.md` (este fichero, ahora archivado).
- HANDOFF.md del repo qctl (notas de sesión 2026-11-07).
- Detalle del inventario real recogido en remoto (fases 0 y 1 del plan).
