# mysteryshack — Servidor web para misterio

## Qué es
- **Aplicación:** mysteryshack
- **Imagen:** docker.io/atareao/mysteryshack:v1.0
- **Consola contenedores:** 1
- **Redes:** proxy.network
- **Dominio:** `mysteryshack.${FQDN}` (subdominio)
- **Puerto interno:** 6767 (traefik.http.services.mysteryshack.loadbalancer.server.port)

## Ficheros
- **Quadlet(s):** .config/containers/available/mysteryshack/mysteryshack.container
- **Volumen(es):** bind `%h/.config/mysteryshack/data` -> `/rs/data` (no hay volumen nombrado)
- **Config no secreta:** (none)
- **Secretos:** (none)

## Cómo funciona
- **Redes:** conecta a proxy.network
- **Volúmenes:** monta bind `%h/.config/mysteryshack/data` en `/rs/data`
- **Healthcheck:** `wget -q --spider http://127.0.0.1:6767/`
- **Traefik:** enruta al puerto 6767 con host `mysteryshack.${FQDN}` y middlewares de seguridad
- **User:** no especificado (ejecuta como root)

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|

## Cómo habilitar / desplegar
1. `mkdir -p ~/.config/mysteryshack/data` (si no existe, Podman lo crea como root del namespace y el entrypoint puede fallar por permisos)
2. `cd .config/containers/available/mysteryshack && qctl install`
3. `systemctl --user daemon-reload`

## Estado: BLOQUEADO (2026-11-12)

No se puede desplegar ni verificar E2E: la imagen `docker.io/atareao/mysteryshack:v1.0` **no
existe** en ningún registro público (Docker Hub devuelve 404 para el repo `atareao/mysteryshack`;
GHCR también falla para `v1.0` y `latest`). Verificado en producción el 2026-11-12:

```
podman pull docker.io/atareao/mysteryshack:v1.0   -> denied (repo inexistente)
podman pull ghcr.io/atareao/mysteryshack:v1.0     -> FALLA
podman pull ghcr.io/atareao/mysteryshack:latest   -> FALLA
podman pull docker.io/atareao/mysteryshack:latest -> FALLA
```

La imagen se **construía localmente** en el repo origen (`atareao/self-hosted`, carpeta
`mysteryshack/`) con `build: .` y se etiquetaba como `atareao/mysteryshack:v1.0`; nunca se publicó
(o se retiró). Su `Dockerfile` es multi-stage: usa `bnjbvr/mysteryshack-docker` como *builder*
(de 2017) y una base `ubuntu:18.04` con `libssl1.0.0` (ambas EOL), por lo que reconstruirla hoy
exigiría actualizar la base y probablemente `libssl`.

Alternativas evaluadas (todas de 2017, no recomendadas sin re-verificación):
`bnjbvr/mysteryshack-docker` (imagen upstream no-oficial, requiere montar `config.ini`, un
`create-user.sh` de un solo uso y el bind `/rs/data`) y `kapolos/mysteryshack`.

Acción pendiente (fuera del alcance de PLAN-034): decidir entre (a) reconstruir y publicar la
imagen con base actualizada, o (b) migrar el quadlet a la imagen upstream `bnjbvr/mysteryshack-docker`
adaptando el entrypoint/usuario, y entonces verificar E2E.

## Follow-ups
- (ninguno)
