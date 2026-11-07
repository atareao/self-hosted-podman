# zennotes — notas Markdown autoalojado

## Qué es

`zennotes` (`docker.io/adibhanna/zennotes`) es una aplicación self‑hosted de notas Markdown orientada a teclado/Vim. Cada nota se almacena como un fichero `.md` dentro de un *vault* en disco; no utiliza base de datos. La imagen es de tipo *scratch* y se ejecuta como un contenedor único, detrás de Traefik, en la red `proxy`, servido en el **dominio raíz `${FQDN}`** y escuchando en el puerto `7878`.

## Ficheros

- Quadlet: `.config/containers/available/zennotes/zennotes.container`
- Volumen Vault: `.config/containers/available/zennotes/zennotes-vault.volume` (`VolumeName=zennotes-vault`)
- Volumen Datos: `.config/containers/available/zennotes/zennotes-data.volume` (`VolumeName=zennotes-data`)
- Config no secreta: `.config/zennotes/zennotes.env` (+ `.env.local` por máquina, gitignored y generado por `post_pull`)
- Secreto Podman: `zennotes_auth_token` (inyectado como `ZENNOTES_AUTH_TOKEN`)

## Cómo funciona

- **Contenedor único**: no necesita acceso al socket del daemon. Se ejecuta con `User=1000:1000` y el volumen nombrado vacío (zennotes-data) se *chown*‑ea a `1000`.
- **Vault**: monta el volumen `zennotes-vault` en `/workspace:Z`.
- **Configuración**: llega por dos `EnvironmentFile` (`.env` versionado y `.env.local` por máquina). El secreto se injecta con `Secret=`.
- **Healthcheck**: `HealthCmd=["/zennotes-server","healthcheck"]` (imagen scratch no tiene shell). 
- **Enrutado**: router `zennotes` con `Host(`${FQDN}`)`, `entrypoints=websecure`, `tls.certresolver=letsencrypt`, middlewares `seguridadHeaders` y `compresionHeaders`.
- **Hardening**: `NoNewPrivileges=true` y usuario no‑root.

## Variables / configuración

| Variable | Dónde | Valor | Descripción |
|---|---|---|---|
| `ZENNOTES_VAULT_PATH` | `.config/zennotes/zennotes.env` | `/workspace` | Path del vault dentro del contenedor |
| `ZENNOTES_CONFIG_PATH` | `.config/zennotes/zennotes.env` | `/data/server.json` | Ruta al fichero de configuración de la app |
| `ZENNOTES_BEHIND_TLS` | `.config/zennotes/zennotes.env` | `1` | Indica que Traefik termina TLS |
| `ZENNOTES_PERSIST_SESSIONS` | `.config/zennotes/zennotes.env` | `1` | Persistencia de sesiones |
| `ZENNOTES_AUTH_TOKEN` | Secreto `zennotes_auth_token` | — | Token de autenticación de la app |
| `ZENNOTES_BIND` | Imagen por defecto | `0.0.0.0:7878` | Puerto de escucha |
| `ZENNOTES_DEFAULT_VAULT_PATH` | Imagen por defecto | `/workspace` | Path por defecto del vault |
| `ZENNOTES_BROWSE_ROOTS` | Imagen por defecto | `/workspace` | Raíces para el navegador de archivos |

## Cómo habilitar / desplegar

```bash
# 1. Crear el secreto ANTES de arrancar (NUNCA con `crypta store`)
printf '%s' "$(openssl rand -hex 32)" | podman secret create zennotes_auth_token -

# 2. Ajustar configuraciones en .config/zennotes/zennotes.env.local (opcional)

# 3. Enlazar las unidades y recargar systemd
cd .config/containers/available/zennotes
qctl install
systemctl --user daemon-reload
```

Para comprobar el estado: `systemctl --user status zennotes` o `journalctl --user -u zennotes`.

## Decisiones de migración (compose → quadlet)

| Compose | Quadlet |
|---|---|
| `init: true` | `PodmanArgs=--init` |
| `restart: unless-stopped` | `Restart=always` |
| `user: 1000:1000` | `User=1000:1000` |
| `vault` → `zennotes-vault.volume` / `data` → `zennotes-data.volume` | | 
| `SECRET_TOKEN` → `zennotes_auth_token` | `Secret=zennotes_auth_token,type=env,target=ZENNOTES_AUTH_TOKEN` |
| Labels normalizados a `websecure`, `certresolver=letsencrypt`, middlewares | `Label=traefik.http.routers.zennotes.entrypoints=websecure` etc. |
| Imagen `scratch` sin HEALTHCHECK, se configura el `HealthCmd` explícito | `HealthCmd=["/zennotes-server","healthcheck"]` |

## Follow‑ups

- El token es obligatorio; sin él el contenedor no arrancará.
- Si en el futuro la imagen publica su propio `HEALTHCHECK`, se puede eliminar el `HealthCmd` del quadlet.
- No hay persistencia de volúmenes a menos que el volume `zennotes-data` exista; debe crearse con `podman volume create` o será creado automáticamente por quadlet.
