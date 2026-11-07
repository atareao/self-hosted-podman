# dasherr — Servicio proxy con autenticación HTTP

## Qué es
Servidor Nginx con autenticación básica para proteger endpoints.
- **App**: dasherr
- **Imagen**: docker.io/atareao/dasherr
- **Contenedores**: 1
- **Red**: proxy.network
- **Dominio**: `nginx.${FQDN}`
- **Puerto interno**: 8080

## Ficheros
- **Quadlet(s)**: /data/self-hosted-podman/.config/containers/available/dasherr/dasherr.container
- **Volumen(es)**: ninguno
- **Config no secreta**: ninguna
- **Secretos**: ninguno

## Cómo funciona
- **Red**: proxy.network
- **Volúmenes**: archivo htpasswd montado en `/opt/nginx/conf/.htpasswd`
- **EnvironmentFile**: ninguna
- **Socket del daemon**: ninguno
- **Healthcheck**: ninguno
- **Enrutado Traefik**: router `dasherr` con puerto 8080
- **User/UserNS/NoNewPrivileges**: valores por defecto de container

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
(ninguna)

## Cómo habilitar / desplegar
1. `cd .config/containers/available/dasherr && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)
