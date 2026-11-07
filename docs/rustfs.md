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