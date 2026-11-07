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
- Volumen(es): /data/self-hosted-podman/.config/containers/available/rabbitmq/rabbitmq-rabbitmq.volume
- Config no secreta: ninguno
- Secretos: rabbitmq_default_pass

## Cómo funciona
- **Red**: proxy.network
- **Volúmenes**: rabbitmq-rabbitmq.volume -> /var/lib/rabbitmq/mnseia/
- **Secretos**: rabbitmq_default_pass (RABBITMQ_DEFAULT_PASS)
- **Healthcheck**: ninguno
- **Routing Traefik**: Host(`mq.${FQDN}`), puerto 15672
- **User/UserNS/NoNewPrivileges**: ninguno

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| RABBITMQ_DEFAULT_USER | Environment | usuario | usuario de rabbitmq |

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store): `printf '%s' '<valor>' | podman secret create rabbitmq_default_pass -`
2. `cd .config/containers/available/rabbitmq && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)