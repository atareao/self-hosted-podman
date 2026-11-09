# PLAN-009 — Stack `headscale` (servidor de control Tailscale)

- **Issue:** #3 (feat: stack headscale)
- **Stack:** `headscale`
- **Dominio:** `headscale.${FQDN}`
- **Estado:** en curso

## Contexto

`headscale` es una implementación self-hosted del servidor de control de Tailscale. Se añade al repo como quadlets Podman (rootless) detrás de Traefik, siguiendo las convenciones de migración del repo (11 secciones canónicas, `EnvironmentFile`, secretos por `podman secret create`, labels Traefik websecure/letsencrypt/middlewares).

## Restricción técnica crítica

El protocolo de control de Tailscale (TS2021) usa un HTTP Upgrade cuyo valor es `tailscale-control-protocol` con método POST. Traefik solo procesa upgrades de tipo `websocket`; sobre HTTP/2 (negociado por ALPN) el Upgrade se descarta y el cliente se queda colgado. Solución: forzar HTTP/1.1 por ALPN únicamente en el router de headscale mediante un `TLSOption` del provider `file`.

## Objetivos

1. Servicio headscale operativo como contenedor rootless, gestionado por systemd.
2. Detrás de Traefik en `headscale.${FQDN}` (HTTPS Let's Encrypt).
3. Config `config.yaml` versionada como plantilla (por el `${FQDN}`) y renderizada.
4. DERP embebido con STUN (UDP/3478) para relay de clientes.
5. Documentación (`docs/headscale.md`) y plan archivado al cerrar.

## Entregables

- [ ] `.config/containers/available/headscale/headscale.container` — quadlet principal (11 secciones).
- [ ] `.config/containers/available/headscale/headscale-data.volume` — volumen nombrado para datos.
- [ ] `.config/headscale/config.yaml.jinja` — plantilla de config (renderiza a `config.yaml`).
- [ ] `.config/headscale/.gitignore` — ignora el `config.yaml` renderizado.
- [ ] `.config/headscale/headscale.env` — config no secreta del stack.
- [ ] `.config/traefik/dynamic/headscale.yml` — `TLSOption` `headscale-http1` (ALPN `http/1.1`).
- [ ] `docs/headscale.md` — documentación de la feature.
- [ ] `plans/PLAN-009-ARCHIVED.md` al cerrar (renombrar + marcar tareas).

## Detalle de diseño

### Quadlet `headscale.container`

- `Image=docker.io/headscale/headscale:latest`, `AutoUpdate=registry`, `PodmanArgs=--init`.
- `ContainerName=headscale`.
- `PublishPort=3478:3478/udp` (STUN del DERP embebido).
- `Volume=%h/.config/headscale/config.yaml:/etc/headscale/config.yaml:ro,Z`.
- `Volume=headscale-data.volume:/var/lib/headscale:Z`.
- `Network=proxy.network`.
- `EnvironmentFile=%h/.config/headscale/headscale.env` y `...headscale.env.local`.
- Labels Traefik: enable, loadbalancer.server.port=8080, rule=Host(headscale.${FQDN}), entrypoints=websecure, tls.certresolver=letsencrypt, tls.options=headscale-http1@file, middlewares=seguridadHeaders@file,compresionHeaders@file.
- `After=network-online.target traefik.service`.
- Hardening: `NoNewPrivileges=true`, `SecurityLabelDisable=true`.
- `[Service]`: `Restart=always`, `RestartSec=10s`, `StartLimitIntervalSec=300`, `StartLimitBurst=3`, `TimeoutStartSec=180`.
- `HealthCmd=/ko-app/headscale health`, `HealthInterval=30s`, `HealthRetries=3`, `HealthStartPeriod=30s`.

### Config `config.yaml`

- `server_url: https://headscale.{{ env.FQDN }}`.
- `listen_addr: 0.0.0.0:8080` (HTTP; TLS lo termina Traefik).
- `metrics_listen_addr: 0.0.0.0:9090` (solo red interna).
- `grpc_listen_addr: 127.0.0.1:50443`, `grpc_allow_insecure: false`.
- `trusted_proxies`: CIDR de `proxy.network`.
- `noise.private_key_path: /var/lib/headscale/noise_private.key`.
- `derp` embebido: `server.enabled: true`, `region_id` fijo, `stun_listen_addr: 0.0.0.0:3478`, `urls: https://headscale.{{ env.FQDN }}/derp`.
- `ip_prefixes` (IPv4/IPv6 de la tailnet).
- `database.type: sqlite`, `sqlite.path: /var/lib/headscale/db.sqlite`.
- `dns.magic_dns: true`, `base_domain` propio (distinto del dominio de server_url).
- `unix_socket: /var/lib/headscale/headscale.sock`.
- `log.level: info`.
- TLS desactivado (`tls_cert_path`/`tls_key_path` vacíos).

### Traefik

- `headscale.yml` con `tls.options.headscale-http1.alpnProtocols: [http/1.1]`.
- El router de headscale referencia `headscale-http1@file`.

## Validación

- [ ] `QUADLET_UNIT_DIRS=<tmp> /usr/lib/podman/quadlet -user -dryrun` rc=0 con unidades + red `proxy`.
- [ ] `qctl check` sin colisiones de nombre.
- [ ] Render de `config.yaml` correcto (`jinrender`).
- [ ] `headscale configtest -c config.yaml` OK.

## Post-despliegue (no en este plan)

- Crear usuario y preauthkey: `headscale users create`, `headscale preauthkeys create`.
- Publicar UDP/3478 y abrir el puerto en el firewall del host.
- Confirmar `curl https://headscale.${FQDN}/health` → `{"status":"pass"}`.
