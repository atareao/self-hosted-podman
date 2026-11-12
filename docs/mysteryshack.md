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

## Follow-ups
- (ninguno)
