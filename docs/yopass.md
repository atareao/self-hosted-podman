# yopass — Servicio de gestión de contraseñas y autenticación en contenedores

## Qué es
- App: yopass
- Imagen: docker.io/jhaals/yopass
- Nº contenedores: 2
- Red: proxy.network, yopass.network
- Dominio: Host `yopass.${FQDN}`
- Puerto interno: 80

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/yopass/yopass.container
  - /data/self-hosted-podman/.config/containers/available/yopass/yopass-memcached.container
  - /data/self-hosted-podman/.config/containers/available/yopass/yopass.network
- Volumen(es):
  - (none)
- Config no secreta:
  - (none)
- Secretos:
  - (none)

## Cómo funciona
Red: proxy.network y yopass.network. No volúmenes, secretos ni variables de entorno. No se especifica User, por lo que se ejecuta como root por defecto. Enrutado con Traefik en puerto 80 bajo el nombre de host `yopass.${FQDN}`.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|

## Cómo habilitar / desplegar
1. `cd .config/containers/available/yopass && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-017, issue #12): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP 200) y **purgado ese mismo día**. Estado actual: **no desplegado**.

**Bug corregido**: yopass escuchaba en el puerto **80**, imposible en podman rootless
(`listen tcp :80: bind: permission denied`). Se cambió `Exec=... --port 1337` y el
`loadbalancer.server.port` de Traefik a `1337`.
