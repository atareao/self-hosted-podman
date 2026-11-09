# ferrishare — Ferrishare es un servicio de compartición de archivos interno

## Qué es
App: ferrishare
Imagen: ghcr.io/tobiasmarschner/ferrishare
Nº contenedores: 1
Red: proxy.network
Dominio: subdominio `ferrishare.${FQDN}`
Puerto interno: 3000

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/ferrishare/ferrishare.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/ferrishare/ferrishare-data.volume
- Config no secreta:
- Secretos:

## Cómo funciona
Red proxy.network, volumen ferrishare-data.volume, socket del daemon (none), healthcheck (none), enrutado Traefik, User/UserNS/NoNewPrivileges (none).

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| | | | |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store):
2. `cd .config/containers/available/ferrishare && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
(ninguno)

## Estado de despliegue

**No desplegable tal cual** (2026-11-09, PLAN-015, issue #10). El contenedor muere al arrancar con
`Failed to open configuration file at "./data/config.toml"`: ferrishare exige crear su `config.toml`
con un setup **interactivo** (`ferrishare --init`, que pide la contraseña de administrador y genera su
hash argon2id) antes del primer arranque. El quadlet no lo genera. Estado actual: **no desplegado**.
Follow-up: documentar/automatizar el `--init` (p. ej. `podman run --rm -it -v <volumen>:/app/data <img> --init`)
antes de poder desplegar ferrishare.