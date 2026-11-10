# headscale

Servidor de control self-hosted compatible con Tailscale, desplegado como stack de quadlets Podman rootless detrás de Traefik.

- **Stack:** `headscale`
- **Dominio público:** `headscale.${FQDN}`
- **Issue GitHub:** #3
- **Plan:** `plans/PLAN-009.md`

## Ficheros implicados

| Ruta | Descripción |
|---|---|
| `.config/containers/available/headscale/headscale.container` | Quadlet principal del stack. |
| `.config/containers/available/headscale/headscale-data.volume` | Volumen nombrado `headscale-data`, montado en `/var/lib/headscale` (estado: sqlite, claves noise/derp). |
| `.config/headscale/config.yaml.jinja` | Plantilla de configuración; se renderiza a `.config/headscale/config.yaml` con `unjinja` (yadm). El render está gitignored vía `.config/headscale/.gitignore`. |
| `.config/headscale/headscale.env` | Config no secreta (TZ). Se cargan también los `.env.local` por máquina. |
| `.config/traefik/dynamic/headscale.yml` | Define el `TLSOption` `headscale-http1` (ALPN forzado a `http/1.1`). |

## Cómo funciona

- headscale escucha HTTP en `0.0.0.0:8080`; Traefik termina TLS y publica en `https://headscale.<FQDN>`.
- Métricas en `0.0.0.0:9090` (solo red interna).
- Publica UDP/3478 (STUN) para el DERP embebido (region_id 999, "Headscale Embedded DERP").
- Base de datos sqlite en `/var/lib/headscale/db.sqlite`; claves en `/var/lib/headscale/noise_private.key` y `/var/lib/headscale/derp_server_private.key`.
- **MagicDNS** activo con `base_domain: tailnet.<FQDN>` (debe ser distinto del dominio de `server_url`).
- `trusted_proxies: 10.89.0.0/24` = subred de `proxy.network` (Traefik), para honrar `X-Forwarded-For`.

## Decisión crítica: por qué el TLSOption

El protocolo de control de Tailscale (TS2021) hace un HTTP Upgrade con método POST y valor `tailscale-control-protocol`. Traefik **solo** procesa upgrades de tipo `websocket`; sobre HTTP/2 el Upgrade se descarta y el cliente se queda colgado durante el registro.

La solución es el `TLSOption` `headscale-http1@file`, que fuerza HTTP/1.1 por ALPN **solo** en el router de headscale. Referencia: [traefik/traefik#12609](https://github.com/traefik/traefik/issues/12609).

## Variables / config

- No requiere secretos propios: **no hay `Secret=`** en el quadlet.
- El único driver de configuración es `config.yaml` (renderizado desde `config.yaml.jinja`).
- `TZ` se define en `headscale.env`.

## Cómo habilitar y desplegar

En el host de apps, como `runner`:

1. `cd ~/.config/containers/available/headscale && qctl install`
2. `systemctl --user daemon-reload`
3. Renderizar config: `unjinja` (o `yadm pull`, que lo hace solo).
4. `systemctl --user start headscale`
5. Comprobar: `qctl status`, `jcu headscale`, y `curl https://headscale.<FQDN>/health` → `{"status":"pass"}`.

## Uso básico tras arrancar

- Crear usuario:

  ```bash
  podman exec headscale headscale users create <nombre>
  ```

- Crear preauthkey:

  ```bash
  podman exec headscale headscale preauthkeys create --user <id> --reusable --expiration 24h
  ```

- Con el socket unix dentro del contenedor también se puede operar directamente con:

  ```bash
  headscale -c /etc/headscale/config.yaml ...
  ```

## Follow-ups / notas

- Publicar/abrir **UDP/3478** en el firewall del host para que el STUN del DERP embebido sea alcanzable.
- Si `proxy.network` cambia de subred, actualizar `trusted_proxies`.
- No hay SELinux en este host; `SecurityLabelDisable=true` es inocuo.
- Los clientes Tailscale se unen con:

  ```bash
  tailscale up --login-server https://headscale.<FQDN> --authkey <key>
  ```

- Dispositivos **Android**: guía paso a paso en `docs/android.md`.

## Desplegado en producción

Estado: **activo y healthy** en el host `new_atareao` (usuario `runner`), proxy Traefik correcto.

Verificado:
- `https://headscale.<FQDN>/health` → `{"status":"pass"}` con certificado Let's Encrypt válido.
- Router Traefik `headscale@docker` activo; **HTTP/1.1 negociado** (gracias al `TLSOption`).
- El endpoint `POST /ts2021` con `Upgrade: tailscale-control-protocol` entra en la ruta Noise de headscale (el upgrade custom se reenvía).

## Gotchas (aprendidos al desplegar)

1. **El comando `serve` es obligatorio.** El entrypoint de la imagen (`/ko-app/headscale`) no añade subcomando; sin `Exec=serve` el contenedor imprime la ayuda y sale en bucle.
2. **Healthcheck en forma exec (JSON), no shell.** La imagen headscale es `ko`/scratch: **no tiene `/bin/sh`**. Con `HealthCmd=/ko-app/headscale health` podman lo ejecuta vía `sh` y falla → contenedor `unhealthy`. **Traefik NO registra el router de un contenedor `unhealthy`** (verificado: un contenedor unhealthy queda sin router y cae al catch-all). Por eso se usa:
   ```
   HealthCmd=["/ko-app/headscale","health"]
   ```
   Regla general para este repo: cualquier imagen sin shell debe declarar el healthcheck en forma exec.
3. **`trusted_proxies`** debe coincidir con la subred de `proxy.network`.

## Conectar un cliente Tailscale

En el cliente (con el binario `tailscale`):
```
tailscale up --login-server https://headscale.<FQDN> --authkey <PREAUTHKEY>
```
Generar una preauthkey en el servidor:
```
podman exec headscale headscale preauthkeys create --user <ID_NUMERICO> --reusable --expiration 24h
```
(`--user` exige el **ID numérico**, no el nombre; se obtiene con `headscale users list`.)

## Headplane (UI web)

El stack incluye **Headplane**, una UI web para gestionar el tailnet, en el **mismo dominio bajo
`/admin`**: `https://headscale.<FQDN>/admin`. Es un componente del propio stack (unit
`headscale-headplane.container`), con integración completa con Podman.

- Login con una **API key** de Headscale: `podman exec headscale headscale apikeys create --expiration 90d`.
- El healthcheck del contenedor está **desactivado** (`HealthCmd=none`): la imagen es distroless y su
  healthcheck heredado (`CMD-SHELL`) falla con exit 125, lo que dejaba el contenedor no-healthy y
  **Traefik no registraba el router**.
- La regla Traefik usa `Host(...)&&PathPrefix(`/admin`)` **sin espacios** (systemd parte el valor del
  label por espacios).

Detalle completo en [`docs/headplane.md`](headplane.md).
