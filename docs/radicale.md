# radicale — Servidor CalDAV/CardDAV

## Qué es
- **App**: radicale
- **Imagen**: docker.io/atareao/radicale:v1.0
- **Nº contenedores**: 1 (radicale)
- **Red**: proxy.network
- **Dominio**: radicale.${FQDN} (subdominio "radicale")
- **Puerto interno**: 5232 (traefik http.services radicale loadbalancer.port)

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/radicale/radicale.container
- Volumen(es): ninguno (binds)
- Binds: `%h/.config/radicale/data` → `/app/data` y `%h/.config/radicale/.htpasswd-users` → `/app/.htpasswd-users` (deben pertenecer a uid/gid 1000)
- Config no secreta: ninguno
- Secretos: ninguno

## Cómo funciona
- **Red**: proxy.network
- **Volúmenes**: %h/.config/radicale/.htpasswd-users -> /app/.htpasswd-users; %h/.config/radicale/data -> /app/data
- **Secretos**: ninguno
- **Healthcheck**: ninguno
- **Routing Traefik**: Host(`radicale.${FQDN}`), puerto 5232 (servicio radicale)
- **User/UserNS/NoNewPrivileges**: el contenedor corre como usuario `radicale` (uid=gid=1000) definido en la imagen; los binds deben pertenecer a ese uid dentro del namespace

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| (ninguna) | | | |

## Cómo habilitar / desplegar

1. Provisionar los binds y el fichero de usuarios (obligatorio antes del primer arranque):

   ```bash
   mkdir -p ~/.config/radicale/data
   PW='<password>'
   podman unshare bash -c "htpasswd -m -b -c ~/.config/radicale/.htpasswd-users <usuario> '$PW' && chmod 600 ~/.config/radicale/.htpasswd-users"
   podman unshare chown -R 1000:1000 ~/.config/radicale
   ```

   - `-m` es imprescindible: la imagen sólo acepta hashes `apr1/md5` (con bcrypt devuelve 500
     `not a valid apr_md5_crypt hash`).
   - Todo se ejecuta bajo `podman unshare` porque los ficheros pasan a ser propiedad del uid mapeado
     (100999 en el host) y `runner` deja de poder escribirlos.

2. `cd .config/containers/available/radicale && qctl install`
3. `systemctl --user daemon-reload`
4. `systemctl --user start radicale.service`

## Follow-ups
- El router y el servicio de Traefik se llaman `radicale`, como el stack.
- La autenticación sólo admite `apr1/md5`; valorar migrar a una imagen con Radicale 3.x (bcrypt) o fijar `auth.type = htpasswd` con `htpasswd_encryption = bcrypt`.
- Añadir `HealthCmd` (p. ej. `wget -qO- http://127.0.0.1:5232/ || exit 1`) para que systemd detecte caídas reales.
- Verificado E2E el 2026-11-11 (PLAN-030, issue #25): 200 en `/`, 200 en `/.web/` con credenciales válidas.