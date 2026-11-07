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
