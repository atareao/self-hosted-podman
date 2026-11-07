# zincsearch — Motor de búsqueda de texto completo Zinc

## Qué es
- App: zincsearch
- Imagen: public.ecr.aws/h9e2j3o7/zinc:latest
- Nº contenedores: 1
- Red: proxy.network
- Dominio: Host `zinc.${FQDN}`
- Puerto interno: 4080

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/zincsearch/zincsearch.container
  - /data/self-hosted-podman/.config/containers/available/zincsearch/zincsearch-data.volume
- Volumen(es):
  - /data/self-hosted-podman/.config/containers/available/zincsearch/zincsearch-data.volume
- Config no secreta:
  - (none)
- Secretos:
  - zincsearch_zinc_first_admin_password (tipo=env, target=ZINC_FIRST_ADMIN_PASSWORD)
  - zincsearch_token (tipo=env, target=TOKEN)

## Cómo funciona
Red: proxy.network. Volumen montado en /data. Secretos: zincsearch_zinc_first_admin_password y zincsearch_token. Variables de entorno: DATA_PATH=/data, ZINC_FIRST_ADMIN_USER=atareao. Enrutado con Traefik en puerto 4080 bajo el nombre de host `zinc.${FQDN}`.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| DATA_PATH | Environment | /data | Ruta donde Zinc escribe los datos |
| ZINC_FIRST_ADMIN_USER | Environment | atareao | Usuario administrador inicial |

## Cómo habilitar / desplegar
1. `printf '%s' '<valor>' | podman secret create zincsearch_zinc_first_admin_password -`
2. `printf '%s' '<valor>' | podman secret create zincsearch_token -`
3. `cd .config/containers/available/zincsearch && qctl install`
4. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
