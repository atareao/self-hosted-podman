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
1. Crear el secreto (NUNCA `crypta store`):
   `printf '%s' "$(openssl rand -base64 24)" | podman secret create zincobserve_root_password -`
2. El email raíz se configura en `.config/zincobserve/zincobserve.env` (`ZO_ROOT_USER_EMAIL`).
3. `cd .config/containers/available/zincobserve && qctl install`
4. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-017, issue #12): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP 200) y **purgado ese mismo día**. Estado actual: **no desplegado**.

**Bug corregido**: zincobserve exige `ZO_ROOT_USER_EMAIL` y `ZO_ROOT_USER_PASSWORD`
(`Please set root user email-id & password using ZO_ROOT_USER_EMAIL & ZO_ROOT_USER_PASSWORD`) y el
quadlet no los aportaba. Se añadió `EnvironmentFile=%h/.config/zincobserve/zincobserve.env`
(con `ZO_ROOT_USER_EMAIL=admin@example.com`) y `Secret=zincobserve_root_password,type=env,target=ZO_ROOT_USER_PASSWORD`.
