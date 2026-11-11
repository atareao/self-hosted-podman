# metube — Metube es un servidor de vídeo.

## Qué es
Metube, Imagen=docker.io/alexta69/metube, 1 contenedor, red proxy.network, dominio metube.${FQDN}, puerto interno 8081

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/metube/metube.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/metube/metube-data.volume
- Config no secreta: (ninguno)
- Secretos: (ninguno)

## Cómo funciona
Red: proxy.network. Volumen: metube-data.volume montado en /downloads.
Sin Secrets.
Sin EnvironmentFile.
Sin socket de daemon.
Ningún healthcheck.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|

## Cómo habilitar / desplegar
1. Secretos: (ninguno)
2. cd .config/containers/available/metube && qctl install
3. systemctl --user daemon-reload

## Follow-ups
- (ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-012, issue #6): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP OK) y **purgado ese mismo día** (units desenlazados,
volúmenes e imágenes eliminados). Estado actual: **no desplegado**.