# shaarli — Aplicación web de marcadores sociales

## Qué es
- **App**: shaarli
- **Imagen**: docker.io/shaarli/shaarli:latest
- **Nº contenedores**: 1
- **Red**: proxy.network
- **Dominio**: subdominio `shaarli.${FQDN}`, raíz `${FQDN}`
- **Puerto interno**: 80

## Ficheros
- **Quadlet(s)**: /data/self-hosted-podman/.config/containers/available/shaarli/shaarli.container
- **Volumen(es)**: /data/self-hosted-podman/.config/containers/available/shaarli/shaarli-cache.volume, /data/self-hosted-podman/.config/containers/available/shaarli/shaarli-data.volume
- **Config no secreta**: NINGUNO
- **Secretos**: NINGUNO

## Cómo funciona
- **Red**: proxy.network
- **Volúmenes**: shaarli-cache.volume, shaarli-data.volume
- **Secrets**: NINGUNO
- **EnvironmentFile**: NINGUNO
- **Socket del daemon**: NINGUNO
- **Healthcheck**: NINGUNO
- **Enrutado Traefik**: Host(`shaarli.${FQDN}`) → puerto 80
- **User/UserNS/NoNewPrivileges**: NINGUNO

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|

## Cómo habilitar / desplegar
1. Secretos (si existen): —
2. `cd .config/containers/available/shaarli && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
