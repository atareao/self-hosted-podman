# vscode — Servidor de código fuente basado en Code-Server

## Qué es
Aplicación: VS Code Server
Imagen: lscr.io/linuxserver/code-server
Número de contenedores: 1
Red: proxy.network
Dominio: `vscode.${FQDN}` (subdominio vscode)
Puerto interno: 8443

## Ficheros
- Quadlet(s): `/data/self-hosted-podman/.config/containers/available/vscode/vscode.container`
- Volumen(es): ninguno
- Config no secreta: ninguno
- Secretos: `vscode_password`

## Cómo funciona
El contenedor se une a la red `proxy.network` y expone el puerto 8443 a Traefik mediante la etiqueta `traefik.http.services.vscode.loadbalancer.server.port`. Se utilizan las variables de entorno `PUID=1000`, `PGID=1000` y `TZ=Europe/Madrid`. El contenedor no corre como root, ya que `USER=1000:1000` se define en la imagen.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| PUID | `Environment=` | 1000 | UID del usuario dentro del contenedor |
| PGID | `Environment=` | 1000 | GID del usuario dentro del contenedor |
| TZ | `Environment=` | Europe/Madrid | Zona horaria |

## Cómo habilitar / desplegar
1. `printf '%s' '<valor_del_secreto>' | podman secret create vscode_password -`
2. `cd .config/containers/available/vscode && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- **Primer arranque verificado**: imagen LinuxServer.io (LSNG) arranca correctamente **sin** `PodmanArgs=--init` (s6-overlay exige ser PID 1; con `--init` abortaría con `s6-overlay-suexec: fatal: can only run as pid 1`). El login funciona con el secreto `PASSWORD` (`vscode_password`).
