# memos — Memos es un servicio de anotaciones.

## Qué es
Memos, Imagen=docker.io/neosmemo/memos:stable, 1 contenedor, red proxy.network, dominio memos.${FQDN}, puerto interno 5230

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/memos/memos.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/memos/memos-memos.volume
- Config no secreta: (ninguno)
- Secretos: (ninguno)

## Cómo funciona
Red: proxy.network. Volumen: memos-memos.volume montado en /var/opt/memos.
Sin Secrets.
Sin EnvironmentFile.
Sin socket de daemon.
Ningún healthcheck.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|

## Cómo habilitar / desplegar
1. Secretos: (ninguno)
2. cd .config/containers/available/memos && qctl install
3. systemctl --user daemon-reload

## Follow-ups
- (ninguno)

## Estado de despliegue

Desplegado y verificado en producción (`new_atareao`) el 2026-11-09 (PLAN-011, issue #5).
URL: https://memos.servidorlinux.es — cert LE válido, router Traefik activo.
Imagen `docker.io/neosmemo/memos:stable` (el tag `latest` no existe).