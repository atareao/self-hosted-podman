# errserve — páginas de error *catch-all*

## Qué es

`errserve` (`ghcr.io/atareao/errserve`) sirve páginas de error HTML para cualquier petición que
Traefik no pueda resolver, en lugar del 404/502 plano. Se despliega tras Traefik como un único
contenedor en la red `proxy`.

## Ficheros

- Quadlet: `.config/containers/available/errserve/errserve.container`
- Config no secreta: `.config/errserve/errserve.env` (+ `.env.local` por máquina, gitignored, scaffold automático en `post_pull`).

## Cómo funciona el enrutado

- Router `errserve-catchall` — regla `HostRegexp(.+) && !Path(`/metrics`)`, `entrypoints=websecure`, `priority=1`.
  Como la prioridad por defecto de un router es la longitud de su regla, cualquier router con `Host(...)` real gana;
  este solo actúa cuando no hay match (fallback).
- Middleware `errpages` — `errors.status=400-599`, `errors.service=errserve`, `errors.query=/{status}`.
  Traefik reenvía los errores 4xx/5xx a errserve con la ruta del código (`/404`, `/500`, …).
- Middleware `errfixed` — variante con `errors.query=/404`. **No** lo usa este router; queda definido para que otros
  stacks lo referencien explícitamente (`errfixed@docker`).
- Servicio `errserve` en el puerto `8080`.

## Variables de entorno (todas no secretas)

| Var | Valor | Descripción |
|---|---|---|
| `PORT` | `8080` | puerto de escucha |
| `LOG_LEVEL` | `info` | nivel de log |
| `LOG_FORMAT` | `text` | formato de log |
| `CONTENT_DIR` | `content` | directorio de plantillas dentro de la imagen |
| `DEFAULT_ERROR_PAGE` | `404` | página por defecto |
| `THEME` | `terminal` | tema de las páginas |

## Habilitar / desplegar

```fish
cd .config/containers/available/errserve
qctl status        # estado (desde el dir del stack)
qctl install       # enlaza en ~/.config/containers/systemd + daemon-reload
```

No requiere secretos (`podman secret create`) ni volúmenes. Verificar con
`systemctl --user status errserve` o `journalctl --user -u errserve`.

## Decisiones de migración (compose → quadlet)

- `init: true` → `PodmanArgs=--init`.
- `restart: unless-stopped` → `Restart=always`.
- Imagen con tag flotante `:latest` → `AutoUpdate=registry`.
- Env no secreta → `.config/errserve/errserve.env` + `EnvironmentFile` (`.env` + `.env.local`).
- Red externa `proxy` → `proxy.network` (definida en el stack `traefik`).
- `NetworkAlias=errserve` es imprescindible: el middleware `errors.service=errserve` resuelve el servicio por ese alias.
- Labels Traefik copiadas **tal cual** del compose: esta stack **no** sigue el patrón single-router seguro del resto
  del repo (`Host(...)` + `seguridadHeaders`/`compresionHeaders`); es un *catch-all* intencionado.
- `Hardening`, `Resources` y `Healthcheck` vacías, igual que el compose (evita romper en runtime).

## Follow-ups

- Añadir un volumen para `CONTENT_DIR` si se quieren páginas de error personalizadas.
- Si se quiere un certificado propio para el catch-all TLS, añadir `tls.certresolver` al router
  (hoy usa el certificado por defecto de Traefik).
