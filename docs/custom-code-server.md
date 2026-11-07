# custom-code-server — código remoto seguro

## Qué es
Editor de código basado en VS Code accesible desde el navegador.
- **App**: custom-code-server
- **Imagen**: docker.io/atareao/custom-code-server
- **Contenedores**: 1
- **Red**: proxy.network
- **Dominio**: `code.${FQDN}`
- **Puerto interno**: 8443

## Ficheros
- **Quadlet(s)**: /data/self-hosted-podman/.config/containers/available/custom-code-server/custom-code-server.container
- **Volumen(es)**:
  - /data/self-hosted-podman/.config/containers/available/custom-code-server/custom-code-server-code_server_data.volume
  - /data/self-hosted-podman/.config/containers/available/custom-code-server/custom-code-server-code_server_workspace.volume
- **Config no secreta**: ninguna
- **Secretos**: ninguno

## Cómo funciona
- **Red**: proxy.network
- **Volúmenes**: configuración y espacio de trabajo persistente
- **EnvironmentFile**: ninguna
- **Socket del daemon**: ninguno
- **Healthcheck**: ninguno
- **Enrutado Traefik**: router `code-server` con puerto 8443
- **User/UserNS/NoNewPrivileges**: valores por defecto de container

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| PUID | Environment | 1000 | UID de usuario dentro del contenedor |
| PGID | Environment | 1000 | GID de usuario dentro del contenedor |
| TZ | Environment | Europe/Madrid | Zona horaria |
| AUTH | Environment | none | Autenticación requerida (none=sin auth) |
| DOCKER_USER | Environment | abc | Usuario Docker (ejemplo) |
| DEFAULT_WORKSPACE | Environment | /config/workspace | Carpeta de trabajo por defecto |

## Cómo habilitar / desplegar
1. `cd .config/containers/available/custom-code-server && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)
