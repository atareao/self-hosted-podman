# searxng — motor de búsqueda de consultas metarevisadas en open source

## Qué es
- **Aplicación**: searxng (Imagen: `docker.io/searxng/searxng:latest`)
- **Nº de contenedores**: 2 (searxng, searxng-redis)
- **Red**: `proxy.network`
- **Dominio**: subdominio `searxng.${FQDN}`
- **Puerto interno**: `8080` (traefik.http.services.searxng.loadbalancer.server.port)

## Ficheros
- **Quadlet(s)**:
  - /data/self-hosted-podman/.config/containers/available/searxng/searxng.container
  - /data/self-hosted-podman/.config/containers/available/searxng/searxng-redis.container
- **Volumen(es)**:
  - /data/self-hosted-podman/.config/containers/available/searxng/searxng-data.volume
- **Config no secreta**: N/A
- **Secretos**: N/A

## Cómo funciona
- **Red**: `proxy.network`
- **Volúmenes**: `/etc/searxng` mapeado a `searxng-data.volume`
- **Secrets**: N/A
- **EnvironmentFile**: N/A
- **Socket del daemon**: N/A
- **Healthcheck**: N/A
- **Enrutado Traefik**: etiquetas especificadas en la sección `Labels` del quadlet
- **User/NoNewPrivileges**: N/A

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| SEARXNG_BASE_URL | searxng.container | https://localhost/ | URL base de searxng |

## Cómo habilitar / desplegar
1. Secretos (si existen): NUNCA `crypta store`.
2. `cd /data/self-hosted-podman/.config/containers/available/searxng && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)
