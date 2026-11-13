# weaviate — Motor de búsqueda semántica vectorial

## Qué es
Aplicación: Weaviate
Imagen: docker.io/semitechnologies/weaviate:1.23.0
Número de contenedores: 1
Red: weaviate.network (interna, con `NetworkAlias=weaviate`)
Dominio: ninguno (sin router, por diseño)
Puerto interno: 8080 (HTTP), 50051 (gRPC) — no publicados en el host

## Ficheros
- Quadlet(s): `/data/self-hosted-podman/.config/containers/available/weaviate/weaviate.container`
- Red: `/data/self-hosted-podman/.config/containers/available/weaviate/weaviate.network`
- Volumen(es): `/data/self-hosted-podman/.config/containers/available/weaviate/weaviate-data.volume`
- Config no secreta: ninguno
- Secretos: ninguno

## Cómo funciona
El contenedor vive en su propia red `weaviate.network`, sin `PublishPort`: solo es alcanzable por otros contenedores a través del alias `weaviate`. Se persisten los datos en el volumen `weaviate-data`. Traefik no se aplica: el stack no se expone públicamente y **no hay autenticación**, así que publicar los puertos en el host dejaba la API abierta a cualquiera.

- **Healthcheck**: `wget -q -O /dev/null http://127.0.0.1:8080/v1/.well-known/ready` (30 s / 5 reintentos / timeout 5 s / `HealthStartPeriod=20s`).
- **gRPC (50051)**: no es HTTP; no se valida con `curl` ni se puede enrutar por Traefik sin h2c.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| QUERY_DEFAULTS_LIMIT | `Environment=` | 25 | Límite de resultados por defecto |
| AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED | `Environment=` | true | Habilitar acceso anónimo |
| PERSISTENCE_DATA_PATH | `Environment=` | /var/lib/weaviate | Directorio de almacenamiento |
| DEFAULT_VECTORIZER_MODULE | `Environment=` | none | Módulo vectorizador por defecto |
| ENABLE_MODULES | `Environment=` | text2vec-cohere,text2vec-huggingface,text2vec-palm,text2vec-openai,generative-openai,generative-cohere,generative-palm,ref2vec-centroid,reranker-cohere,qna-openai | Módulos habilitados |
| CLUSTER_HOSTNAME | `Environment=` | node1 | Nombre del nodo |

## Cómo habilitar / desplegar
1. `cd .config/containers/available/weaviate && qctl install`
2. `systemctl --user daemon-reload`

## Verificación E2E (2026-11-13)

Verificado en producción (`new_atareao`, usuario `runner`) y después purgado. Es un stack
**interno, sin Traefik** (excepción), así que la comprobación se hizo por dentro del contenedor:

1. Unit `weaviate` → `active`.
2. Contenedor `weaviate` → `Up (healthy)`.
3. Router Traefik: **no aplica** (sin labels, por diseño).
4. Certificado: **no aplica** (no expuesto).
5. `wget http://127.0.0.1:8080/v1/.well-known/ready` → OK; gRPC `SERVING` con
   `podman exec weaviate /bin/grpc_health_probe -addr=127.0.0.1:50051`.

Bugs latentes corregidos para llegar hasta aquí:

- Publicaba `8080:8080` y `50051:50051` en `0.0.0.0` **sin autenticación** → API abierta. Ahora sin `PublishPort`, con red propia `weaviate.network` y `NetworkAlias=weaviate` (esto además evita la colisión del puerto 8080 con `open-webui`).
- No tenía healthcheck.

Purga: `qctl purge --images` (sin secretos).

## Follow-ups
- `AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED=true`: no hay auth. Aceptable mientras solo sea alcanzable desde `weaviate.network`, pero conviene activar API key/OIDC si se expone.
- Versión `1.23.0` (enero 2024) y Docker Hub ya no publica versiones recientes: migrar la imagen a `cr.weaviate.io/semitechnologies/weaviate` al actualizar.
