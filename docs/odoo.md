# odoo — Sistema de gestión empresarial Odoo

## Qué es
- **App:** Odoo
- **Imagen:** docker.io/library/odoo
- **Número de contenedores:** 2 (odoo, odoo-postgresql)
- **Red(es):** proxy.network, odoo.network
- **Dominio:** subdominio `odoo.${FQDN}` (con ${FQDN}=raíz del dominio)
- **Puerto interno:** 8069

## Ficheros
- Quadlet(s):
  - .config/containers/available/odoo/odoo.container
  - .config/containers/available/odoo/odoo-postgresql.container
- Volumen(es):
  - .config/containers/available/odoo/odoo-db.volume
  - .config/containers/available/odoo/odoo-odoo.volume
- Config no secreta: ninguno
- Secretos: odoo_password, odoo_postgres_password

## Cómo funciona
- **Red proxy.network:** conecta Odoo con Traefik para exponer el servicio.
- **Red odoo.network:** aislamiento interno para comunicación con PostgreSQL.
- **Volumes:** almacenamiento persistente de datos de Odoo y PostgreSQL.
- **Secrets:** contraseña de Odoo y PostgreSQL.
- **EnvironmentFile:** ninguno.
- **Healthcheck:** no definido.
- **Traefik:** enrutado por `odoo.${FQDN}` y balanciar puerto 8069.
- **User:** no se especifica (usa usuario por defecto del contenedor).

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| HOST | odoo.container | db | Host del DB |
| USER | odoo.container | $POSTGRES_USER | Usuario del DB |
| POSTGRES_USER | odoo-postgresql.container | $POSTGRES_USER | Usuario de PostgreSQL |
| POSTGRES_DB | odoo-postgresql.container | postgres | Base de datos por defecto |

## Cómo habilitar / desplegar
1. Secretos:
   ```bash
   printf '%s' '<valor>' | podman secret create odoo_password -
   printf '%s' '<valor>' | podman secret create odoo_postgres_password -
   ```
2. `cd .config/containers/available/odoo && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
