# filebrowser — FileBrowser es un navegador de archivos ligero

## Qué es
App: filebrowser
Imagen: docker.io/filebrowser/filebrowser
Nº contenedores: 1
Red: proxy.network
Dominio: subdominio `filebrowser.${FQDN}`
Puerto interno: 80

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/filebrowser/filebrowser.container
- Volumen(es):
- Config no secreta:
- Secretos:

## Cómo funciona
Red proxy.network, bind mounts /srv, /database.db, /.filebrowser.json al host, socket del daemon (none), healthcheck (none), enrutado Traefik, User/UserNS/NoNewPrivileges: 1000:1000.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| | | | |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store):
2. `cd .config/containers/available/filebrowser && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)