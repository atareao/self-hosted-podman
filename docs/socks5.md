# socks5 — Proxy SOCKS5 (go-socks5-proxy)

## Qué es

Stack de un **único contenedor** que expone un proxy SOCKS5 autenticado por usuario/password.

- **App / imagen (`Image=`):** `docker.io/serjs/go-socks5-proxy` (sin tag → `latest`), contenedor `socks5`.
- **Nº contenedores:** 1.
- **Red:** ninguna (`Network=` no declarado) → usa la red por defecto de Podman; **no** se une a `proxy.network` ni pasa por Traefik.
- **Dominio:** no aplica (no hay labels Traefik ni router).
- **Puerto interno / publicado:** `8388` (`PublishPort=8388:8388`), expuesto directamente al host (no detrás de Traefik).

## Ficheros

- Quadlet(s): `.config/containers/available/socks5/socks5.container`
- Volumen(es): ninguno (no hay fichero `.volume`).
- Config no secreta: no existe `.env` de stack (no hay `.config/socks5/`).
- Fichero de config montado: `%h/.config/socks5/config.json` → `/etc/shadowsocks-rust/config.json` (bind mount, no versionado en el stack).
- Secretos: `socks5_proxy_password`.

## Cómo funciona

- **Red:** el quadlet no declara `Network=`, por lo que el contenedor queda en la red por defecto de Podman. No se integra con `proxy.network` ni con el enrutado de Traefik: el único acceso es el puerto publicado `8388` en el host.
- **Volumen:** bind mount del fichero de configuración `%h/.config/socks5/config.json` sobre `/etc/shadowsocks-rust/config.json` (con `:Z`). Es una ruta de host, no un volumen nombrado, y no está versionada.
- **Secretos:** `socks5_proxy_password` se inyecta como variable de entorno con `Secret=socks5_proxy_password,type=env,target=PROXY_PASSWORD` (driver `crypta`). No hay `EnvironmentFile`.
- **Socket del daemon:** no aplica (no monta `podman.sock`).
- **Healthcheck:** no define `Health*`.
- **Enrutado Traefik:** no hay labels `traefik.*`; el servicio no pasa por el edge router.
- **Hardening:** sección `Hardening` vacía (sin `User`, `NoNewPrivileges` ni `ReadOnly`).
- **AutoUpdate:** `AutoUpdate=registry` (imagen sin tag fijo).
- **Arranque:** `After=network-online.target`, `Restart=always`, `RestartSec=10s`, `StartLimitIntervalSec=300`, `StartLimitBurst=3`, `TimeoutStartSec=60`, `WantedBy=default.target`. `PodmanArgs=--init`.

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `PROXY_USER` | `socks5.container` (`Environment=`) | `someuser` | Usuario para autenticarse en el proxy SOCKS5 |
| `PROXY_PORT` | `socks5.container` (`Environment=`) | `8388` | Puerto de escucha del proxy |
| `PROXY_PASSWORD` | `socks5.container` (`Secret=socks5_proxy_password`) | *(secreto)* | Password del proxy SOCKS5 |
| `8388` | `socks5.container` (`PublishPort=8388:8388`) | `8388` | Puerto publicado en el host |

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
- El `PublishPort=8388:8388` expone el proxy directamente al host sin TLS ni filtrado por Traefik; conviene restringir el acceso por firewall (nftables) al puerto 8388.
- Inconsistencia a revisar: la imagen es `serjs/go-socks5-proxy` pero el fichero se monta en `/etc/shadowsocks-rust/config.json`; verificar que la ruta de configuración es la que espera la imagen.
- Sin healthcheck ni hardening.
