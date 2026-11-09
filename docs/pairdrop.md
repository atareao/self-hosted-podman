# pairdrop — Servicio de transferencia de archivos peer‑to‑peer

## Qué es
- **App:** PairDrop
- **Imagen:** ghcr.io/schlagmichdoch/pairdrop
- **Número de contenedores:** 1 (pairdrop)
- **Red(es):** proxy.network
- **Dominio:** subdominio `pairdrop.${FQDN}`
- **Puerto interno:** 3000

## Ficheros
- Quadlet(s):
  - .config/containers/available/pairdrop/pairdrop.container
- Volumen(es):
  - ninguno
- Config no secreta: ninguno
- Secretos: ninguno

## Cómo funciona
- **Red proxy.network:** conectividad con Traefik para la exposición pública.
- **Healthcheck:** no definido.
- **Traefik:** enrutado por `pairdrop.${FQDN}` y puerto 3000.
- **User:** no especificado.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| — | — | — | — |

## Cómo habilitar / desplegar
1. Secretos: ninguno.
2. `cd .config/containers/available/pairdrop && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-014, issue #9): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP OK) y **purgado ese mismo día** (unit desenlazado,
volumen/binds e imagen eliminados). Estado actual: **no desplegado**.
