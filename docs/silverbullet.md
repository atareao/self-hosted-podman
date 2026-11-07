# silverbullet — Biblioteca de datos de noticias en un solo repositorio

## Qué es
- **App**: silverbullet
- **Imagen**: docker.io/atareao/silverbullet:latest
- **Nº contenedores**: 1
- **Red**: proxy.network
- **Dominio**: subdominio `silverbullet.${FQDN}`, raíz `${FQDN}`
- **Puerto interno**: 3000

## Ficheros
- **Quadlet(s)**: /data/self-hosted-podman/.config/containers/available/silverbullet/silverbullet.container
- **Volumen(es)**: NINGUNO
- **Config no secreta**: NINGUNO
- **Secretos**: silverbullet_sb_user

## Cómo funciona
- **Red**: proxy.network
- **Volúmenes**: NINGUNO
- **Secrets**: silverbullet_sb_user
- **EnvironmentFile**: NINGUNO
- **Socket del daemon**: NINGUNO
- **Healthcheck**: NINGUNO
- **Enrutado Traefik**: Host(`silverbullet.${FQDN}`) → puerto 3000
- **User/UserNS/NoNewPrivileges**: NINGUNO

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|

## Cómo habilitar / desplegar
1. Secretos (si existen): `printf '%s' '<valor>' | podman secret create silverbullet_sb_user -`
2. `cd .config/containers/available/silverbullet && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
