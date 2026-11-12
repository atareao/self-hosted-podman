# socks5 — Proxy SOCKS5 (go-socks5-proxy)

## Qué es

Stack de un **único contenedor** que expone un proxy SOCKS5 autenticado por usuario/password.

- **App / imagen (`Image=`):** `docker.io/serjs/go-socks5-proxy` (sin tag → `latest`), contenedor `socks5`.
- **Nº contenedores:** 1.
- **Red:** ninguna (`Network=` no declarado) → usa la red por defecto de Podman; **no** se une a `proxy.network` ni pasa por Traefik.
- **Dominio:** no aplica (no hay labels Traefik ni router).
- **Puerto interno / publicado:** `8388` interno, publicado en `8389` (`PublishPort=8389:8388`), expuesto directamente al host (no detrás de Traefik). El `8388` del host queda reservado para mtproxy.

## Ficheros

- Quadlet(s): `.config/containers/available/socks5/socks5.container`
- Volumen(es): ninguno (no hay fichero `.volume`).
- Config no secreta: no existe `.env` de stack (no hay `.config/socks5/`).
- Secretos: `socks5_proxy_password`.

## Cómo funciona

- **Red:** el quadlet no declara `Network=`, por lo que el contenedor queda en la red por defecto de Podman. No se integra con `proxy.network` ni con el enrutado de Traefik: el único acceso es el puerto publicado `8389` en el host.
- **Secretos:** `socks5_proxy_password` se inyecta como variable de entorno con `Secret=socks5_proxy_password,type=env,target=PROXY_PASSWORD` (driver `crypta`). No hay `EnvironmentFile`.
- **Socket del daemon:** no aplica (no monta `podman.sock`).
- **Healthcheck:** no define `Health*`.
- **Enrutado Traefik:** no hay labels `traefik.*`; el servicio no pasa por el edge router.
- **Hardening:** sección `Hardening` vacía (sin `User`, `NoNewPrivileges` ni `ReadOnly`).
- **AutoUpdate:** `AutoUpdate=registry` (imagen sin tag fijo).
- **Arranque:** `After=network-online.target`, `Restart=always`, `RestartSec=10s`, `StartLimitIntervalSec=300` y `StartLimitBurst=3` (van en `[Unit]`), `TimeoutStartSec=60`, `WantedBy=default.target`. `PodmanArgs=--init`.

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `PROXY_USER` | `socks5.container` (`Environment=`) | `someuser` | Usuario para autenticarse en el proxy SOCKS5 |
| `PROXY_PORT` | `socks5.container` (`Environment=`) | `8388` | Puerto de escucha interno del proxy |
| `PROXY_PASSWORD` | `socks5.container` (`Secret=socks5_proxy_password`) | *(secreto)* | Password del proxy SOCKS5 |
| `8389` | `socks5.container` (`PublishPort=8389:8388`) | `8389` | Puerto publicado en el host (el `8388` queda para mtproxy) |

No hay `.env` de stack para este servicio.

## Cómo habilitar / desplegar

1. Crear el secreto (con `podman secret create`, **nunca** `crypta store`):

```bash
printf '%s' '<valor>' | podman secret create socks5_proxy_password -
```

2. `cd .config/containers/available/socks5 && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups

- `PROXY_USER=someuser` es un valor placeholder: cámbialo antes de exponer el proxy.
- El `PublishPort=8389:8388` expone el proxy directamente al host sin TLS ni filtrado por Traefik; conviene restringir el acceso por firewall (nftables) al puerto 8389.
- El puerto `8388` del host queda reservado para mtproxy, por lo que no se publica en este stack.
- Sin healthcheck ni hardening.

## Verificación E2E (PLAN-033 / #28)

Desplegado y verificado el **2026-11-12**: unit `active`, contenedor up y escucha en 8389
(verificado por puerto). Servicio **interno, sin Traefik** (excepción documentada). Fix: quitado el
bind inexistente a `/etc/shadowsocks-rust/config.json`; publica 8389 (el 8388 del host queda
reservado a mtproxy); password por secreto `socks5_proxy_password`.

Follow-up: `PROXY_USER=someuser` es placeholder; el 8389 queda sin TLS ni filtrado.
