# PLAN-020 — IP real del cliente en apps detrás de Traefik (proxy de confianza)

- **Issue GitHub:** #15
- **Fecha:** 2026-11-10
- **Estado:** completado

## Objetivo

Que las apps detrás de Traefik registren la **IP real del cliente** (la del proxy de confianza) en lugar de la IP interna de podman (10.89.0.85 = Traefik en la red `proxy`). Incluye:

1. Corregir `pocketid` (`TRUST_PROXY=false` → `true`).
2. Documentar el patrón: guía `docs/trusted-proxy.md` + regla en `AGENTS.md`, con tabla app→variable.
3. Desplegar y verificar en producción.

## Contexto (diagnóstico verificado en `new_atareao`)

- **Sockets OK**: `http.socket`/`https.socket` bindean 80/443; Traefik hereda los FDs (`ss -tlnp` los comparte traefik+conmon; `systemctl` muestra `TriggeredBy: http.socket https.socket`; arranque con `--preserve-fds`).
- **Traefik ve la IP real**: el `ClientHost` del access log son IPs públicas. En `podman logs traefik` los `10.89.x` que aparecen son `ServiceAddr`/`ServiceURL` = backend **destino** (10.89.0.3 = errserve), no el cliente.
- **Causa real**: las apps no honran `X-Forwarded-For` (lo envía Traefik). Evidencia: `pocketid` registra 10.89.0.85 (Traefik).
- Único stack con trusted-proxy: `headscale` (`trusted_proxies: 10.89.0.0/24` en `config.yaml.jinja`).

## Tareas

- [x] T1. `pocketid.container`: `Environment=TRUST_PROXY=true` (con comentario explicativo).
- [x] T2. Crear `docs/trusted-proxy.md`: qué es, cómo verificar, tabla app→variable→valor, nota de seguridad (solo Traefik alcanza la red `proxy`, así que confiar en XFF es seguro).
- [x] T3. `AGENTS.md`: nueva sección "IP real del cliente / proxy de confianza" con la regla y el patrón.
- [x] T4. Deploy en `new_atareao` (usuario `runner`, wrapper `rr`): push → `yadm pull` → `systemctl --user daemon-reload` → `systemctl --user restart pocketid` → verificar IP real en logs.
- [x] T5. Commit gitmoji en `main` (el repo trabaja directo en `main`).

## Verificación

- `podman logs pocketid` muestra una IP pública real, no `10.89.0.85`.
- Solicitud desde fuera (navegador/curl) → la app registra esa IP.

## Resultado (verificado en `new_atareao`)

- pocketid: `TRUST_PROXY=true` desplegado; en sus logs aparece `ip=139.47.26.33` (IP pública real)
  y ya no `10.89.0.x`.
- Desplegado con: commit en `main` → `yadm pull` (como `runner`) → `daemon-reload` → `restart pocketid`.
- Hallazgo: al **recrear** un contenedor (`systemctl --user restart <stack>`), Traefik puede no
  re-registrar su router (el tráfico cae al catch-all de `errserve`, router `errserve-catchall@docker`);
  se resolvió con `systemctl --user restart traefik`. Documentado como gotcha en `AGENTS.md`.

## Follow-ups

- Al reconstruir cada stack, añadir su variable de trusted-proxy (ver `docs/trusted-proxy.md`).
- No hay fix global posible en Traefik: es configuración por app.