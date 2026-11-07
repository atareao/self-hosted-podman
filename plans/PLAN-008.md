# PLAN-008 — Renombrar el usuario de producción `podman` → `runner`

## Objetivo

Renombrar el usuario de contenedores del host de producción `new_atareao` (hostname `vmi3651091`,
Ubuntu 26.04) de `podman` a `runner`, **conservando el UID 1002** para no tocar el systemd de
usuario, los volúmenes, el storage ni los ficheros. Todo el ecosistema (quadlets, yadm, unidades
generadas, contenedores) sigue siendo propiedad del UID 1002; solo cambia el nombre de login y la
ruta del home.

## Contexto verificado en el host (2026-11-07)

- Usuario actual: `podman` (uid 1002), home `/home/podman`, shell fish. `Linger=yes`.
- Contenedores en marcha como unidades systemd **generadas** por quadlet: `pocketid` (Up 47h),
  `traefik` (Up 14h), `errserve` (Up 1h) — todas healthy. Todas viven en `systemctl --user`
  (bus `/run/user/1002`).
- Stacks root: `~/.config/containers/available/` → **124 stacks**; `~/.config/containers/systemd/`
  → 7 ficheros fuente.
- Storage podman: `~/.local/share/containers/` = **2.3G** (overlay + volúmenes nombrados:
  `umami-db-data`, `traefik-certs`, `traefik-plugins`, `pocketid-data`).
- Quadlets fuente: **0** referencias a `/home/podman` ni `User=podman` (usan `%h` y nombres de
  volumen relativos). No hay unidades `.service` hardcodeadas en `~/.config/systemd/user/`
  (0 ficheros; las unidades son generadas por quadlet).
- Sin crontab, sin sudoers, sin units de systemd del sistema que nombren a `podman`.
- `yadm` clona `https://github.com/atareao/self-hosted-podman.git` (repo de este plan); config en
  `~/.config/yadm/`. SSH key `~/.ssh/id_gitea.pub`.
- Binarios en `~/.local/bin/`: crypta, jinrender, nevi, qctl (0.6.2), sops, starship, yq.
- `qctl 0.6.2` desplegado (fix multi-path del generador quadlet ya activo).

## Principio rector

**El rename es del nombre de login, NO del UID.** `usermod -l` mantiene el UID; el systemd de
usuario, linger, ownership de ficheros, storage y volúmenes siguen intactos. Las unidades
generadas por quadlet NO se editan: se regeneran solas tras `daemon-reload`. Los quadlets
fuente usan `%h`, así que seguirán resolviendo al home nuevo tras `usermod -d -m`.

## Fases de ejecución (orden estricto)

### Fase 0 — Pre-flight (verificación, sin cambios)

1. Backup del estado: `systemctl --user list-units --type=service --state=running` como podman —
   esperado 3+ unidades.
2. `podman ps` — esperados pocketid/traefik/errserve healthy.
3. Registrar GUID/UID: `id podman` (uid 1002) y `ls -n ~podman/` para confirmar owner 1002.
4. Tamaño del home: `du -sh /home/podman` (≈2.3G storage incluido) y **espacio libre en
   `/home`** (`df -h /home`) suficiente para el `mv` (2.3G + margen).
5. Confirmar que no hay sesiones logueadas activas: `loginctl list-sessions` (solo `podman`
   por linger/systemd no interactivo; no debe haber terminales).
6. Confirmar DNS/rutas: los quadlets usan `${FQDN}`, no cambian con el rename.

### Fase 1 — Parada controlada de los contenedores

1. Como `podman`: `systemctl --user stop pocketid.service traefik.service errserve.service`
   (y cualquier otra unidad generated en marcha — revisar `systemctl --user list-units
   --type=service --state=running`).
2. Verificar: `podman ps --format "{{.Names}} {{.Status}}"` → 0 contenedores.
3. Esto evita que conmon/podman escriban en el storage mientras se mueve el home.

### Fase 2 — Rename y movimiento del home

1. `sudo usermod -l runner podman` → cambia el nombre de login, **UID sigue 1002**.
2. `sudo usermod -d /home/runner -m runner` → mueve el home completo (incluido el storage 2.3G)
   y actualiza `/etc/passwd`.
3. Verificar: `id runner` (uid 1002), `ls -ld /home/runner` (owner runner/1002), y
   `getent passwd runner` → home `/home/runner`.

### Fase 3 — Reactivación

1. Como `runner`: `loginctl enable-linger runner` (mismo UID, el linger existente sigue; se
   refuerza por nombre nuevo por si acaso).
2. `systemctl --user daemon-reload` → quadlet regenera las unidades con `%h` → `/home/runner`.
3. `systemctl --user start pocketid.service traefik.service errserve.service`.
4. Verificar: `podman ps` → los 3 healthy; `systemctl --user list-units --type=service
   --state=running`.

### Fase 4 — Verificación integral

1. `qctl check` (auditoría stacks root, usuario runner) → exit 0.
2. `qctl check <un quadlet real>` → exit 0, generador `/usr/libexec/podman/quadlet` operativo.
3. `yadm status` y `yadm remote get-url origin` → sigue apuntando a `self-hosted-podman.git`;
   hacer `yadm pull` de prueba.
4. Probar acceso a un servicio público (p. ej. HTTPS de traefik o un endpoint conocido) que
   dependa de los contenedores.
5. `~/.local/bin/qctl --version` → 0.6.2.

### Fase 5 — Limpieza

1. Confirmar que nada referencia `/home/podman`:
   `grep -rln "/home/podman" /etc/systemd /etc/cron* /usr/local/bin 2>/dev/null` → vacío.
2. NO borrar `/home/podman` viejo si quedó algo (el `-m` debería haberlo movido todo): verificar
   que esté vacío o inexistente antes de decidir.
3. Actualizar la doc del repo: `docs/` (errserve.md, gestion-stacks-qctl.md, etc.) y `AGENTS.md`
   si mencionan el usuario `podman` o `/home/podman`.

## Rollback (si algo falla)

1. `sudo usermod -l podman runner && sudo usermod -d /home/podman -m runner` (inverso exacto).
2. `systemctl --user daemon-reload && systemctl --user start pocketid.service traefik.service errserve.service`.
3. Verificar `podman ps` healthy. El UID nunca cambió → ownership y storage intactos en cualquier
   dirección.

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Storage 2.3G moviéndose con contenedores escribiendo | Fase 1 para todo antes del `-m` |
| Unidades generadas apuntando a rutas viejas | Quadlets con `%h` → regeneran solas con `daemon-reload` (Fase 3) |
| Algo en el sistema referencia `podman` por nombre | Pre-flight Fase 0.5 + grep de Fase 5; nada encontrado hoy |
| Fallo a mitad del rename | UID constante → rollback 2 comandos, sin pérdida de datos |
| `mv` incompleto del home | Verificar en Fase 2.3; `du` comparado antes/después |

## Criterio de éxito

- `id runner` = uid 1002, home `/home/runner`; `id podman` → ya no existe.
- Los 3 contenedores vuelven a estar healthy vía systemd user.
- `qctl check` (auditoría + fichero) exit 0.
- yadm operativo; docs del repo actualizadas; `/home/podman` sin restos.

## Referencias

- Notas de sesión qctl 2026-11-07 (HANDOFF.md del repo qctl): despliegue de qctl 0.6.2 en el
  usuario podman, auditoría del host, decisión de renombrar a `runner`.
- Detalle del inventario real recogido en remoto (fases 0 y 1 del plan).
