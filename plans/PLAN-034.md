---
# PLAN-034 — Ronda E2E lote 6: tick, mumble, mysteryshack, cells, chevereto, jellystat

- **Issue:** #29
- **Fecha:** 2026-11-12
- **Estado:** EN CURSO (tick ✅ verificado E2E y purgado; 5 stacks pendientes)

## Objetivo

Continuar las rondas de verificación E2E de stacks en producción (`new_atareao`, usuario `runner`,
rootless Podman) con el lote 6: revisar estáticamente los 6 stacks candidatos, corregir los bugs
latentes detectados, desplegar, verificar los 5 puntos E2E y purgar (unit, volúmenes, binds,
secretos e imágenes) cada stack, dejando `docs/` y `docs/estado-verificacion-e2e.md` actualizados.

## Contexto

- Repo de dotfiles (yadm), no aplicación: sin build/test/lint ni código de aplicación. Queda fuera
  del flujo OpenSpec/TDD global; el equivalente a verificación es la comprobación E2E por CLI (5
  puntos), como en lotes 1–5.
- Inventario: 127 stacks = 83 verificados + 4 en producción + 2 bloqueados (`alloy`, `apimail`) +
  38 sin verificar. Al cerrar este lote, si los 6 pasan: 127 = 89 + 4 + 2 + 32.
- Candidatos: `tick`, `mumble`, `mysteryshack`, `cells`, `chevereto`, `jellystat`.
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

Excepción documentada: stacks sin dominio propio (servicio interno, sin labels Traefik, p. ej.
`mumble` por ser protocolo no HTTP/TCP-UDP) se verifican por puerto/API y se anota en su `docs/`.

## Observaciones estáticas previas (a confirmar en el despliegue)

- `tick`: 3 contenedores (`tick-grafana`, `tick-influxdb`, `tick-telegraf`), redes `tick.network` +
  `proxy.network`. Grafana en `tick.${FQDN}:3000`, InfluxDB en `influxdb.${FQDN}:8086`. **Sospechas:**
  (a) `tick-influxdb` monta `/var/lib/influxdb` pero `influxdb:latest` es 2.x (path real
  `/var/lib/influxdb2`, requiere setup inicial); (b) `tick-telegraf` monta
  `%h/.config/tick/telegraf.conf`, fichero que **no existe en el repo** (bind a fichero inexistente
  impide arrancar); (c) `tick-telegraf` sin `After=`/`Requires=` hacia InfluxDB/Grafana; (d) sin
  healthchecks en ninguno de los tres.
- `mumble`: 2 contenedores (`mumble`, `mumble-recorder`). **Sin labels Traefik**: publica
  `64738/tcp` y `64738/udp` con `PublishPort` (excepción documentada). **Sospechas:** (a)
  `MUMBLE_CONFIG_SSLCERT`/`SSLKEY` apuntan a `/certs/mumble.${FQDN}/cert.pem` dentro del volumen
  `mumble-certs` (vacío; el cert no se genera); (b) `docs/mumble.md` dice que se carga
  `EnvironmentFile=.config/mumble/mumble.env`, pero `mumble.container` **no** declara
  `EnvironmentFile` (sí lo hace `mumble-recorder`); (c) `mumble-recorder` apunta por defecto a
  `rtmp://127.0.0.1:1935` (sin servidor RTMP); (d) sin healthchecks.
- `mysteryshack`: 1 contenedor con Traefik. Revisar dominio, puerto y volumen.
- `cells`: 2 contenedores con Traefik. Revisar dependencia app/BD.
- `chevereto`: 2 contenedores con Traefik. Revisar app/BD y volumen de datos/imágenes.
- `jellystat`: 2 contenedores con Traefik. Revisar app/BD.

## Progreso

- **`tick`** — ✅ verificado E2E (5/5) y purgado el 2026-11-12. Correcciones: `telegraf.conf` creado y adaptado a Telegraf 1.40; `influxdb:2.7` + `/var/lib/influxdb2` + setup por secretos; `tick-telegraf` con `User=telegraf` y `--group-add keep-groups`; dependencias telegraf→influxdb y healthchecks en los 3. Purga sin `--data` (binds versionados). Nota: se usaron certificados LE de producción, no staging.
- **`mumble`** — ✅ verificado E2E (5/5, con excepción TCP/UDP: puerto 64738 tcp/udp publicado y alcanzable desde el exterior, proceso `mumble-server` vivo) y purgado el 2026-11-12. Corrección extra detectada en despliegue: healthcheck de `mumble-recorder` comprobaba `ffmpeg` (solo presente bajo audio) → ahora comprueba el proceso Python real.
- **`mysteryshack`** — ⛔ BLOQUEADO: su imagen `docker.io/atareao/mysteryshack:v1.0` no existe en ningún registro (nunca se publicó; el repo origen la construía localmente con base `ubuntu:18.04`/`libssl1.0.0`, hoy EOL). Documentado en `docs/mysteryshack.md`. Requiere decisión de re-publicar imagen o migrar a la upstream.
- **`cells`, `chevereto`, `jellystat`** — correcciones estáticas aplicadas y en `main`; aún **no desplegados**.
- **Hallazgo fuera de alcance:** `grafana-influx-telegraf` figura como verificado en `docs/estado-verificacion-e2e.md` pero está roto (su unit monta `%h/.config/grafana-influx-telegraf/telegraf.conf`, directorio inexistente en el repo, y su telegraf no lleva `User`/`keep-groups`). Requiere plan propio.

## Tareas

1. **Revisión estática** de los 6 stacks: canonical quadlet, `[Unit]`/`[Service]`, dependencias,
   puertos, binds, secretos, labels, healthcheck y `StartLimit*` en `[Unit]`.
2. **Corregir** bugs latentes detectados en el repo (binds faltantes, rutas, puertos, labels,
   `PodmanArgs=--init` en LinuxServer, path de volúmenes de PostgreSQL/InfluxDB 2.x, etc.).
3. **Crear** los secretos y ficheros de configuración necesarios en prod (`telegraf.conf`, certs de
   mumble, htpasswd, etc.) con `podman secret create` / `podman unshare`.
4. **Desplegar** cada stack: `unjinja` si aplica, `qctl install`, `systemctl --user daemon-reload`,
   `systemctl --user start <stack>`.
5. **Verificar los 5 puntos** (o la excepción documentada) por stack. Para TLS, usar
   `letsencrypt-staging` y revertir el label antes de purgar.
6. **Documentar** cada stack en `docs/<stack>.md` (estado, bugs corregidos, decisiones, follow-ups).
7. **Purgar** cada stack: `qctl uninstall`, `systemctl --user stop`, borrar volúmenes, binds, secretos
   e imágenes; borrar symlinks colgantes en `~/.config/containers/systemd/`.
8. **Actualizar** `docs/estado-verificacion-e2e.md` (mover a «Verificados E2E» y ajustar cifras).
9. **Commit** en `main` con gitmoji y **archivar** el plan como `plans/PLAN-034-ARCHIVED.md`.
10. **Actualizar** `HANDOFF.md` con el estado final.

## Riesgos / notas

- No publicar puertos <80 en rootless (limitación del host: `ip_unprivileged_port_start=80`).
- Healthchecks con `127.0.0.1`, nunca `localhost`.
- `podman secret create` siempre, nunca `crypta store`.
- Verificar SIEMPRE con `git diff` tras delegar ediciones; en este repo los subagentes
  `docker-expert` alucinan, usar `general` para editar ficheros.
- `tick` tiene routers `tick-grafana`/`tick-influxdb` para evitar la colisión global del nombre
  `grafana` con el stack `grafana-influx-telegraf` (resuelto en PLAN-023); no reintroducirla.
- La imagen `influxdb:latest` (2.x) puede exigir fijar versión y montar `/var/lib/influxdb2`.
- `mumble` es TCP/UDP puro: verificar por puerto/proceso, no por HTTPS.

## Cierre

- [x] Revisión estática de los 6 stacks
- [x] Correcciones aplicadas
- [ ] Secretos y configuración creados
- [ ] 6 stacks desplegados
- [ ] 5 puntos E2E verificados por stack
- [ ] `docs/` actualizados
- [ ] 6 stacks purgados
- [ ] Inventario y cifras actualizados
- [ ] Commit en `main` y plan archivado
- [ ] `HANDOFF.md` actualizado

---
FIN DEL CONTENIDO. No añadas nada más. Solo crea el fichero.