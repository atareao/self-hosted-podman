# bentopdf — visor y editor de PDF

## Qué es
- Aplicación: visor y editor de PDF
- Imagen: `docker.io/bentopdf/bentopdf`
- Contenedores: 1
- Red: `proxy.network`
- Dominio: `pdf.${FQDN}`
- Puerto interno: 8080

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/bentopdf/bentopdf.container
- Volumen(es): (ninguno)
- Config no secreta: (ninguna)
- Secretos: (ninguno)

## Cómo funciona
- Se conecta a la red `proxy.network` y es accesible vía Traefik en `pdf.${FQDN}`.
- No utiliza volúmenes ni secretos.
- No se define Healthcheck.
- El contenedor corre con su usuario/ID sin privilegios.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| (n/a) | | | |

## Cómo habilitar / desplegar
1. Secretos (si existen): (ninguno)
2. `cd .config/containers/available/bentopdf && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
