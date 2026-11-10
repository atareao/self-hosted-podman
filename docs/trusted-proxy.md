---
# trusted-proxy — IP real del cliente detrás de Traefik

## Qué es

Las apps detrás de Traefik (red `proxy`) ven como IP de origen la de **Traefik** (`10.89.0.x`, dinámica), no
la del cliente, porque el proxy termina la conexión. Traefik **sí** añade las cabeceras
`X-Forwarded-For`, `X-Forwarded-Proto` y `X-Real-Ip` con la IP real, pero cada app debe estar
configurada para **confiar** en ellas. No hay ajuste global posible en Traefik: es **por app**.

## Cómo verificar

1. IP real que recibe Traefik (es la correcta): en el access log, campo `ClientHost`.

   ```bash
   rr 'podman logs --tail 500 traefik | grep -oE "\"ClientHost\":\"[0-9.]+\"" | sort -u | head'
   ```

2. Qué ve la app: mira sus logs. Si aparece `10.89.0.85` (Traefik) en vez de tu IP pública, falta
   el trusted-proxy.

   ```bash
   rr 'podman logs --tail 200 pocketid'
   ```

3. Ojo con leer mal el log de Traefik: `ServiceAddr`/`ServiceURL` (`10.89.0.x:puerto`) es el backend
   **destino**, no el cliente. El cliente es `ClientHost`/`ClientAddr`.

## Regla del repo

Toda app que registre/use la IP del cliente (auth, seguridad, analytics, rate-limit) debe declarar
su variable de proxy de confianza apuntando a la subred de la red `proxy`:

- **Subred de `proxy.network`:** `10.89.0.0/24` (comprobar con `podman network inspect proxy.network`).
- Alternativa precisa: la IP concreta de Traefik (`10.89.0.85`), pero puede cambiar → mejor la subred.

## Tabla app → variable

| Stack | Variable | Valor | Dónde |
|---|---|---|---|
| pocketid | `TRUST_PROXY` | `true` | `pocketid.container` (`Environment=`) |
| headscale | `trusted_proxies` | `10.89.0.0/24` | `.config/headscale/config.yaml.jinja` |
| immich | `IMMICH_TRUSTED_PROXIES` | `10.89.0.0/24` | env del server |
| vaultwarden | `IP_HEADER` | `X-Real-IP` | ya por defecto; Traefik envía `X-Real-Ip` |
| gitea | `GITEA__security__REVERSE_PROXY_TRUSTED_PROXIES` | `10.89.0.0/24` | env |
| nextcloud | `trusted_proxies` + `overwriteprotocol` | `10.89.0.0/24` / `https` | `config.php` |
| umami | `CLIENT_IP_HEADER` | `x-forwarded-for` | env |
| plausible | `-` | — | analytics; lee XFF automáticamente |
| searxng | `-` | — | el limiter usa XFF vía cabeceras estándar |
| crowdsec (bouncer Traefik) | `-` | — | usa `ClientHost` (ya real) |
| grafana | `-` | — | no expone IP de cliente en logs; usar `GF_SERVER_ROOT_URL` |
| miniflux, memos, dozzle, it-tools, filebrowser, ntfy… | `-` | — | no usan la IP del cliente |

> La tabla cubre las apps donde la IP del cliente importa (auth/seguridad/analytics). Para el
> resto, busca en su documentación la variable de *trusted proxy* / *real IP* / *X-Forwarded-For*.
> El patrón habitual es un booleano (`TRUST_PROXY=true`) o una lista CIDR (`TRUSTED_PROXIES=10.89.0.0/24`).

## Seguridad

Confiar en `X-Forwarded-For` es seguro **mientras la app solo sea alcanzable por Traefik**. En este
repo las apps no publican puerto (`PublishPort`); solo están en la red `proxy` y las alcanza Traefik.
No expongas un backend directamente a Internet con el trusted-proxy activo, o podrían falsificar su IP.

## Follow-ups

- Al añadir/reconstruir un stack, revisar si usa la IP del cliente y añadir su variable aquí.

---
