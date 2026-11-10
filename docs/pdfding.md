# pdfding — 

## Qué es
- app: pdfding
- Image: docker.io/mrmn/pdfding:latest
- nº contenedores: 1
- red: proxy.network
- dominio: subdominio pdfding.${FQDN} (root ${FQDN})
- puerto interno: 8000

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/pdfding/pdfding-pdfding.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/pdfding/pdfding-media.volume, /data/self-hosted-podman/.config/containers/available/pdfding/pdfding-sqlite_data.volume
- Config no secreta: none
- Secretos: pdfding_secret_key

## Cómo funciona
Usa la red proxy.network. Persiste datos en pdfding-sqlite_data.volume y pdfding-media.volume. Inyecta SECRET_KEY mediante secret. No tiene socket del daemon ni healthcheck. Traefik enruta a https://pdfding.${FQDN} con puerto 8000.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| DEFAULT_THEME | container | dark | Tema por defecto. |
| DEFAULT_THEME_COLOR | container | blue | Color por defecto. |
| HOST_NAME | container | "pdfding.${FQDN}" | Nombre del host para pdfding. |
| CSRF_COOKIE_SECURE | container | TRUE | Cookie CSRF segura. |
| SESSION_COOKIE_SECURE | container | TRUE | Cookie de sesión segura. |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store): `printf '%s' '<valor>' | podman secret create pdfding_secret_key -`
2. `cd .config/containers/available/pdfding && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-019, issue #14): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP 200) y **purgado ese mismo día**. Estado actual: **no desplegado**.

Requiere el secreto `pdfding_secret_key` (crear con `podman secret create`).

**Nota**: el stack duplicado `dingpdf` se eliminó del repo en PLAN-023 (issue #18) junto con su doc.