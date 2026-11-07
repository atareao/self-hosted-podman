# simple-torrent — Cliente torrent en la nube ligera

## Qué es
- **App**: simple-torrent
- **Imagen**: docker.io/boypt/cloud-torrent
- **Nº contenedores**: 1
- **Red**: NINGUNA (solo puertos expuestos)
- **Dominio**: NINGUNO
- **Puerto interno**: 50012

## Ficheros
- **Quadlet(s)**: /data/self-hosted-podman/.config/containers/available/simple-torrent/simple-torrent.container
- **Volumen(es)**: NINGUNO
- **Config no secreta**: NINGUNO
- **Secretos**: NINGUNO

## Cómo funciona
- **Red**: NINGUNA
- **Volúmenes**: NINGUNO
- **Secrets**: NINGUNO
- **EnvironmentFile**: NINGUNO
- **Socket del daemon**: NINGUNO
- **Healthcheck**: NINGUNO
- **Enrutado Traefik**: NINGUNO
- **User/UserNS/NoNewPrivileges**: NINGUNO

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| AUTH | Container | `username:password` | Credenciales de acceso |
| TITLE | Container | `MySimpleTorrent` | Título de la aplicación |

## Cómo habilitar / desplegar
1. Secretos (si existen): —
2. `cd .config/containers/available/simple-torrent && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
