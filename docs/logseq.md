# logseq — Logseq es una herramienta de toma de notas colaborativa.

## Qué es
Logseq, Imagen=ghcr.io/logseq/logseq-webapp:latest, 1 contenedor, red proxy.network, dominio logseq.${FQDN}, puerto interno 80

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/logseq/logseq.container
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
2. cd .config/containers/available/logseq && qctl install
3. systemctl --user daemon-reload

## Follow-ups
(ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-015, issue #10): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP 200) y **purgado ese mismo día** (unit desenlazado,
volumenes/binds e imagen eliminados). Estado actual: **no desplegado**.