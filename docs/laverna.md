# laverna — Laverna es una aplicación web de toma de notas.

## Qué es
Laverna, Imagen=docker.io/atareao/laverna:v1.0, 1 contenedor, red proxy.network, dominio laverna.${FQDN}, puerto interno 8080

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/laverna/laverna.container
- Volumen(es): (ninguno)
- Config no secreta: (ninguno)
- Secretos: (ninguno)

## Cómo funciona
Red: proxy.network. Volumenes: (ninguno).
Sin Secrets.
Sin EnvironmentFile.
Sin socket de daemon.
Ningún healthcheck.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|

## Cómo habilitar / desplegar
1. Secretos: (ninguno)
2. cd .config/containers/available/laverna && qctl install
3. systemctl --user daemon-reload

## Follow-ups
(ninguno)