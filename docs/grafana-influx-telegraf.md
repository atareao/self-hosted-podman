# grafana-influx-telegraf — Monitoreo con Grafana, InfluxDB y Telegraf

## Qué es
Esta stack combina **Grafana** para visualización, **InfluxDB** para almacenamiento de series temporales y **Telegraf** para medición de métricas. Se despliega con imágenes oficiales: `grafana/grafana:latest`, `influxdb:1.8` y `telegraf:latest`. La stack consta de 3 contenedores, utiliza las redes `proxy.network` y `grafana-influx-telegraf.network`, y expone la dirección subdominio `grafana.${FQDN}` con el puerto interno `3000` gestionado por Traefik.

## Ficheros
- Quadlet(s):
  - `grafana-influx-telegraf-grafana.container`
  - `grafana-influx-telegraf-influxdb.container`
  - `grafana-influx-telegraf-telegraf.container`
- Volumen(es):
  - `grafana-influx-telegraf-data_grafana.volume`
  - `grafana-influx-telegraf-data_influxdb.volume`
- Config no secreta: *(ninguno)*
- Secretos: `grafana_influx_telegraf_gf_security_admin_password`

## Cómo funciona
- Red: Conexión a `proxy.network` para acceso público y a `grafana-influx-telegraf.network` para comunicación interna.
- Volúmenes: Persistencia de datos en los volumes `grafana` y `influxdb`.
- Secrets: Secreto `grafana_influx_telegraf_gf_security_admin_password` para la contraseña admin de Grafana.
- `EnvironmentFile`: Ninguno.
- `podman.socket`: No se expone el socket.
- Healthcheck: No definido.
- User: El contenedor `grafana` corre como root (UID 0). Se recomienda cambiar.
- NoNewPrivileges: No habilitado.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| INFLUXDB_DATA_ENGINE | grafana | tsm1 | motor de almacenamiento de InfluxDB |
| INFLUXDB_REPORTING_DISABLED | grafana | false | deshabilita reporte de uso |
| GF_INSTALL_PLUGINS | influxdb | grafana-clock-panel,briangann-gauge-panel,natel-plotly-panel,grafana-simple-json-datasource | plugins a instalar |
| GF_SECURITY_ADMIN_USER | influxdb | admin | usuario admin Grafana |
| GF_USERS_ALLOW_SIGN_UP | influxdb | FALSE | impedir registro externo |

## Cómo habilitar / desplegar
1. Secretos (solo si existen): `printf '%s' '<valor>' | podman secret create grafana_influx_telegraf_gf_security_admin_password -`
2. `cd .config/containers/available/grafana-influx-telegraf && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
