# dufs — File system explorer simple

## Qué es
**Aplicación**: dufs (image: `docker.io/sigoden/dufs`)
**Número de contenedores**: 1
**Red**: `proxy.network`
**Dominio**: `dufs.${FQDN}`
**Puerto interno**: `5000`

## Ficheros
- Quadlet(s):
  - `/data/self-hosted-podman/.config/containers/available/dufs/dufs.container`
- Volumen(es):
  - `/data/self-hosted-podman/.config/containers/available/dufs/dufs-data.volume`  *(bind: `dufs-data.volume:/data:Z`)*
- Config no secreta: —
- Secretos: —

## Cómo funciona
- Red `proxy.network`
- Volumen: `dufs-data.volume` para `/data`
- Secretos: ninguno
- Healthcheck: no
- Enrutado Traefik: reglas en las Labels
- User/UserNS/NoNewPrivileges: no especificado
- Volumen con permiso de escritura y enlace simbólico: `Z` para compatibilidad con Podman

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `DUFS_SERVE_PATH` | Environment | `/data` | directorio a servir |
| `DUFS_HIDDEN` | Environment | `tmp,*.log,*.lock` | Archivos ocultos |
| `DUFS_AUTH` | Environment | `$DUFS_AUTH` | Variable dinámica de autenticación |
| `DUFS_ALLOW_ALL` | Environment | `True` | Permite todo |
| `DUFS_ALLOW_UPLOAD` | Environment | `True` | Permite subir |
| `DUFS_ALLOW_DELETE` | Environment | `True` | Permite eliminar |
| `DUFS_ALLOW_SEARCH` | Environment | `True` | Permite buscar |
| `DUFS_ALLOW_SYMLINK` | Environment | `True` | Permite enlaces simbólicos |
| `DUFS_ALLOW_ARCHIVE` | Environment | `True` | Permite archivar |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store): —
2. `cd .config/containers/available/dufs && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)