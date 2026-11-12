# PLAN-033 — Ronda E2E lote 5: mtproxy, simple-torrent, socks5, webdav, miniflux-client, zennotes

- **Issue:** #28
- **Fecha:** 2026-11-12
- **Estado:** EN CURSO

## Objetivo

Continuar las rondas de verificación E2E de stacks en producción (`new_atareao`, usuario `runner`,
rootless Podman) con el lote 5: revisar estáticamente los 6 stacks candidatos, corregir los bugs
latentes detectados, desplegar, verificar los 5 puntos E2E y purgar (unit, volúmenes, binds,
secretos e imágenes) cada stack, dejando `docs/` y `docs/estado-verificacion-e2e.md` actualizados.

## Contexto

- Repo de dotfiles (yadm), no aplicación: sin build/test/lint ni código de aplicación. Queda fuera
del flujo OpenSpec/TDD global; el equivalente a verificación es la comprobación E2E por CLI (5
puntos), como en lotes 1–4.
- Inventario: 127 stacks = 77 verificados + 4 en producción + 2 bloqueados (`alloy`, `apimail`) +
  44 sin verificar. Al cerrar este lote, si los 6 pasan: 127 = 83 + 4 + 2 + 38.
- Candidatos: `mtproxy`, `simple-torrent`, `socks5`, `webdav`, `miniflux-client`, `zennotes`.
- Flujo de despliegue/purga: `docs/gestion-stacks-qctl.md`. Invariantes: `docs/traefik.md`.
- Producción **solo** como `runner` vía wrapper `rr`. Secretos con `podman secret create`, nunca
  `crypta store`. TLS con `letsencrypt-staging` durante la verificación y revertir antes del
  `yadm pull`.
- Un stack que no se resuelva en tiempo razonable se documenta, se purga y queda como bloqueado;
  el lote no se bloquea por él.

## Criterio de «verificado E2E» (5 puntos)

1. El unit systemd queda `active`.
2. El contenedor arranca (`podman ps`).
3. Traefik registra el router (label `traefik.enable=true`).
4. El certificado Let's Encrypt es válido para el dominio.
5. La URL responde con el HTTP esperado.

Excepción documentada: stacks sin dominio propio (servicio interno, sin labels Traefik) se
verifican por puerto/API y se anota en su `docs/`.

## Observaciones estáticas previas (a confirmar en el despliegue)

- `mtproxy`: sin Traefik; publica `8388:8889`; secreto `mtproxy_secret`. Verificar puerto real y
  respuesta del proxy.
- `simple-torrent`: sin Traefik; publica `50012:50012` TCP+UDP; **falta** el bind
  `.config/simple-torrent/cloud-torrent.yaml` en el repo; `Exec=-c /etc/cloud-torrent.yaml` y
  `AUTH=username:password` en claro. Revisar si la imagen admite `-c` o si el fichero debe existir.
- `socks5`: sin Traefik; publica `8388:8388`; **falta** el bind `.config/socks5/config.json`; la
  imagen es `serjs/go-socks5-proxy` pero el fichero se monta en `/etc/shadowsocks-rust/config.json`
  (inconsistencia ya anotada en `docs/socks5.md`).
- `webdav`: Traefaik `webdav.${FQDN}` puerto 8080; **falta** el bind `.config/webdav/htpasswd` (auth
  básica). Sin `HealthCmd` declarado.
- `miniflux-client`: sin Traefik ni puerto; es un cliente/worker. 4 secretos y `EnvironmentFile`
  existente. Verificar que arranca y que no depende de `miniflux` (no está desplegado).
- `zennotes`: Traefik `zennotes.${FQDN}` puerto 7878; `HealthCmd` propio, `User=1000:1000`, dos
  volúmenes; `EnvironmentFile` existente. Revisar permisos de los volúmenes.

## Tareas

1. **Revisión estática** de los 6 stacks: canonical quadlet, `[Unit]`/`[Service]`, dependencias,
   puertos, binds, secretos, labels, healthcheck y `StartLimit*` en `[Unit]`.
2. **Corregir** bugs latentes detectados en el repo (binds faltantes, rutas, puertos, labels,
   `PodmanArgs=--init` en LinuxServer, etc.).
3. **Crear** los secretos y ficheros de configuración necesarios en prod (htpasswd, config.json,
   cloud-torrent.yaml, tokens) con `podman secret create` / `podman unshare`.
4. **Desplegar** cada stack: `unjinja` si aplica, `qctl install`, `systemctl --user daemon-reload`,
   `systemctl --user start <stack>`.
5. **Verificar los 5 puntos** (o la excepción documentada) por stack. Para TLS, usar
   `letsencrypt-staging` y revertir el label antes de purgar.
6. **Documentar** cada stack en `docs/<stack>.md` (estado, bugs corregidos, decisiones, follow-ups).
7. **Purgar** cada stack: `qctl uninstall`, `systemctl --user stop`, borrar volúmenes, binds, secretos
   e imágenes; borrar symlinks colgantes en `~/.config/containers/systemd/`.
8. **Actualizar** `docs/estado-verificacion-e2e.md` (mover a «Verificados E2E» y ajustar cifras).
9. **Commit** en `main` con gitmoji y **archivar** el plan como `plans/PLAN-033-ARCHIVED.md`.
10. **Actualizar** `HANDOFF.md` con el estado final.

## Riesgos / notas

- `simple-torrent` y `socks5` no tienen ficheros de configuración en el repo: decidir si se crean
  con valores por defecto o se ajusta el unit para no depender de ellos.
- `miniflux-client` puede requerir `miniflux` desplegado; si no, verificar solo el arranque y anotar
  la dependencia.
- `zennotes` con `User=1000:1000`: `podman unshare chown -R 1000:1000` en los volúmenes.
- No publicar puertos <80 en rootless (limitación del host).
- Healthchecks con `127.0.0.1`, nunca `localhost`.
- Verificar SIEMPRE con `git diff` tras delegar ediciones; en este repo los subagentes
  `docker-expert` alucinan, usar `general` para editar ficheros.

## Cierre

- [ ] Revisión estática de los 6 stacks
- [ ] Correcciones aplicadas
- [ ] Secretos y configuración creados
- [ ] 6 stacks desplegados
- [ ] 5 puntos E2E verificados por stack
- [ ] `docs/` actualizados
- [ ] 6 stacks purgados
- [ ] Inventario y cifras actualizados
- [ ] Commit en `main` y plan archivado
- [ ] `HANDOFF.md` actualizado