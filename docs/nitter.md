# nitter — Servicio de Nitter (interfaz alternativa a Twitter)

## Qué es
- App: nitter
  Image: docker.io/zedeus/nitter:8142bab1a920d13589ab5e689d7623ac0ac7ec34
  Contenedores: 2 (nitter + nitter-redis)
  Red principal: proxy.network (nitter); nitter.network (nitter y nitter-redis)
  Dominio: nitter.${FQDN}
  Puerto interno: 8080

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/nitter/nitter.container
  - /data/self-hosted-podman/.config/containers/available/nitter/nitter-redis.container
  - /data/self-hosted-podman/.config/containers/available/nitter/nitter.network
- Volumen(es):
  - Bind: %h/.config/nitter/nitter.conf -> /src/nitter.conf (nitter, solo lectura)
  - Bind: %h/.config/nitter/sessions.jsonl -> /src/sessions.jsonl (nitter)
  - nitter-redis.volume -> /data (nitter-redis)
- Config no secreta: .config/nitter/nitter.conf.jinja (plantilla; el `nitter.conf` renderizado está en .gitignore)
- Secretos: none

## Cómo funciona
- Proxy.network: sí (expuesto a traefik)
- Volúmenes: bind mount de configuración y de `sessions.jsonl`; volumen nombrado para la caché de Redis
- Secretos: ninguno
- EnvironmentFile: ninguno
- Socket del daemon: ninguno
- Healthcheck: sí (wget -nv --tries=1 --spider http://127.0.0.1:8080/)
- Dependencias: nitter arranca tras nitter-redis (`After=`/`Requires=`)
- Config: `nitter.conf` se versiona como plantilla `.config/nitter/nitter.conf.jinja` (usa `{{ env.FQDN }}` y se renderiza con unjinja); el `.conf` renderizado está en `.gitignore`. El `sessions.jsonl` es un **placeholder vacío obligatorio** (nitter hace `quit 1` si no existe): sin tokens reales sirve la portada pero no consulta la API de X.
- Enrutado Traefik: etiquetas cargadas:
  - traefik.http.services.nitter.loadbalancer.server.port=8080
  - traefik.http.routers.nitter.rule=Host(`nitter.${FQDN}`)
  - traefik.http.routers.nitter.entrypoints=websecure
  - traefik.http.routers.nitter.tls.certresolver=letsencrypt
  - traefik.http.routers.nitter.middlewares=seguridadHeaders@file,compresionHeaders@file
- User/UserNS/NoNewPrivileges: ninguno

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|

## Cómo habilitar / desplegar
1. Renderiza `nitter.conf` desde la plantilla: `unjinja .config/nitter/nitter.conf.jinja` (o el hook `post_pull`).
2. Asegura que existe el placeholder `sessions.jsonl` (vacío) en `.config/nitter/`.
3. `cd .config/containers/available/nitter && qctl install`
4. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
