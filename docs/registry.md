# registry — Registro de contenedores Docker privado

## Qué es
- **App**: registry (con UI)
- **Imagen**: docker.io/library/registry
- **Nº contenedores**: 2 (registry, registry-ui)
- **Red**: registry.network, proxy.network (para registry-ui)
- **Dominio**: tu.${FQDN} (subdominio "tu")
- **Puerto interno**: 80 (traefik http.services registryui loadbalancer.port)

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/registry/registry.container
  - /data/self-hosted-podman/.config/containers/available/registry/registry-ui.container
- Volumen(es):
  - /data/self-hosted-podman/.config/containers/available/registry/registry-data.volume
- Config no secreta: ninguno
- Secretos: ninguno

## Cómo funciona
- **Red**: registry.network (para registry), proxy.network (para registry-ui)
- **Volúmenes**: registry-data.volume -> /var/lib/registry; host config.yml → /etc/docker/registry/config.yml; htpasswd → /auth/htpasswd
- **Secretos**: ninguno
- **Healthcheck**: ninguno
- **Routing Traefik**: Host(`tu.${FQDN}`) con puerto 80
- **User/UserNS/NoNewPrivileges**: ninguno

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| REGISTRY_STORAGE_DELETE_ENABLED | Environment | true | habilita borrado de imágenes |

## Cómo habilitar / desplegar
1. `cd .config/containers/available/registry && qctl install`
2. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)