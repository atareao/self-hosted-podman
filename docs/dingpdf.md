# dingpdf — Servicio de ingestión y visualización de PDFs

## Qué es
**Aplicación**: pdfding (image: `docker.io/mrmn/pdfding:latest`)
**Número de contenedores**: 1
**Red**: `proxy.network`
**Dominio**: `dingpdf.${FQDN}`
**Puerto interno**: `8000`

## Ficheros
- Quadlet(s):
  - `/data/self-hosted-podman/.config/containers/available/dingpdf/dingpdf-pdfding.container`
- Volumen(es):
  - `/data/self-hosted-podman/.config/containers/available/dingpdf/dingpdf-sqlite_data.volume`
  - `/data/self-hosted-podman/.config/containers/available/dingpdf/dingpdf-media.volume`
- Config no secreta: —
- Secretos:
  - `dingpdf_secret_key`

## Cómo funciona
- Red `proxy.network`
- Volúmenes: sqlite data en `/home/nonroot/pdfding/db`, media en `/home/nonroot/pdfding/media`
- Secretos:
  - `dingpdf_secret_key` (env target `SECRET_KEY`)
- Healthcheck: no
- Enrutado Traefik: reglas en las Labels
- User/UserNS/NoNewPrivileges: no especificado

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `DEFAULT_THEME` | Environment | `dark` | Tema predeterminado |
| `DEFAULT_THEME_COLOR` | Environment | `blue` | Color tema predeterminado |
| `HOST_NAME` | Environment | `pdfding.${FQDN}` | Nombre de host interno |
| `CSRF_COOKIE_SECURE` | Environment | `TRUE` | Cookies CSRF marcadas seguras |
| `SESSION_COOKIE_SECURE` | Environment | `TRUE` | Cookies de sesión marcadas seguras |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store): `printf '%s' '<valor>' | podman secret create dingpdf_secret_key -`
2. `cd .config/containers/available/dingpdf && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)