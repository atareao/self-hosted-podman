# crowdsec — CrowdSec Security Engine

## Qué es
Aplicación de análisis de logs y protección DDoS.
- **App**: crowdsec
- **Imagen**: docker.io/crowdsecurity/crowdsec:latest
- **Contenedores**: 1
- **Red**: security.network
- **Dominio**: no Traefik router definido
- **Puerto interno**: no servicio expuesto a Traefik

## Ficheros
- **Quadlet(s)**: /data/self-hosted-podman/.config/containers/available/crowdsec/crowdsec.container
- **Volumen(es)**:
  - /data/self-hosted-podman/.config/containers/available/crowdsec/crowdsec-config.volume
  - /data/self-hosted-podman/.config/containers/available/crowdsec/crowdsec-data.volume
- **Config no secreta**: ninguna
- **Secretos**: ninguno

## Cómo funciona
- **Red**: security.network
- **Volúmenes**: configuracion y datos
- **EnvironmentFile**: ninguna
- **Socket del daemon**: ninguno
- **Healthcheck**: `cscli lapi status`
- **Enrutado Traefik**: no aplicable
- **User/UserNS/NoNewPrivileges**: valores por defecto de container

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| COLLECTIONS | Environment | "crowdsecurity/linux crowdsecurity/traefik crowdsecurity/http-cve" | Colecciones activadas |
| DISABLE_LOCAL_CONFIG | Environment | false | Desactiva config local |
| TZ | Environment | Europe/Madrid | Zona horaria |

## Cómo habilitar / desplegar
1. `cd .config/containers/available/crowdsec && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)
