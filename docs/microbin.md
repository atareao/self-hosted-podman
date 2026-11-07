# microbin — Servicio de pastebin minimalista

## Qué es
- **Aplicación:** microbin
- **Imagen:** docker.io/danielszabo99/microbin:latest
- **Consola contenedores:** 1
- **Redes:** proxy.network
- **Dominio:** `microbin.${FQDN}` (subdominio)
- **Puerto interno:** 8080 (traefik.http.services.microbin.loadbalancer.server.port)

## Ficheros
- **Quadlet(s):** .config/containers/available/microbin/microbin.container
- **Volumen(es):** .config/containers/available/microbin/microbin-microbin.volume
- **Config no secreta:** .config/microbin/microbin.env
- **Secretos:** microbin_basic_auth_password, microbin_admin_password

## Cómo funciona
- **Red proxy.network**: conecta con Traefik
- **Volúmenes**: microbin.data persistente
- **Secretos**: `MICROBIN_BASIC_AUTH_PASSWORD`, `MICROBIN_ADMIN_PASSWORD`
- **EnvironmentFile**: carga variables públicas desde `.config/microbin/microbin.env` y `.config/microbin/microbin.env.local`
- **Healthcheck**: no definido
- **Traefik**: enruta HTTP/HTTPS a puerto 8080 con reglas de host y middlewares
- **User**: no especificado (se ejecuta como root por defecto, pero no se fuerza en el quadlet)

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| MICROBIN_EDITABLE | EnvironmentFile | true | Permite editar contenidos
| MICROBIN_HIDE_FOOTER | EnvironmentFile | false | Oculta pie de página
| MICROBIN_HIDE_HEADER | EnvironmentFile | false | Oculta encabezado
| MICROBIN_HIGHLIGHTSYNTAX | EnvironmentFile | true | Resaltado de sintaxis
| MICROBIN_BIND | EnvironmentFile | 0.0.0.0 | Bind IP
| MICROBIN_PRIVATE | EnvironmentFile | true | Servicio privado
| MICROBIN_JSON_DB | EnvironmentFile | false | BBDD en JSON
| MICROBIN_PUBLIC_PATH | EnvironmentFile | "https://microbin.${FQDN}/" | Ruta pública
| MICROBIN_READONLY | EnvironmentFile | true | Solo lectura
| MICROBIN_SHOW_READ_STATS | EnvironmentFile | true | Muestra estadísticas de lectura
| MICROBIN_TITLE | EnvironmentFile | PasteBin | Título del sitio
| MICROBIN_THREADS | EnvironmentFile | 1 | Hilos de ejecución
| MICROBIN_GC_DAYS | EnvironmentFile | 90 | Días de recolección de basura
| MICROBIN_ENABLE_BURN_AFTER | EnvironmentFile | true | Permite destruir después de leer
| MICROBIN_DEFAULT_BURN_AFTER | EnvironmentFile | 0 | Valor por defecto del burn after
| MICROBIN_WIDE | EnvironmentFile | false | UI ancha
| MICROBIN_QR | EnvironmentFile | true | Muestra QR
| MICROBIN_ETERNAL_PASTA | EnvironmentFile | true | Pastas eternas
| MICROBIN_ENABLE_READONLY | EnvironmentFile | true | Sólo lectura
| MICROBIN_DEFAULT_EXPIRY | EnvironmentFile | never | Expiración por defecto
| MICROBIN_NO_FILE_UPLOAD | EnvironmentFile | false | Permitir subir archivos
| MICROBIN_HASH_IDS | EnvironmentFile | false | Hash ID
| MICROBIN_ENCRYPTION_CLIENT_SIDE | EnvironmentFile | true | Encriptación cliente
| MICROBIN_ENCRYPTION_SERVER_SIDE | EnvironmentFile | true | Encriptación servidor
| MICROBIN_MAX_FILE_SIZE_ENCRYPTED_MB | EnvironmentFile | 256 | Tamaño máximo de archivo cifrado MB
| MICROBIN_MAX_FILE_SIZE_UNENCRYPTED_MB | EnvironmentFile | 2048 | Tamaño máximo de archivo sin cifrar MB
| MICROBIN_BASIC_AUTH_USERNAME | .config/microbin/microbin.env | admin | Usuario de Basic Auth
| MICROBIN_ADMIN_USERNAME | .config/microbin/microbin.env | admin | Usuario admin

## Cómo habilitar / desplegar
1. Secretos (solo si existen; NUNCA crypta store): `printf '%s' '<valor>' | podman secret create microbin_basic_auth_password -`
2. `cd .config/containers/available/microbin && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups
- (ninguno)
