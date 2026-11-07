# vaultwarden — Servidor de contraseñas compatible Bitwarden

## Qué es

Vaultwarden: implementación ligera y compatible con la API de Bitwarden para autoalojar contraseñas (imagen `docker.io/vaultwarden/server:latest`). Un único contenedor (`vaultwarden`). Red: `proxy.network`. Dominio: subdominio `vaultwarden.${FQDN}` (`${FQDN}` es la raíz del host). Puerto interno expuesto a Traefik: `80`.

## Ficheros

- Quadlet(s): `.config/containers/available/vaultwarden/vaultwarden.container`
- Volumen(es): — (no usa volumen nombrado; usa bind mount `%h/.config/vaultwarden/data`)
- Config no secreta: — (no existe `.env` de stack)
- Secretos: `vaultwarden_admin_token`

## Cómo funciona

Se une a `proxy.network` con `NetworkAlias=vaultwarden`, de modo que Traefik lo alcanza por el puerto interno `80`. Los datos persisten en un bind mount `%h/.config/vaultwarden/data` montado en `/data` (con `:Z`), no en un volumen nombrado. El token de administración se inyecta con Podman secret como variable de entorno (`vaultwarden_admin_token`→`ADMIN_TOKEN`). Arranca con `Restart=always` y `AutoUpdate=registry`; **no** usa `PodmanArgs=--init`. No define healthcheck, hardening ni variables de entorno adicionales. El enrutado Traefik usa el router `vaultwarden` en el entrypoint `websecure`, con TLS vía `letsencrypt` y los middlewares `seguridadHeaders@file,compresionHeaders@file`.

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `ADMIN_TOKEN` | `vaultwarden.container` (`Secret=vaultwarden_admin_token`) | *(secreto)* | Token para acceder al panel de administración de Vaultwarden (habitualmente un hash Argon2) |
| `FQDN` | entorno systemd (`~/.config/environment.d/fqdn.conf`) | `<tu-dominio>` | Dominio raíz; se usa como `vaultwarden.${FQDN}` en la label Traefik |

## Cómo habilitar / desplegar

1. Crear el secreto (NUNCA `crypta store`):
   - `printf '%s' '<admin-token>' | podman secret create vaultwarden_admin_token -`
2. `cd .config/containers/available/vaultwarden && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups

- Usa bind mount en `%h/.config/vaultwarden/data` en lugar de volumen nombrado: asegurarse de que la ruta existe y de que los backups la cubren.
- No aplica hardening (`ReadOnly`, `NoNewPrivileges`, `User`/`Group`); evaluar añadirlo.
