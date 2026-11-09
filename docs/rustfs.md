# rustfs — Sistema de archivos basado en Rust

## Qué es
- **App**: rustfs
- **Imagen**: docker.io/rustfs/rustfs
- **Nº contenedores**: 1 (rustfs)
- **Red**: proxy.network
- **Dominio**: rustfs.${FQDN} (subdominio "rustfs")
- **Puerto interno**: 9001 (traefik http.services rustfs-console loadbalancer.port) y 9000 para /health

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/rustfs/rustfs.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/rustfs/rustfs-data.volume
- Config no secreta: ninguno
- Secretos: rustfs_access_key, rustfs_secret_key

## Cómo funciona
- **Red**: proxy.network
- **Volúmenes**: rustfs-data.volume -> /data
- **Secretos**: rustfs_access_key, rustfs_secret_key
- **Healthcheck**: sh -c curl -f http://localhost:9000/health && curl -f http://localhost:9001/rustfs/console/health
- **Routing Traefik**: Host(`rustfs.${FQDN}`), puertos 9000 (health) y 9001 (console)
- **User/UserNS/NoNewPrivileges**: ninguno

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| RUSTFS_CONSOLE_ENABLE | Environment | true | habilita consola |

## Cómo habilitar / desplegar
1. Secretos:
   - `printf '%s' '\u003cvalor\u003e' | podman secret create rustfs_access_key -`
   - `printf '%s' '\u003cvalor\u003e' | podman secret create rustfs_secret_key -`
2. `cd .config/containers/available/rustfs && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-019, issue #14): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP 200) y **purgado ese mismo día**. Estado actual: **no desplegado**.

**Bugs / notas**:
- El `HealthCmd` en forma CMD-SHELL (`curl ... && curl ... || exit 1`) fallaba con **exit 125** en conmon
  (el healthcheck no se ejecutaba), dejando el contenedor `unhealthy` y haciendo que Traefik dejara de
  enrutarlo (404). Se corrigió usando la **forma exec** (array JSON):
  `HealthCmd=["/usr/bin/curl","-f","http://127.0.0.1:9000/health"]`.
- El **console** se sirve bajo `/rustfs/console` (el root `/` devuelve 403 — API S3). La URL correcta es
  `https://rustfs.${FQDN}/rustfs/console`. El base path del console es de compilación
  (`RUSTFS_CONSOLE_BASE_PATH`), no configurable en runtime.
- Requiere los secretos `rustfs_access_key` y `rustfs_secret_key` (crear con `podman secret create`).