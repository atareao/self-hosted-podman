# PLAN-015 — Probar stacks cloudbeaver, custom-code-server, ferrishare, logseq, phpmyadmin y sftpgo

- **Issue GitHub:** #10
- **Fecha:** 2026-11-09
- **Estado:** en curso

## Objetivo

Segundo lote de 6 stacks sin verificar E2E (ver `docs/estado-verificacion-e2e.md`): desplegarlos en
producción (`new_atareao`, usuario `runner`), verificarlos end-to-end y **purgarlos** al terminar.
Todos de fricción cero (sin `Secret=`, sin OIDC, sin binds que necesiten `chown`).

## Stacks

| Stack | Imagen | Puerto Traefik | Almacenamiento | URL |
|---|---|---|---|---|
| cloudbeaver | `docker.io/dbeaver/cloudbeaver:latest` | 8978 | volumen `cloudbeaver-cloudbeaver` | cloudbeaver.servidorlinux.es |
| custom-code-server | `docker.io/atareao/custom-code-server` | 8443 (HTTPS) | volúmenes `custom-code-server-code_server_{data,workspace}` | code.servidorlinux.es |
| ferrishare | `ghcr.io/tobiasmarschner/ferrishare` | 3000 | volumen `ferrishare-data` | ferrishare.servidorlinux.es |
| logseq | `ghcr.io/logseq/logseq-webapp:latest` | 80 | ninguno | logseq.servidorlinux.es |
| phpmyadmin | `docker.io/library/phpmyadmin` | 80 | ninguno | myadmin.servidorlinux.es |
| sftpgo | `docker.io/drakkan/sftpgo:alpine` | 8080 | volúmenes `sftpgo-data`, `sftpgo-home` | sftpgo.servidorlinux.es |

- Sin `Secret=` ni OIDC. Tags de imagen verificados en sus registros (HTTP 200).
- **Riesgo conocido:** `custom-code-server` sirve HTTPS en 8443 pero su quadlet no declara
  `loadbalancer.server.scheme=https` -> probable 502 (mismo patrón que el bug de gokapi). Si ocurre,
  corregir el quadlet (y la doc) en esta ronda.

## Fase A — repo
- Crear este plan y el issue.

## Fase B — despliegue
1. `yadm pull` en prod.
2. Por stack: `cd .config/containers/available/<stack> && qctl install`.
3. `systemctl --user daemon-reload` y `start` de los seis.

## Fase C — verificación
- Unit `active`, contenedor arriba, router Traefik, cert LE y HTTP correcto en `https://<host>`.
- Reintentar 502 transitorios por arranque lento; corregir si es estructural (p. ej. scheme=https).

## Fase D — purga
1. `qctl uninstall` de los seis.
2. `podman volume rm` de `cloudbeaver-cloudbeaver`, `custom-code-server-code_server_data`, `custom-code-server-code_server_workspace`, `ferrishare-data`, `sftpgo-data`, `sftpgo-home`.
3. `podman rmi` de las seis imágenes.
4. Comprobar: sin symlinks, sin contenedores, sin volúmenes, sin imágenes.

## Criterios de aceptación
- Los seis verificados (unit + contenedor + router + cert + HTTP).
- Al terminar, TODO purgado.
- `docs/<stack>.md` con «Estado de despliegue»; `docs/estado-verificacion-e2e.md` actualizado; `HANDOFF.md` actualizado.

## Tareas
- [ ] Crear issue GitHub.
- [ ] Fase B: `yadm pull` + `qctl install` + start de los seis.
- [ ] Fase C: verificación end-to-end de cada stack (+ fix scheme=https si procede).
- [ ] Fase D: purga total (units + volúmenes + imágenes).
- [ ] Actualizar docs, `docs/estado-verificacion-e2e.md` y `HANDOFF.md`; archivar este plan.