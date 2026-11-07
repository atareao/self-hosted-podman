# audiobookshelf — gestor de audiolibros

## Qué es
- Aplicación: gestor de audiolibros
- Imagen: `ghcr.io/advplyr/audiobookshelf:latest`
- Contenedores: 1
- Red: `proxy.network`
- Dominio: `books.${FQDN}`
- Puerto interno: 80

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/audiobookshelf/audiobookshelf.container
- Volumen(es):
  - /data/self-hosted-podman/.config/containers/available/audiobookshelf/audiobookshelf-books.volume
  - /data/self-hosted-podman/.config/containers/available/audiobookshelf/audiobookshelf-config.volume
  - /data/self-hosted-podman/.config/containers/available/audiobookshelf/audiobookshelf-metadata.volume
- Config no secreta: (ninguna)
- Secretos: (ninguno)

## Cómo funciona
- Conectado a la red `proxy.network` y expuesto a través de Traefik en `books.${FQDN}`.
- Se guardan los libros y metadatos en los volúmenes montados bajo `/books`, `/config` y `/metadata`.
- No se especifica healthcheck.
- El contenedor utiliza UID/GID no privilegiado.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| (n/a) | | | |

## Cómo habilitar / desplegar
1. Secretos (si existen): (ninguno)
2. `cd .config/containers/available/audiobookshelf && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
