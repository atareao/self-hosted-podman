# rabbitmq — Sistema de colas de mensajes

## Qué es
- **App**: rabbitmq
- **Imagen**: docker.io/library/rabbitmq:3-management
- **Nº contenedores**: 1 (rabbitmq)
- **Red**: proxy.network
- **Dominio**: mq.${FQDN} (subdominio "mq")
- **Puerto interno**: 15672 (traefik http.services rabbitmq loadbalancer.port)

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/rabbitmq/rabbitmq.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/rabbitmq/rabbitmq-data.volume
- Config no secreta: ninguno
- Secretos: rabbitmq_default_pass

## Cómo funciona
- **Red**: proxy.network
- **Volúmenes**: rabbitmq-data.volume -> `/var/lib/rabbitmq/mnesia:U` (el sufijo `:U` hace `chown` del volumen al uid del contenedor)
- **Secretos**: rabbitmq_default_pass (`type=env`, `target=RABBITMQ_DEFAULT_PASS`)
- **Healthcheck**: `rabbitmq-diagnostics -q ping` (30 s / 5 reintentos / timeout 10 s / `HealthStartPeriod=30s`)
- **Routing Traefik**: Host(`mq.${FQDN}`), puerto 15672
- **User/UserNS/NoNewPrivileges**: `User=rabbitmq` en `[Container]`

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| RABBITMQ_DEFAULT_USER | Environment | admin | usuario de rabbitmq |
| RABBITMQ_DEFAULT_PASS | Secret (`type=env`) | `rabbitmq_default_pass` | contraseña del usuario admin |

## Cómo habilitar / desplegar
1. Secretos (NUNCA crypta store): `openssl rand -base64 32 | podman secret create rabbitmq_default_pass -`
2. `cd .config/containers/available/rabbitmq && qctl install`
3. `systemctl --user daemon-reload`

## Verificación E2E (2026-11-13)

Verificado en producción (`new_atareao`, usuario `runner`) y después purgado:

1. Unit `rabbitmq` → `active`.
2. Contenedor `rabbitmq` → `Up (healthy)`.
3. Router `rabbitmq@docker` registrado en Traefik (servicio → `15672`).
4. Certificado válido con el resolver `letsencrypt-staging`.
5. `https://mq.${FQDN}` → `200` (consola de management).

Bugs latentes corregidos para llegar hasta aquí:

- Ruta del volumen con errata: `/var/lib/rabbitmq/mnseia/` → `mnesia`. Sin el fix los datos caían en la capa efímera del contenedor y se perdían al recrearlo.
- El secreto `rabbitmq_default_pass` **no existía** en producción: el unit no arrancaba.
- Usuario placeholder `usuario` → `admin`; añadidos `AutoUpdate=registry` y healthcheck (no tenía).
- **Hallazgo (patrón reutilizable)**: el healthcheck se ejecuta como **root** (la imagen hace `gosu rabbitmq`), y `rabbitmq-diagnostics` crea `/var/lib/rabbitmq/.erlang.cookie` como `root:root 400`. El servidor, ya como `rabbitmq`, falla con `Error when reading /var/lib/rabbitmq/.erlang.cookie: eacces` y entra en crash-loop. Fix: `User=rabbitmq` en `[Container]` + volumen con `:U`. Verificado con `Ping succeeded`.

Purga: `qctl purge --secrets --images`.

## Follow-ups
- `rabbitmq:3-management` es la rama **3.x (EOL)**: migrar a `3.13-management` o `4-management`. Ojo: el salto a 4 es **incompatible** con la mnesia previa (requiere volumen nuevo o migración explícita).
