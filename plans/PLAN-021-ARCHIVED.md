---
# PLAN-021 — Probar stacks ntfy, opengist, filebrowser, silverbullet, yacht y dasherr

- **Issue:** #16
- **Estado:** completado
- **Fecha:** 2026-11-10

## Contexto
Ronda de verificación E2E del inventario `docs/estado-verificacion-e2e.md` (81 stacks sin verificar).
Lote de 6 stacks, todos de un solo contenedor. Flujo y purga según `docs/gestion-stacks-qctl.md `.
Infra de producción: usuario `runner` (uid 1002) en `new_atareao`, FQDN `servidorlinux.es`, acceso vía wrapper `rr `.

## Objetivos
- [x] Desplegar y verificar E2E los 6 stacks: ntfy, opengist, filebrowser, silverbullet, yacht, dasherr.
- [x] Corregir los bugs latentes detectados (quadlets y docs).
- [x] Purgar los 6 stacks (`qctl purge --secrets --images --data`) dejando prod limpio.
- [x] Actualizar `docs/estado-verificacion-e2e.md` (44 → 50 verificados, 81 → 75 sin verificar) y `HANDOFF.md ` (ambos actualizados).
- [x] Asegurar `docs/<stack>.md` de los 6 (ya existen; revisar contenido tras los cambios).
- [x] Archivar el plan: `plans/PLAN-021-ARCHIVED.md `.

## Stacks, configuración prevista y riesgos

| Stack | Dominio | Imagen | Servicio/port | Volúmenes/binds | Secretos | Riesgo latente a comprobar |
|---|---|---|---|---|---|---|
| ntfy | `ntfy.${FQDN}` | `docker.io/atareao/ntfy:v1.0` | 80 | bind `~/.config/ntfy/etc` | — | imagen no oficial; bind `/etc/ntfy` debe existir; healthcheck ausente |
| opengist | `gist.${FQDN}` | `ghcr.io/thomiceli/opengist:latest` | 6157 | `opengist-data.volume` | `opengist_og_gitea_client_key`, `opengist_og_gitea_secret` (OG_GITEA_CLIENT_KEY/SECRET) | router/service llamados `gist` (no `opengist`); secretos de Gitea obligatorios aunque la integración no se use; `UID/GID=1000` |
| filebrowser | `filebrowser.${FQDN}` | `docker.io/filebrowser/filebrowser` | 80 | binds `srv/`, `filebrowser.db`, `filebrowser.json`; `User=1000:1000` | — | los binds `filebrowser.db` y `filebrowser.json` deben existir como ficheros (si no, podman crea directorios → fallo); ficheros con uid mapeado → purga con `podman unshare rm -rf` |
| silverbullet | `silverbullet.${FQDN}` | `docker.io/atareao/silverbullet:latest` | 3000 | bind `~/.config/silverbullet/space` | `silverbullet_sb_user` (SB_USER) | `SB_USER` con formato `user:password`; imagen no oficial |
| yacht | `yacht.${FQDN}` | `docker.io/selfhostedpro/yacht` | 3000 | bind `~/.config/yacht/config` + podman.sock (ro) | — | socket podman.sock debe existir; sin healthcheck |
| dasherr | `nginx.${FQDN}` | `docker.io/atareao/dasherr` | 8080 | bind `~/.config/dasherr/htpasswd` | — | sin colisión real: `nginx` sirve `web.${FQDN}` y dasherr `nginx.${FQDN}` |

## Fases

### 1. Preparación (local)
- Revisar los 6 quadlets y sus docs; `qctl check` para colisiones (basename/ContainerName/router).
- Decidir el tratamiento de la colisión `dasherr` vs `nginx` (router `dasherr` sirve Host `nginx.${FQDN}`).

### 2. Despliegue y verificación E2E (prod, usuario `runner` vía `rr`)
Por cada stack, en orden:
1. `cd ~/.config/containers/available/<stack>` (tras `yadm pull`).
2. Crear los secretos necesarios con **`podman secret create`** (nunca `crypta store`):
   - opengist: `opengist_og_gitea_client_key`, `opengist_og_gitea_secret `.
   - silverbullet: `silverbullet_sb_user` (valor `user:password` ) .
3. Preparar los binds que lo requieran (ntfy `etc/`, filebrowser `srv/` + `filebrowser.db` + `filebrowser.json`, silverbullet `space/`, yacht `config/`, dasherr `htpasswd ` ) .
4. `qctl install` y `qctl start <unit>`.
5. Verificar los 5 puntos E2E: (a) unit `active`; (b) contenedor en `podman ps`; (c) router registrado en Traefik; (d) certificado LE válido para el dominio; (e) URL responde con el HTTP esperado (`curl -sS -o /dev/null -w '%{http_code}' ` ) .

### 3. Corrección de bugs latentes
- Arreglar quadlets/docs según hallazgos (delegar la escritura al subagente correspondiente ).
- Tras corregir, **recrear** el contenedor y, si Traefik no re-registra el router, `systemctl --user restart traefik `.

### 4. Purga
- Por stack: `qctl purge --secrets --images --data -y`; revisar restos manuales (secretos de Gitea de opengist no declarados, binds con uid mapeado con `podman unshare rm -rf` ) .
- Comprobar limpieza: `podman ps -a`, `podman volume ls`, `podman secret ls`, `podman images`, symlinks en `~/.config/containers/systemd/`.

### 5. Documentación y cierre
- Actualizar `docs/estado-verificacion-e2e.md`, `HANDOFF.md` y los `docs/<stack>.md` afectados.
- Renombrar el plan a `plans/PLAN-021-ARCHIVED.md `.

## Criterios de aceptación
- Los 6 stacks alcanzan los 5 puntos E2E (o el hallazgo documentado que lo impida ).
- Prod limpio al cerrar: solo `errserve`, `headscale`, `headscale-headplane`, `pocketid`, `traefik `.
- Inventario y HANDOFF actualizados; plan archivado.

## Follow-ups previstos
- Eliminar `dingpdf` (duplicado de `pdfding` ) .
- Decidir dominio propio de `dasherr` para evitar el choque con `nginx` .

## Resultado

Ejecutado y verificado en producción (`runner` en `new_atareao`) el 2026-11-10. Los 6 stacks
alcanzaron los 5 puntos E2E y se purgaron después.

### Verificación HTTP

| Stack | HTTP | Notas |
|---|---|---|
| ntfy | 200 | **Bug corregido:** la imagen oficial `binwiederhier/ntfy` no trae `CMD`; se añadió `Exec=serve`. |
| opengist | 302 | Router/servicio Traefik llamados `gist`; los secretos de Gitea (`og_gitea_client_key`/`og_gitea_secret`) son obligatorios. |
| filebrowser | 200 | Layout v2.63 con `/config` + `/database`; puerto 8080; binds creados con `podman unshare chown -R 1000:1000`. |
| silverbullet | 200 | Secreto `silverbullet_sb_user` (formato `user:password`). |
| yacht | 200 | **Bug corregido:** service port de Traefik 3000 → 8000. |
| dasherr | 401 | Auth básica con htpasswd (401 esperado sin credenciales); dominio `nginx.${FQDN}`. |

### Aclaración dasherr vs nginx

No hay colisión real: el stack `nginx` sirve `web.${FQDN}` y `dasherr` sirve `nginx.${FQDN}`.
Son dominios distintos, por lo que el riesgo anotado en la tabla queda descartado.

### Limpieza de restos de purga

Purga con `qctl purge --secrets --images --data -y` en los 6 stacks. Restos limpiados a mano:
binds con uid mapeado borrados con `podman unshare rm -rf` (filebrowser, dasherr, silverbullet)
y 6 volúmenes anónimos *dangling* eliminados con `podman volume rm`.

### Estado final de prod

Limpio: solo `errserve`, `headscale`, `headscale-headplane`, `pocketid` y `traefik`; 5 volúmenes
y los secretos de esos servicios.

---