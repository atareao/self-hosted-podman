# kavita — Lector de cómics y libros

## Qué es
Servidor de lectura Kavita para cómics y libros.
- Imagen principal: docker.io/jvmilazz0/kavita
- Número de contenedores: 1
- Red(es) usadas: proxy.network
- Dominio(s): kavita.${FQDN}
- Puerto interno: 5000

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/kavita/kavita.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/kavita/kavita-books.volume, /data/self-hosted-podman/.config/containers/available/kavita/kavita-data.volume
- Config no secreta: N/A
- Secretos: N/A

## Cómo funciona
Conecta a proxy.network, monta volúmenes kavita-books y kavita-data, healthcheck none, enrutamiento Traefik con TLS, TZ configurado a Europe/Madrid.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| TZ | Environment= | Europe/Madrid | Zona horaria |

## Cómo habilitar / desplegar
1. Secretos (si existen; NUNCA crypta store): Ninguno
2. `cd .config/containers/available/kavita && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (PLAN-013, issue #7): desplegado, verificado
end-to-end (router Traefik + cert LE + HTTP OK) y **purgado ese mismo día** (units desenlazados,
volúmenes/binds e imágenes eliminados). Estado actual: **no desplegado**.