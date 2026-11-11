# PLAN-025 — Apex con certificado válido y renombrado del volumen huginn

- **Issue:** #20
- **Estado:** en curso
- **Fecha:** 2026-11-11

## Contexto

Cierra los dos follow-ups vivos que dejó PLAN-024 (issue #19). El primero destapó un **defecto real**
durante el recon (no era cosmético como se creía).

## Hallazgos

1. **Apex `${FQDN}` — defecto de TLS.** El catch-all de `errserve`
   (`HostRegexp(.+) && !Path(/metrics)`, `priority=1`) **no declara `certresolver`**, así que
   `https://servidorlinux.es` se sirve con el certificado por defecto (autofirmado) de Traefik →
   **error de validación TLS**. `errserve.container` es el **único** contenedor enrutado del repo sin
   `certresolver`. El cert no se emite porque ningún router con `tls.certresolver` declara el apex.
2. **Volumen `huginn-huginn_mariadb`.** Nombre no sigue la convención `<stack>-<rol>`. `huginn` no
   está desplegado en producción (prod solo corre `errserve`, `headscale`, `headscale-headplane`,
   `pocketid`, `traefik`), así que no hay datos que migrar.

## Hallazgo adicional (durante la verificación local)

Las labels de quadlet **no pueden contener espacios**: systemd parte el `ExecStart` generado en cada
espacio y la label se trunca en el primero. Verificado en prod: el catch-all de `errserve` llegaba a
Traefik como `HostRegexp(`.+`)`, **perdiendo `&& !Path(`/metrics`)`**. Era el **único** caso del repo
(`headplane` ya usaba `Host(...)&&PathPrefix(...)` sin espacios y funciona). Se arregla la regla y se
documenta como invariante de enrutado #6.

## Objetivos

- [ ] Añadir el router `errserve-apex` a `errserve.container` con `Host(\`${FQDN}\`)`,
      `tls.certresolver=letsencrypt`, `service=errserve` y `middlewares=errpages`.
- [ ] Renombrar el volumen a `huginn-mariadb` (`.volume`, `VolumeName=`, `Volume=` del contenedor).
- [ ] Corregir `docs/traefik.md` (invariante 3 + auditoría) y `docs/huginn.md`.
- [ ] Actualizar `docs/estado-verificacion-e2e.md` y `HANDOFF.md`.
- [ ] Desplegar en prod (`yadm pull` + restart `errserve`) y verificar el apex.
- [ ] Archivar el plan: `plans/PLAN-025-ARCHIVED.md`.
- [ ] Corregir la label del catch-all de `errserve` (`HostRegexp(.+) && !Path(/metrics)` → sin espacios) y documentar el invariante «sin espacios en `Label=`» en `docs/traefik.md`.

## Fases

### 1. Quadlets

- `errserve.container`: seis labels nuevas tras las del catch-all:
  `errserve-apex.rule`, `.entrypoints`, `.service`, `.middlewares`, `.tls.certresolver`.
- `huginn`: `mv huginn-huginn_mariadb.volume huginn-mariadb.volume`; `VolumeName=huginn-mariadb`;
  `Volume=huginn-mariadb.volume:/var/lib/mysql:Z`.

### 2. Documentación

- `docs/traefik.md`: el invariante 3 pasa de «apex sin dueño» a «el apex lo posee `errserve` con
  certificado propio»; ajustar el bloque de auditoría.
- `docs/huginn.md`: quitar el follow-up del volumen y actualizar el nombre en la tabla de ficheros.

### 3. Verificación

- `quadlet -user -dryrun` sobre `errserve` y `huginn` → 0 errores.
- Auditoría de duplicados (`ContainerName`, routers, servicios, `Host(...)`).
- Prod: `https://servidorlinux.es` con certificado **válido** (no autofirmado); `auth` y `headscale` siguen 200.

### 4. Cierre

- Inventario + HANDOFF; renombrar a `plans/PLAN-025-ARCHIVED.md`; commit, push y cierre del issue #20.

## Criterios de aceptación

- `https://servidorlinux.es` responde con certificado LE válido (sin aviso del navegador).
- Volumen de huginn renombrado a `huginn-mariadb` en quadlet y docs; sin referencias al nombre viejo.
- Auditoría sin duplicados (salvo `headscale`+`headplane`).
- Prod sigue sana (5 contenedores; `auth` 200, `headscale` 200).

## Follow-ups previstos

- Decidir si el apex debe **redirigir** a un servicio concreto en vez de servir la página de error
  (cambio de 2 labels). Hoy: sirve `errserve`.
- Renombrar los demás volúmenes con patrón `<stack>-<stack>_<rol>` (`dev-dev_mariadb`, `chevereto-chevereto_mariadb`, `caddy-caddy_data`, …) — cosmético, fuera de alcance de este plan.
