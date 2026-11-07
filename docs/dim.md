# dim — Sistema de diagramas dinámicos

## Qué es
Herramienta de diagramación basada en web.
- **App**: dim
- **Imagen**: ghcr.io/dusk-labs/dim:dev
- **Contenedores**: 1
- **Red**: proxy.network
- **Dominio**: `dim.${FQDN}`
- **Puerto interno**: 8000

## Ficheros
- **Quadlet(s)**: /data/self-hosted-podman/.config/containers/available/dim/dim.container
- **Volumen(es)**:
  - /data/self-hosted-podman/.config/containers/available/dim/dim-media.volume
- **Config no secreta**: ninguna
- **Secretos**: ninguno

## Cómo funciona
- **Red**: proxy.network
- **Volúmenes**: configuraciones y medios persistentes
- **EnvironmentFile**: ninguna
- **Socket del daemon**: ninguno
- **Healthcheck**: ninguno
- **Enrutado Traefik**: router `dim` con puerto 8000
- **User/UserNS/NoNewPrivileges**: valores por defecto de container

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
(ninguna)

## Cómo habilitar / desplegar
1. `cd .config/containers/available/dim && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)
