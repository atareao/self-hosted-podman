# matrix — Matrix Conduit y Element Web

## Qué es
Matrix Conduit y Element Web, Imágenes=docker.io/matrixconduit/matrix-conduit:latest y docker.io/vectorim/element-web, 2 contenedores, red proxy.network, Conduit en `matrix.${FQDN}` (router `conduit`) y Element Web en `element.${FQDN}` (router `element`), puertos internos 6167 y 80

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/matrix/matrix.container
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/matrix/matrix-element.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/matrix/matrix-db.volume
- Config no secreta: (ninguno)
- Secretos: (ninguno)

## Cómo funciona
Red: proxy.network. El contenedor Conduit usa el volumen matrix-db.volume montado en /var/lib/matrix-conduit/; Element Web no usa volúmenes.
Sin Secrets.
Sin EnvironmentFile.
Sin socket de daemon.
Ningún healthcheck.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| RUST_BACKTRACE | matrix.container | full | Backtrace de Rust |
| CONDUIT_SERVER_NAME | matrix.container | matrix.${FQDN} | Nombre del servidor Matrix |
| CONDUIT_DATABASE_PATH | matrix.container | /var/lib/matrix-conduit/ | Ruta de la base de datos |
| CONDUIT_DATABASE_BACKEND | matrix.container | rocksdb | Backend de base de datos |
| CONDUIT_PORT | matrix.container | 6167 | Puerto interno de Conduit |
| CONDUIT_MAX_REQUEST_SIZE | matrix.container | 20000000 | Tamaño máximo de petición |
| CONDUIT_ALLOW_REGISTRATION | matrix.container | False | Permitir registro |
| CONDUIT_ALLOW_FEDERATION | matrix.container | True | Permitir federación |
| CONDUIT_ALLOW_CHECK_FOR_UPDATES | matrix.container | True | Comprobar actualizaciones |
| CONDUIT_TRUSTED_SERVERS | matrix.container | ["matrix.org"] | Servidores de confianza |
| CONDUIT_ADDRESS | matrix.container | 0.0.0.0 | Dirección de escucha |
| CONDUIT_CONFIG | matrix.container | (vacío) | Configuración adicional |

## Cómo habilitar / desplegar
1. Secretos: (ninguno)
2. cd .config/containers/available/matrix && qctl install
3. systemctl --user daemon-reload

## Follow-ups
- Element Web en subdominio propio desde PLAN-023 (antes colisionaba con Conduit en `matrix.${FQDN}`).