# matrixmail — Matrixmail es un cliente de correo basado en Matrix.

## Qué es
Matrixmail, Imagen=docker.io/atareao/matrixmail:latest, 1 contenedor, red (ninguna), dominio (ninguno), puerto interno (ninguno)

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/matrixmail/matrixmail.container
- Volumen(es): (ninguno)
- Config no secreta: (ninguno)
- Secretos: (ninguno)

## Cómo funciona
Sin red externa. No hay volúmenes.
Sin Secrets.
Sin EnvironmentFile.
Ningún socket de daemon.
Ningún healthcheck.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| RUST_LOG | matrixmail.container | DEBUG | Registro de Rust |

## Cómo habilitar / desplegar
1. Secretos: (ninguno)
2. cd .config/containers/available/matrixmail && qctl install
3. systemctl --user daemon-reload

## Follow-ups
- **Sin enrutado por diseño**: el stack no declara labels de Traefik (igual que en el repo origen `atareao/self-hosted`); si hay que exponerlo, se añaden labels `Host(`<subdominio>.${FQDN}`)` propias. Ver los invariantes de enrutado en `docs/traefik.md`.