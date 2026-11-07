# opengist — Servicio de Gists de código abierto similar a GitHub Gist

## Qué es
- **App:** opengist
- **Imagen:** ghcr.io/thomiceli/opengist:latest
- **Número de contenedores:** 1 (opengist)
- **Red(es):** proxy.network
- **Dominio:** subdominio `gist.${FQDN}`
- **Puerto interno:** 6157

## Ficheros
- Quadlet(s):
  - .config/containers/available/opengist/opengist.container
- Volumen(es):
  - .config/containers/available/opengist/opengist-data.volume
- Config no secreta: ninguno
- Secretos: opengist_og_gitea_client_key, opengist_og_gitea_secret

## Cómo funciona
- **Red proxy.network** se usa para exponer el servicio a través de Traefik.
- **Volumes:** almacenamiento persistente de la base de datos del servicio.
- **Secrets:** credenciales para integrarse con Gitea.
- **EnvironmentFile:** ninguno.
- **Healthcheck:** no definido.
- **Traefik:** enrutado por `gist.${FQDN}` y balanceo en puerto 6157.
- **User:** se establece UID 1000 y GID 1000.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| UID | opengist.container | 1000 | UID del proceso |
| GID | opengist.container | 1000 | GID del proceso |
| OG_GITEA_URL | opengist.container | https://gitea.${FQDN} | URL de Gitea |

## Cómo habilitar / desplegar
1. Secretos:
   ```bash
   printf '%s' '<valor>' | podman secret create opengist_og_gitea_client_key -
   printf '%s' '<valor>' | podman secret create opengist_og_gitea_secret -
   ```
2. `cd .config/containers/available/opengist && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
