# crowdsec — CrowdSec Security Engine

## Qué es
Security Engine **global** de análisis de logs y protección DDoS; su LAPI alimenta el bouncer de Traefik.
- **App**: crowdsec
- **Imagen**: docker.io/crowdsecurity/crowdsec:v1.8.2
- **Contenedores**: 1
- **Red**: security.network, proxy.network
- **Dominio**: no Traefik router definido
- **Puerto interno**: LAPI en 8080 (consumido por el bouncer de Traefik; no publicado por Traefik)

## Ficheros
- **Quadlet(s)**:
  - /data/self-hosted-podman/.config/containers/available/crowdsec/crowdsec.container
  - /data/self-hosted-podman/.config/containers/available/crowdsec/crowdsec-config.volume
  - /data/self-hosted-podman/.config/containers/available/crowdsec/crowdsec-data.volume
- **Volumen(es)**:
  - /data/self-hosted-podman/.config/containers/available/crowdsec/crowdsec-config.volume -> /etc/crowdsec
  - /data/self-hosted-podman/.config/containers/available/crowdsec/crowdsec-data.volume -> /var/lib/crowdsec/data
  - Bind: %h/.config/crowdsec/acquis.yaml -> /etc/crowdsec/acquis.d/local.yaml
- **Config no secreta**: .config/crowdsec/acquis.yaml; .config/traefik/dynamic/crowdsec.yml.jinja
- **Secretos**: crowdsec_bouncer_key (store de secretos; lo consume la plantilla `crowdsec.yml.jinja`)

## Cómo funciona
- **Red**: security.network y proxy.network — el bouncer de Traefik (en proxy.network) alcanza el LAPI en `crowdsec:8080`
- **Volúmenes**: configuración y datos; además, `acquis.yaml` se monta en `/etc/crowdsec/acquis.d/local.yaml` (dentro de `acquis.d/` y **no** en `/etc/crowdsec/acquis.yaml`, porque el volumen tapa el directorio padre)
- **EnvironmentFile**: ninguna
- **Socket del daemon**: ninguno
- **Healthcheck**: `cscli lapi status`
- **Enrutado Traefik**: no aplicable (no expone servicio propio)
- **Security Engine global**: la clave del bouncer vive en el store de secretos (`crowdsec_bouncer_key`) y `.config/traefik/dynamic/crowdsec.yml` se renderiza desde `crowdsec.yml.jinja`. El `traefik-bouncer` queda registrado y validado, y el middleware `crowdsec-bouncer@file` se aplica globalmente en el entrypoint `websecure` de `traefik.yml`.
- **Restart**: `on-failure`
- **User/UserNS/NoNewPrivileges**: valores por defecto de container

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| COLLECTIONS | Environment | "crowdsecurity/linux crowdsecurity/traefik crowdsecurity/http-cve" | Colecciones activadas |
| DISABLE_LOCAL_CONFIG | Environment | false | Desactiva config local |
| TZ | Environment | Europe/Madrid | Zona horaria |

## Cómo habilitar / desplegar
1. Asegura la clave del bouncer `crowdsec_bouncer_key` en el store de secretos que lee unjinja.
2. Renderiza `.config/traefik/dynamic/crowdsec.yml` desde `crowdsec.yml.jinja` (unjinja / hook `post_pull`).
3. `cd .config/containers/available/crowdsec && qctl install`
4. `systemctl --user daemon-reload`

> Este stack **no se purga**: es el Security Engine global y queda en producción.

## Follow-ups
(ninguno)
