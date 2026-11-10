# Android

Unir un dispositivo **Android** a la tailnet self-hosted (`headscale`).

- **Cliente:** app oficial **Tailscale** (Play Store / F-Droid).
- **Servidor de control:** `headscale` → `https://headscale.<FQDN>` (ver `docs/headscale.md`).
- **Issue GitHub:** —
- **Plan:** —

## Ficheros implicados

| Ruta | Descripción |
|---|---|
| `.config/containers/available/headscale/*` | Stack del servidor de control (ver `docs/headscale.md`). |
| `.config/headscale/config.yaml` | `server_url` y `base_domain` (MagicDNS) que consume el cliente. |

No hay ficheros nuevos en el repo; el Android es un cliente externo.

## Cómo funciona

La app Tailscale apunta por defecto a los servidores de Tailscale Inc. Para usar la
tailnet propia hay que cambiar el **login server** a la URL de headscale y autenticar
con una **preauthkey**. El nodo queda registrado en la base sqlite de headscale.

Requisitos en el servidor (ya presentes):
- HTTPS con certificado válido (Traefik + letsencrypt).
- `TLSOption` `headscale-http1@file` forzando HTTP/1.1 (necesario para el upgrade TS2021).
  Sin él el registro se queda colgado (ver `docs/headscale.md`).

## Pasos

### 1. Servidor (como `runner`)

```bash
# Usuario (una sola vez; si ya existe, saltar)
rr "podman exec headscale headscale users create android"

# Localizar el ID de usuario
rr "podman exec headscale headscale users list"

# Crear preauthkey reusable
rr "podman exec headscale headscale preauthkeys create --user <ID> --reusable --expiration 24h"
```

Copia la clave devuelta (`hskey-auth-...`).

### 2. Android

1. Instala la app **Tailscale**.
2. Menú **⋮ → "Use an alternate server"** (según versión: mantener pulsado el perfil
   o "Change… → Login server").
3. Introduce: `https://headscale.<FQDN>`.
4. Inicia sesión con **"Sign in with other" / auth key** y pega la `hskey-auth-...`.
5. Activa el toggle de conexión.

### 3. Verificar

```bash
rr "podman exec headscale headscale nodes list"
```

El nodo debe aparecer; desde el móvil se resuelven los nombres vía MagicDNS
(`<nodo>.tailnet.<FQDN>`).

## Variables / config

- `server_url` en `.config/headscale/config.yaml` = `https://headscale.<FQDN>`.
- `base_domain` = `tailnet.<FQDN>` (MagicDNS). Debe ser distinto del dominio de `server_url`.
- Sin secretos en el cliente: la autenticación es la preauthkey.

## Cómo habilitar / desplegar

No requiere despliegue en el repo. Solo:

1. `headscale` operativo (`qctl status` en `available/headscale`).
2. Render de config al día: `unjinja` (o `yadm pull`).

## Decisiones y notas

- Las preauthkeys son **reusable** y con caducidad corta; no dejarlas fijas en repo.
- Si la app no conecta, comprobar el `TLSOption` HTTP/1.1 y el certificado del dominio.

## Follow-ups

- Publicar/abrir **UDP/3478** en el firewall para el DERP embebido (ver `docs/headscale.md`).
- Considerar ACLs por usuario si se añaden más dispositivos.
