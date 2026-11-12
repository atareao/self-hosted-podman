# simple-torrent — Cliente torrent en la nube ligera

## Qué es
- **App**: simple-torrent
- **Imagen**: docker.io/jpillora/cloud-torrent:latest (la imagen original `boypt/cloud-torrent` fue retirada de Docker Hub; se sustituye por `jpillora`, upstream del fork)
- **Nº contenedores**: 1
- **Red**: NINGUNA (solo puertos expuestos)
- **Dominio**: NINGUNO
- **Puerto interno**: 50012

## Ficheros
- **Quadlet(s)**: /data/self-hosted-podman/.config/containers/available/simple-torrent/simple-torrent.container
- **Volumen(es)**: `%h/.config/simple-torrent/downloads` → `/srv/downloads` y `%h/.config/simple-torrent/cloud-torrent.json` → `/etc/cloud-torrent.json` (bind mounts, no versionados)
- **Config no secreta**: `%h/.config/simple-torrent/cloud-torrent.json` (JSON, no YAML)
- **Secretos**: `simple_torrent_auth`

## Cómo funciona
- **Red**: NINGUNA
- **Volúmenes**: bind mounts de `%h/.config/simple-torrent/downloads` (descargas) y `%h/.config/simple-torrent/cloud-torrent.json` (configuración JSON, `Exec=-c /etc/cloud-torrent.json`).
- **Secrets**: `simple_torrent_auth` se inyecta con `Secret=simple_torrent_auth,type=env,target=AUTH` (driver `crypta`).
- **EnvironmentFile**: NINGUNO
- **Socket del daemon**: NINGUNO
- **Healthcheck**: NINGUNO
- **Enrutado Traefik**: NINGUNO
- **User/UserNS/NoNewPrivileges**: NINGUNO

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| AUTH | Container (`Secret=simple_torrent_auth`) | *(secreto)* | Credenciales de acceso (`usuario:password`) |
| TITLE | Container | `MySimpleTorrent` | Título de la aplicación |
| PORT | Container | `50012` | Puerto de escucha HTTP (jpillora escucha en 3000 por defecto) |

### Contenido del JSON (`cloud-torrent.json`)
```json
{"Title":"MySimpleTorrent","Port":50012,"DownloadDirectory":"/srv/downloads"}
```

## Cómo habilitar / desplegar
1. Crear el secreto con `podman secret create` (nunca `crypta store`):
   ```bash
   printf '%s' 'usuario:password' | podman secret create simple_torrent_auth -
   ```
2. Crear en prod el directorio de descargas y el JSON de configuración **antes** de arrancar:
   - `%h/.config/simple-torrent/downloads/`
   - `%h/.config/simple-torrent/cloud-torrent.json` (el contenedor lo lee con `Exec=-c /etc/cloud-torrent.json`; si no existe, no arranca). El puerto de escucha se fija por `Environment=PORT=50012` (jpillora escucha en 3000 por defecto); `AUTH` sigue viniendo del secreto `simple_torrent_auth`.
3. `cd .config/containers/available/simple-torrent && qctl install`
4. `systemctl --user daemon-reload`

## Follow-ups
- El JSON `cloud-torrent.json` no se versiona en el repo; debe crearse en prod antes de arrancar el contenedor.
- El puerto de entrada de torrents de jpillora por defecto es 50007; el `PublishPort=50012:50012/udp` actual no lo cubre. Revisar si se quiere publicar/tagear ese puerto.
