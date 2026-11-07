# mumble — Servidor de voz Mumble

## Qué es
- **Aplicación:** mumble
- **Imagen:** docker.io/mumblevoip/mumble-server
- **Consola contenedores:** 1
- **Redes:** proxy.network, mumble.network
- **Dominio:** `mumble.${FQDN}` (subdominio)
- **Puerto interno:** 64738 (traefik.http.services.mumble.loadbalancer.server.port not defined, se expone por PublishPort)

## Ficheros
- **Quadlet(s):**
  - .config/containers/available/mumble/mumble.container
- **Volumen(es):**
  - .config/containers/available/mumble/mumble-data.volume
  - .config/containers/available/mumble/mumble-certs.volume
- **Config no secreta:** .config/mumble/mumble.env
- **Secretos:** mumble_superuser_password

## Cómo funciona
- **Redes:** conecta a red proxy y a su red interna mumble
- **Volúmenes:** persiste datos y certificados
- **Secretos:** `MUMBLE_SUPERUSER_PASSWORD` inyectado
- **EnvironmentFile:** carga configuración pública de `.config/mumble/mumble.env` y local
- **Healthcheck:** (no definido)
- **Traefik:** se expone al puerto TCP/UDP 64738 sin configuración especial
- **User:** no especificado (ejecuta como root)

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| MUMBLE_VERBOSE | Environment | true | Verboso
| MUMBLE_CONFIG_WELCOME_TEXT | Environment | "Bienvenido" | Texto de bienvenida
| MUMBLE_CONFIG_OPUSTHRESHOLD | Environment | 0 | Umbral OPU
| MUMBLE_CONFIG_MESSAGEBURST | Environment | 1 | Burst de mensajes
| MUMBLE_CONFIG_MESSAGELIMIT | Environment | 1 | Límite mensajes
| MUMBLE_CONFIG_USERS | Environment | 10 | Nº max usuarios
| MUMBLE_CONFIG_BANDWIDTH | Environment | 512000 | Ancho de banda
| MUMBLE_CONFIG_SSLCERT | Environment | /certs/mumble.${FQDN}/cert.pem | Certificado SSL
| MUMBLE_CONFIG_SSLKEY | Environment | /certs/mumble.${FQDN}/key.pem | Clave SSL
| MUMBLE_SUPERUSER_PASSWORD | .config/mumble/mumble.env | (valor secreto) | Contraseña superusuario

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store): `printf '%s' '\u003cvalor\u003e' | podman secret create mumble_superuser_password -`
2. `cd .config/containers/available/mumble && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
