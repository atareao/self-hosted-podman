# vector — Recolector y enrutador de logs

## Qué es

Vector: recolector, transformador y enrutador de logs basado en Rust (imagen `docker.io/timberio/vector:latest-alpine`). Un único contenedor (`vector`). Red: `security.network`. No está detrás de Traefik: no publica dominio ni usa `proxy.network`; envía los logs a otros servicios (p. ej. OpenObserve). No publica puertos.

## Ficheros

- Quadlet(s): `.config/containers/available/vector/vector.container`
- Volumen(es): `.config/containers/available/vector/vector-data.volume`
- Red(es): `.config/containers/available/vector/security.network`
- Config no secreta: `.config/vector/vector.env` (versionada); overrides de máquina en `.config/vector/vector.env.local` (gitignored, creado por el hook `post_pull`)
- Secretos: `openobserve_root_password` (activo, el mismo que usa la stack OpenObserve)

## Cómo funciona

Vector se une a `security.network` y recolecta logs del daemon Podman. Monta:
`%t/podman/podman.sock` en `/var/run/docker.sock` (`:ro`) para leer metadata de contenedores; el fichero de config `%h/.config/vector/vector.yaml` en `/etc/vector/vector.yaml` (`:ro,Z`); y el volumen nombrado `vector-data.volume` en `/var/lib/vector` (`:Z`) para el estado/buffers. **No** monta `/var/log/journal` ni `/run/log/journal` ni usa `AddCapability` (no hay source `journald`; el único source es `docker_logs`).

La config no secreta se inyecta con `EnvironmentFile=%h/.config/vector/vector.env` y, después, `%h/.config/vector/vector.env.local` (el segundo sobrescribe al primero). Las credenciales se inyectan con Podman secrets como variables de entorno: `openobserve_root_password`→`OO_USER_PASSWORD` (el mismo secreto que usa OpenObserve, garantizando que el login coincide). El sink de CrowdSec se **eliminó** en este lote (sin ingest configurado), así que ya no existe `VECTOR_INGEST_PASSWORD`. El `vector.yaml` es un fichero plano con interpolación `${VAR}` nativa de Vector (ya no es `.jinja`).

El sink `openobserve` usa un **URI fijo** `http://openobserve:5080/api/default/vector/_json`: el sink `http` de Vector no interpola campos por evento, así que todas las líneas van al stream `vector`.

Healthcheck: `vector validate --config-yaml /etc/vector/vector.yaml` (cada 90 s, `HealthStartPeriod=15s`). Arranca con `Restart=on-failure`, `ExecStartPre=/usr/bin/sleep 2` y `ExecStartPost` esperando a `healthy` (atención al **quoting** del `ExecStartPost`: la `"` de cierre tras `vector)` es obligatoria, sin ella la unit falla con `status=2/INVALIDARGUMENT`). No define `User`/`NoNewPrivileges` ni `AddCapability`.

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `VECTOR_SELF_DATA_DIR` | `vector.container` (`Environment=`) | `/var/lib/vector` | Directorio de datos propios de Vector (buffers/estado) |
| `OO_USER_EMAIL` | `.config/vector/vector.env` | `admin@example.com` | Email de usuario de OpenObserve (debe coincidir con `ZO_ROOT_USER_EMAIL` de la stack openobserve) |
| `OO_USER_PASSWORD` | `vector.container` (`Secret=openobserve_root_password`) | *(secreto)* | Password de OpenObserve (mismo secreto que usa esa stack) |

## Cómo habilitar / desplegar

1. Crear el secreto (NUNCA `crypta store`), reutilizando el de OpenObserve si ya existe:
   - `printf '%s' '<openobserve-root-password>' | podman secret create openobserve_root_password -`
2. Revisar/ajustar `.config/vector/vector.env` (y `.config/vector/vector.env.local` si hace falta).
3. `cd .config/containers/available/vector && qctl install`
4. `systemctl --user daemon-reload`

## Follow-ups

- **Ingest de CrowdSec**: el sink `crowdsec` se eliminó porque CrowdSec aún no define ingest; reintroducirlo (y crear `crowdsec_ingest_password` con `podman secret create`) cuando exista.
- **Dependencia de OpenObserve**: el sink apunta a `openobserve`, que **no está desplegado**; el DNS no resuelve y Vector reintenta. Desplegar `openobserve` (o ajustar el sink) para que la entrega de logs funcione de extremo a extremo.
- `vector.yaml` depende del intérprete `${VAR}` de Vector; mantener las variables documentadas en `vector.env`.
