# sftpgo — servidor SFTP con interfaz web

## Qué es
- **Aplicación**: sftpgo (Imagen: `docker.io/drakkan/sftpgo:alpine`)
- **Nº de contenedores**: 1 (sftpgo)
- **Red**: `proxy.network`
- **Dominio**: subdominio `sftpgo.${FQDN}`
- **Puerto interno**: `8080` (traefik.http.services.sftpgo.loadbalancer.server.port)

## Ficheros
- **Quadlet(s)**:
  - /data/self-hosted-podman/.config/containers/available/sftpgo/sftpgo.container
- **Volumen(es)**:
  - /data/self-hosted-podman/.config/containers/available/sftpgo/sftpgo-data.volume
  - /data/self-hosted-podman/.config/containers/available/sftpgo/sftpgo-home.volume
- **Config no secreta**: N/A
- **Secretos**: N/A

## Cómo funciona
- **Red**: `proxy.network`
- **Volúmenes**: `/sfv/sftpgo` y `/var/lib/sftpgo` mapeados a los volúmenes `sftpgo-data.volume` y `sftpgo-home.volume` respectivamente
- **Secrets**: N/A
- **EnvironmentFile**: N/A
- **Socket del daemon**: N/A
- **Healthcheck**: N/A
- **Enrutado Traefik**: etiquetas especificadas en la sección `Labels` del quadlet
- **User/NoNewPrivileges**: N/A

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| SFTPGO_WEBDAV__BINDINGS__0__PORT | sftpgo.container | 10080 | Puerto de la interfaz WebDAV de SFTPGo |

## Cómo habilitar / desplegar
1. Secretos (si existen): NUNCA `crypta store`.
2. `cd /data/self-hosted-podman/.config/containers/available/sftpgo && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-015, issue #10): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP 200) y **purgado ese mismo día** (unit desenlazado,
volumenes/binds e imagen eliminados). Estado actual: **no desplegado**.
