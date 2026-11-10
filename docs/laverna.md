# laverna — Laverna es una aplicación web de toma de notas.

## Qué es
Laverna, Imagen=docker.io/olegfiksel/laverna:0.7.54, 1 contenedor, red proxy.network, dominio laverna.${FQDN}, puerto interno 80

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/laverna/laverna.container
- Volumen(es): (ninguno)
- Config no secreta: (ninguno)
- Secretos: (ninguno)

## Cómo funciona
Red: proxy.network. No volumenes.
Autenticación gestionada por Traefik mediante middleware `laverna-auth` (definido en `.config/traefik/dynamic/laverna-auth.yml`).
No Secrets ni EnvironmentFile.
No socket de daemon.
Ningún healthcheck.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|

## Cómo habilitar / desplegar
1. Crear ~/.config/traefik/dynamic/laverna.htpasswd (usando `htpasswd -nB usuario`) y reiniciar Traefik: `systemctl --user restart traefik`.
2. cd .config/containers/available/laverna && qctl install
3. systemctl --user daemon-reload

## Follow-ups
- Laverna está abandonada (última release ~2018); valorar migración a otra app de notas.