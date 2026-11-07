# facturascripts — Sistema de facturación web

## Qué es
**Aplicación**: facturascripts (image: `docker.io/facturascripts/facturascripts:latest`)
**Número de contenedores**: 2
**Red**: `proxy.network` (facturascripts) y `facturascripts.network` (mariadb)
**Dominio**: `fs.${FQDN}`
**Puerto interno**: `80`

## Ficheros
- Quadlet(s):
  - `/data/self-hosted-podman/.config/containers/available/facturascripts/facturascripts.container`
  - `/data/self-hosted-podman/.config/containers/available/facturascripts/facturascripts-mariadb.container`
- Volumen(es):
  - `/data/self-hosted-podman/.config/containers/available/facturascripts/facturascripts-volume`  *(bind: `%h/.config/facturascripts/facturascripts:/var/www/html:Z`)*
  - `/data/self-hosted-podman/.config/containers/available/facturascripts/facturascripts-mariadb-volume`  *(bind: `%h/.config/facturascripts/mariadb:/var/lib/mysql:Z`)*
- Config no secreta: —
- Secretos: —

## Cómo funciona
- Red `proxy.network` (facturascripts) y `facturascripts.network` (mariadb)
- Volúmenes: datos web en `%h/.config/facturascripts/facturascripts` y datos de MariaDB en `%h/.config/facturascripts/mariadb`
- Secretos: ninguno
- Healthcheck: no
- Enrutado Traefik: reglas en las Labels (puerto `80`)
- User/UserNS/NoNewPrivileges: no especificado

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| N/A | — | — | — |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store): —
2. `cd .config/containers/available/facturascripts && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)