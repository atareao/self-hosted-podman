# mtproxy — Proxy MTProto de Telegram

## Qué es
- **Aplicación:** mtproxy
- **Imagen:** ghcr.io/dofamin/mtproxy-docker:main
- **Consola contenedores:** 1
- **Redes:** (default, sin enlace a proxy.network)
- **Dominio:** (no expone Traefik)
- **Puerto interno:** 8889 (expone por `PublishPort=8388:8889`)

## Ficheros
- **Quadlet(s):** .config/containers/available/mtproxy/mtproxy.container
- **Volumen(es):** (none)
- **Config no secreta:** (none)
- **Secretos:** mtproxy_secret

## Cómo funciona
- **Redes:** usa red por defecto del host
- **Secretos:** variable `SECRET` se inyecta vía `podman secret create mtproxy_secret -`
- **Environment:** establece `MTPROTO_REPO_URL`, `WORKERS`, `TZ`
- **Healthcheck:** (no definido)
- **Traefik:** (no expuesto)
- **User:** no especificado (ejecuta como root por defecto)

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| MTPROTO_REPO_URL | Environment | https://github.com/TelegramMessenger/MTProxy | Repositorio MTProxy
| WORKERS | Environment | 1 | Número de workers
| TZ | Environment | Europe/Madrid | Zona horaria

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store): `printf '%s' '\u003cvalor\u003e' | podman secret create mtproxy_secret -`
2. `cd .config/containers/available/mtproxy && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- El puerto `8388` queda expuesto directamente a Internet (sin Traefik ni TLS); revisar la configuración de nftables para restringirlo o protegerlo.
