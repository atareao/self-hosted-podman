# alloy — dashboard de gestión de contenedores

## Qué es

`alloy` (`docker.io/atareao/alloy`) es un dashboard autoalojado para gestionar contenedores
Docker/Podman (Rust/Axum en el backend + React en el frontend). Se despliega como un único
contenedor tras Traefik, en la red `proxy`, y se sirve en el **dominio raíz `${FQDN}`**
(no en un subdominio). Escucha en el puerto `3066` y autentica por OIDC.

## Ficheros

- Quadlet: `.config/containers/available/alloy/alloy.container`
- Volumen: `.config/containers/available/alloy/alloy-data.volume` (`VolumeName=alloy-data`)
- Config no secreta: `.config/alloy/alloy.env` (+ `.env.local` por máquina, gitignored, scaffold automático en `post_pull`).
- Secreto: `alloy_oidc_client_secret` (inyectado como `OIDC_CLIENT_SECRET`).

## Cómo funciona

- **Acceso al daemon**: el contenedor gestiona el motor vía socket. En vez del
  `/var/run/docker.sock` del compose, se monta el socket de Podman
  (`%t/podman/podman.sock` → `/var/run/docker.sock:ro`). Como el proceso corre en el
  contenedor con `uid/gid 1000` y el socket pertenece a ese mismo usuario en el host,
  se usa `UserNS=keep-id` para mapear ese usuario del contenedor al `uid 1000` del host y
  así poder abrir el socket. Por eso **no** se necesita `group_add: "999"` (era el gid de
  `docker` en el origen).
- **Persistencia**: el volumen nombrado `alloy-data` se monta en `/app/data` (con `:Z` por SELinux rootless).
- **Configuración**: la config no secreta llega por dos `EnvironmentFile` (`.env` versionado y
  `.env.local` por máquina; el segundo sobreescribe al primero). El `OIDC_CLIENT_SECRET` va por
  **secreto Podman** (`Secret=…,type=env,target=OIDC_CLIENT_SECRET`). `OIDC_REDIRECT_URL` se fija
  en el quadlet con `https://${FQDN}/api/auth/callback` (`${FQDN}` lo expande systemd en runtime).
- **Healthcheck**: `wget -q --spider http://localhost:3066/api/health` (endpoint público, sin auth).
- **Enrutado**: router `alloy` con `Host(`${FQDN}`)`, `entrypoints=websecure`,
  `tls.certresolver=letsencrypt` y los middlewares del repo (`seguridadHeaders`, `compresionHeaders`).

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `TIMEZONE` | `.config/alloy/alloy.env` | `Europe/Madrid` | zona horaria |
| `DOCKER_HOST` | `.config/alloy/alloy.env` | `unix:///var/run/docker.sock` | socket del daemon dentro del contenedor |
| `OIDC_ISSUER_URL` | `.config/alloy/alloy.env` (o `.env.local`) | `https://auth.example.com` | issuer OIDC — **ajustar al real** |
| `OIDC_CLIENT_ID` | `.config/alloy/alloy.env` (o `.env.local`) | `alloy` | client id OIDC — **ajustar al real** |
| `OIDC_CLIENT_SECRET` | secreto Podman `alloy_oidc_client_secret` | — | client secret OIDC |
| `OIDC_REDIRECT_URL` | fijado en el quadlet | `https://${FQDN}/api/auth/callback` | callback OIDC |

## Habilitar / desplegar

```fish
# 1. Crear el secreto ANTES de arrancar (NUNCA con crypta store)
printf '%s' '<client-secret>' | podman secret create alloy_oidc_client_secret -

# 2. Ajustar OIDC_ISSUER_URL / OIDC_CLIENT_ID reales en .config/alloy/alloy.env.local

# 3. Enlazar y recargar
cd .config/containers/available/alloy
qctl install
systemctl --user daemon-reload
```

Verificar con `systemctl --user status alloy` o `journalctl --user -u alloy`.

## Decisiones de migración (compose → quadlet)

| compose | quadlet |
|---|---|
| `image: atareao/alloy` | `Image=docker.io/atareao/alloy:latest` |
| `init: true` | `PodmanArgs=--init` |
| `restart: unless-stopped` | `Restart=always` |
| `group_add: "999"` (docker gid) | descartado: `UserNS=keep-id` da acceso al socket podman (gid 1000) |
| app corre como no-root (uid 1000) | `UserNS=keep-id` (uid 1000 contenedor = uid 1000 host) |
| `TIMEZONE`, `DOCKER_HOST`, `OIDC_ISSUER_URL`, `OIDC_CLIENT_ID` | `.config/alloy/alloy.env` + `EnvironmentFile` |
| `OIDC_CLIENT_SECRET` | `Secret=alloy_oidc_client_secret,type=env,target=OIDC_CLIENT_SECRET` |
| `OIDC_REDIRECT_URL=https://${FQDN}/api/auth/callback` | `Environment=OIDC_REDIRECT_URL=https://${FQDN}/api/auth/callback` |
| `/var/run/docker.sock:/var/run/docker.sock` | `Volume=%t/podman/podman.sock:/var/run/docker.sock:ro` |
| `data:/app/data` | `Volume=alloy-data.volume:/app/data:Z` |
| `networks: proxy (external)` | `Network=proxy.network` |
| labels: entrypoints `https`, `Host(${FQDN})` | router `websecure` + `tls.certresolver=letsencrypt` + `middlewares=seguridadHeaders@file,compresionHeaders@file`, `Host(`${FQDN}`)` |
| healthcheck (nuevo) | `wget -q --spider http://localhost:3066/api/health || exit 1` (busybox) |

## Follow-ups

- La autenticación OIDC es **obligatoria** en alloy: sin `OIDC_ISSUER_URL` / `OIDC_CLIENT_ID` /
  `OIDC_CLIENT_SECRET` válidos el login no funciona.
- Si el socket deja de ser accesible, revisar `UserNS=keep-id` (el uid del contenedor debe coincidir
  con el dueño del socket podman en el host).
- Notificaciones opcionales (Telegram/Matrix) **no configuradas**.
