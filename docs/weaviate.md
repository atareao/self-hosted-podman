# weaviate — Motor de búsqueda semántica vectorial

## Qué es
Aplicación: Weaviate
Imagen: docker.io/semitechnologies/weaviate:1.23.0
Número de contenedores: 1
Red: ninguna
Dominio: ninguno
Puerto interno: 8080, 50051

## Ficheros
- Quadlet(s): `/data/self-hosted-podman/.config/containers/available/weaviate/weaviate.container`
- Volumen(es): `/data/self-hosted-podman/.config/containers/available/weaviate/weaviate-data.volume`
- Config no secreta: ninguno
- Secretos: ninguno

## Cómo funciona
El contenedor se ejecuta sin red pública y expone los puertos 8080 y 50051 localmente. Se persisten los datos en el volumen `weaviate-data`. Traefik no se aplica, ya que el servicio no está expuesto públicamente en este stack.

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

## Follow-ups
- (ninguno)
