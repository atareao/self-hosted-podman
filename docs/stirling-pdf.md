# stirling-pdf — Suite web de herramientas PDF

## Qué es

Stirling PDF es una suite web (autoalojada) para manipular PDF: unir, dividir, comprimir, OCR, conversiones, firmas, etc.

- **App / imagen (`Image=`):** `docker.io/stirlingtools/stirling-pdf:latest`, contenedor `stirling-pdf`.
- **Nº contenedores:** 1.
- **Red:** `proxy.network` (red edge de Traefik), alias `stirlingpdf`.
- **Dominio:** `stirling-pdf.${FQDN}` → **subdominio** `stirling-pdf` (router Traefik `stirlingpdf`).
- **Puerto interno (Traefik):** `8080` (`traefik.http.services.stirlingpdf.loadbalancer.server.port=8080`).
- No hay `PublishPort`: el acceso es solo vía Traefik.

## Ficheros

- Quadlet(s): `.config/containers/available/stirling-pdf/stirling-pdf.container`
- Volumen(es):
  - `.config/containers/available/stirling-pdf/stirling-pdf-trainingData.volume`
  - `.config/containers/available/stirling-pdf/stirling-pdf-extraConfigs.volume`
  - `.config/containers/available/stirling-pdf/stirling-pdf-customFiles.volume`
  - `.config/containers/available/stirling-pdf/stirling-pdf-logs.volume`
  - `.config/containers/available/stirling-pdf/stirling-pdf-pipeline.volume`
- Config no secreta: no existe `.env` de stack (no hay `.config/stirling-pdf/`).
- Secretos: ninguno (`Secret=` no declarado).

## Cómo funciona

- **Red:** el contenedor se une a `proxy.network`, por lo que Traefik lo descubre y enruta; no hay red interna propia (servicio único).
- **Enrutado Traefik:** `traefik.enable=true`, servicio `stirlingpdf` en el puerto `8080`, router `stirlingpdf` con `Host(\`stirling-pdf.${FQDN}\`)`, entrypoint `websecure`, `certresolver=letsencrypt` y middlewares `seguridadHeaders@file,compresionHeaders@file`.
- **Volúmenes:** cinco volúmenes nombrados persisten datos que de otro modo vivirían dentro del contenedor:
  - `stirling-pdf-trainingData` → `/usr/share/tessdata` (datos de entrenamiento OCR/Tesseract).
  - `stirling-pdf-extraConfigs` → `/configs` (configuración extra).
  - `stirling-pdf-customFiles` → `/customFiles/` (ficheros propios, p. ej. plantillas/estilos).
  - `stirling-pdf-logs` → `/logs/` (logs de la app).
  - `stirling-pdf-pipeline` → `/pipeline/` (automatizaciones/pipelines).
- **Secretos / EnvironmentFile:** no hay `Secret=` ni `EnvironmentFile`; toda la config no secreta va como `Environment=`.
- **Socket del daemon:** no monta `podman.sock`.
- **Healthcheck:** no define `Health*`.
- **Hardening:** sección `Hardening` vacía (sin `User`, `NoNewPrivileges` ni `ReadOnly`).
- **AutoUpdate:** `AutoUpdate=registry` (imagen `latest`).
- **Arranque:** `After=network-online.target traefik.service`, `Restart=always`, `RestartSec=10s`, `StartLimitIntervalSec=300`, `StartLimitBurst=3`, `TimeoutStartSec=60`, `WantedBy=default.target`. `PodmanArgs=--init`.

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `DOCKER_ENABLE_SECURITY` | `stirling-pdf.container` (`Environment=`) | `False` | Desactiva la capa de seguridad/login propia de Stirling PDF (el acceso se controla en Traefik) |
| `LANGS` | `stirling-pdf.container` (`Environment=`) | `es_ES` | Idiomas de la interfaz (español) |
| `FQDN` | `stirling-pdf.container` (label `traefik.http.routers.stirlingpdf.rule`) | *(inyectada por systemd desde `~/.config/environment.d/fqdn.conf`)* | Dominio raíz del host; el stack usa `stirling-pdf.${FQDN}` |

No hay `.env` de stack para este servicio.

## Cómo habilitar / desplegar

1. No requiere secretos.
2. `cd .config/containers/available/stirling-pdf && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups

- `DOCKER_ENABLE_SECURITY=False` deja la app sin autenticación propia; el servicio queda protegido únicamente por Traefik (`websecure` + middlewares). Valorar activarla si se quiere login propio.
- Sin healthcheck ni hardening (`User`, `NoNewPrivileges`, `ReadOnly`).
- Imagen `latest` con `AutoUpdate=registry`: las actualizaciones pueden introducir cambios de comportamiento sin aviso.

## Estado de despliegue

Desplegado y verificado en producción (`new_atareao`) el 2026-11-09 (PLAN-011, issue #5), y
**desinstalado ese mismo día**: units desenlazados (`qctl uninstall`), volúmenes, secretos y datos
eliminados. Estado actual: **no desplegado**.
