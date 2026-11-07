# portainer — Interfaz web de gestión de contenedores

## Qué es
Portainer, basado en la imagen `docker.io/portainer/portainer-ce:alpine`. Número de contenedores: 1 (portainer). Red(es): `proxy.network`. Dominio(s): `portainer.${FQDN}` subdominio (label `traefik.http.routers.portainer.rule`). Puerto interno: 9000 (label `traefik.http.services.portainer.loadbalancer.server.port`).

## Ficheros
- Quadlet(s):
  - `/data/self-hosted-podman/portainer.container`
- Volumen(es):
  - `/data/self-hosted-podman/portainer-data.volume`
- Config no secreta: (no dispone de .env)
- Secretos:
  - (ninguno)

## Cómo funciona
Utiliza la red `proxy.network` para la exposición a Traefik y monta el socket de Podman `%t/podman/podman.sock` para administrar contenedores locales. Se ejecuta como usuario no root con `Restart=always`. Traefik enruta el tráfico a través del puerto interno 9000.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| (ninguna) |

## Cómo habilitar / desplegar
1. `cd .config/containers/available/portainer && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
