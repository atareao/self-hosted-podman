# dufs — Servidor de ficheros web

## Qué es

dufs (`docker.io/sigoden/dufs`) es un servidor de ficheros (Rust) con subida/descarga, búsqueda,
control de acceso y WebDAV.

- **App / imagen (`Image=`):** `docker.io/sigoden/dufs` (sin tag -> `latest`), contenedor `dufs`.
- **Nº contenedores:** 1.
- **Red:** `proxy.network`, alias `dufs`.
- **Dominio:** `dufs.${FQDN}` (router Traefik `dufs`).
- **Puerto interno (Traefik):** `5000`.
- No hay `PublishPort`: el acceso es solo vía Traefik.

## Ficheros

- Quadlet: `.config/containers/available/dufs/dufs.container`
- Volumen: `.config/containers/available/dufs/dufs-data.volume` (`VolumeName=dufs-data`) → `/data`.
- Config no secreta: `.config/dufs/dufs.env` (+ `dufs.env.local` por máquina, gitignored).
- Secretos: `dufs_auth` (env target `DUFS_AUTH`).

## Cómo funciona

- **Red:** `proxy.network`.
- **Volumen:** `dufs-data` en `/data` (lo que se sirve).
- **Autenticación:** reglas en `DUFS_AUTH`, con formato de dufs `user:pass@/:rw`
  (varias reglas separadas por `|`). Si no se define regla anónima (`@/`), el acceso exige credenciales.
- **Permisos de operación:** `DUFS_ALLOW_ALL=true` habilita todas las operaciones (upload, delete,
  search, symlink, archive); en la práctica `:rw` sobre `/` ya concede todo lo permitido.
- **Enrutado Traefik:** servicio `dufs` puerto `5000`, router con `Host(`dufs.${FQDN}`)`, `websecure`,
  `certresolver=letsencrypt`, middlewares `seguridadHeaders@file,compresionHeaders@file`.
- **Healthcheck:** no define `Health*`. dufs expone `GET /__dufs__/health`.
- **Hardening:** sección vacía.
- **AutoUpdate:** `AutoUpdate=registry`; `PodmanArgs=--init`.

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `DUFS_SERVE_PATH` | `dufs.env` | `/data` | directorio servido |
| `DUFS_HIDDEN` | `dufs.env` | `tmp,*.log,*.lock` | rutas ocultas en los listados |
| `DUFS_ALLOW_ALL` | `dufs.env` | `true` | permite todas las operaciones |
| `DUFS_ALLOW_UPLOAD` | `dufs.env` | `true` | permite subir |
| `DUFS_ALLOW_DELETE` | `dufs.env` | `true` | permite eliminar |
| `DUFS_ALLOW_SEARCH` | `dufs.env` | `true` | permite buscar |
| `DUFS_ALLOW_SYMLINK` | `dufs.env` | `true` | permite enlaces simbólicos |
| `DUFS_ALLOW_ARCHIVE` | `dufs.env` | `true` | permite descargar carpetas como archivo |
| `DUFS_AUTH` | `Secret=dufs_auth,type=env` | *secreto* | reglas de acceso, p. ej. `admin:pass@/:rw` |
| `FQDN` | label del router | *(inyectada por systemd)* | dominio raíz |

## Cómo habilitar / desplegar

1. Crear el secreto de autenticación (NUNCA `crypta store`):
   - `printf '%s' 'admin:<password>@/:rw' | podman secret create dufs_auth -`
2. `cd .config/containers/available/dufs && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups

- Sin healthcheck ni hardening.
- Verificado que `DUFS_AUTH` llega por `Secret=` (antes el quadlet usaba `Environment=DUFS_AUTH=$DUFS_AUTH`, que systemd dejaba literal).

## Notas

- Histórico: hasta 2026-11-09 el quadlet usaba `Environment=DUFS_AUTH=$DUFS_AUTH` sin fuente; corregido a `Secret=` + `.env` de stack.

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (issue #8): desplegado, verificado end-to-end
(401 sin credenciales, 200 con credenciales válidas, 401 con credenciales incorrectas, cert LE OK) y
**purgado ese mismo día** (unit desenlazado, volumen `dufs-data`, secreto `dufs_auth` e imagen
eliminados). Estado actual: **no desplegado**.

Dos bugs latentes corregidos: (1) `Environment=DUFS_AUTH=$DUFS_AUTH` —systemd no expande `$VAR`— se
sustituyó por `Secret=dufs_auth,type=env,target=DUFS_AUTH` + `.config/dufs/dufs.env`; (2) los
`DUFS_ALLOW_*` usaban `True` y dufs exige `true` en minúscula (si no, el contenedor muere con
`invalid value 'True' for '--allow-all'`).