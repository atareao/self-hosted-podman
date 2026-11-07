# pocketid — Servidor de autenticación PocketID

## Qué es
PocketID, basado en la imagen `ghcr.io/pocket-id/pocket-id:v2`. Número de contenedores: 1 (pocketid). Red(es): `proxy.network`. Dominio(s): `auth.${FQDN}` subdominio (label `traefik.http.routers.pocketid.rule`). Puerto interno: 1411 (label `traefik.http.services.pocketid.loadbalancer.server.port`).

## Ficheros
- Quadlet(s):
  - `/data/self-hosted-podman/pocketid.container`
- Volumen(es):
  - `/data/self-hosted-podman/pocketid-data.volume`
- Config no secreta: (no dispone de .env)
- Secretos:
  - pocketid_encryption_key

## Cómo funciona
Utiliza la red `proxy.network` para la exposición a Traefik. El volumen persiste la base de datos de la aplicación. La variable de entorno `APP_URL` apunta a `https://auth.${FQDN}` y `ENCRYPTION_KEY_FILE` a `/run/secrets/pocketid_encryption_key`. Se ejecuta como usuario 1000/1000 con permisos necesarios. Traefik enruta el tráfico a través del puerto interno 1411.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| APP_URL | Environment | `https://auth.${FQDN}` | URL de la aplicación |
| ENCRYPTION_KEY_FILE | Environment | `/run/secrets/pocketid_encryption_key` | Ruta al secreto de cifrado |
| TRUST_PROXY | Environment | `false` | Desactiva proxy de confianza |
| PUID | Environment | `1000` | UID del usuario de la aplicación |
| PGID | Environment | `1000` | GID del usuario de la aplicación |

## Cómo habilitar / desplegar
1. Secretos (solo si existen):
   ```bash
   printf '%s' '<valor>' | podman secret create pocketid_encryption_key -
   ```
2. `cd .config/containers/available/pocketid && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
