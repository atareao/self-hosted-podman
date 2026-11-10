# filebrowser — FileBrowser es un navegador de archivos ligero

## Qué es
App: filebrowser
Imagen: docker.io/filebrowser/filebrowser
Nº contenedores: 1
Red: proxy.network
Dominio: subdominio `filebrowser.${FQDN}`
Puerto interno: 8080

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/filebrowser/filebrowser.container
- Volumen(es):
  - Bind: ~/.config/filebrowser/srv → /srv:Z
  - Bind: ~/.config/filebrowser/config → /config:Z (settings.json)
  - Bind: ~/.config/filebrowser/database → /database:Z (filebrowser.db)
- Config no secreta: none
- Secretos: none


## Cómo funciona
Red proxy.network, bind mounts ~/.config/filebrowser/srv → /srv, ~/.config/filebrowser/database → /database, ~/.config/filebrowser/config → /config, User/UserNS/NoNewPrivileges: 1000:1000, servicio escucha en puerto 8080 (no expose 80), se requiere chown -R 1000:1000 de los mounts con podman unshare.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| | | | |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store):
2. `cd .config/containers/available/filebrowser && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- el proyecto filebrowser está archivado (2026-09-01), sin más releases ni parches de seguridad → valorar migración futura.