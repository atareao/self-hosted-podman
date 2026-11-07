# zincobserve — Plataforma de observabilidad y métricas basada en Zinc

## Qué es
- App: zincobserve
- Imagen: public.ecr.aws/zinclabs/zincobserve:latest
- Nº contenedores: 1
- Red: proxy.network
- Dominio: Host `zincobserve.${FQDN}`
- Puerto interno: 5080

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/zincobserve/zincobserve.container
  - /data/self-hosted-podman/.config/containers/available/zincobserve/zincobserve-data.volume
- Volumen(es):
  - /data/self-hosted-podman/.config/containers/available/zincobserve/zincobserve-data.volume
- Config no secreta:
  - (none)
- Secretos:
  - (none)

## Cómo funciona
Red: proxy.network. Volumen montado en /data. No secretos ni variables de entorno. Enrutado con Traefik en puerto 5080 bajo el nombre de host `zincobserve.${FQDN}`.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|

## Cómo habilitar / desplegar
1. `cd .config/containers/available/zincobserve && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
