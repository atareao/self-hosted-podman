# mumble — Servidor de voz Mumble

## Qué es
- **Aplicación:** mumble
- **Imagen:** docker.io/mumblevoip/mumble-server
- **Consola contenedores:** 2 (`mumble` + `mumble-recorder`)
- **Redes:** proxy.network, mumble.network
- **Dominio:** `mumble.${FQDN}` (subdominio, sin labels Traefik: se publica el puerto 64738 directo)
- **Puerto interno:** 64738 (TCP/UDP, expuesto con `PublishPort`)

## Ficheros
- **Quadlet(s):**
  - .config/containers/available/mumble/mumble.container
  - .config/containers/available/mumble/mumble-recorder.container
- **Volumen(es):**
  - .config/containers/available/mumble/mumble-data.volume
- **Config no secreta:** .config/mumble/mumble.env (+ `mumble.env.local`, gitignored)
- **Secretos:** mumble_superuser_password

## Cómo funciona
- **Redes:** `mumble` se conecta a `proxy.network` y a su red interna `mumble` (`NetworkAlias=mumble`); `mumble-recorder` solo a `mumble.network` (`NetworkAlias=recorder`).
- **Volúmenes:** `mumble-data.volume` → `/data` (BD SQLite y config generada). Ya **no** se monta `/certs`: murmur autogenera su certificado autofirmado en `/data`.
- **Secretos:** `MUMBLE_SUPERUSER_PASSWORD` inyectado con `Secret=mumble_superuser_password,type=env,target=MUMBLE_SUPERUSER_PASSWORD`.
- **EnvironmentFile:** ambos contenedores cargan `.config/mumble/mumble.env` y después `.config/mumble/mumble.env.local`. En `mumble` se añadió en esta revisión (antes solo lo tenía el recorder).
- **Recorder:** `kaffetorsk/mumble-recorder` lee `SERVER` (host del servidor Mumble) del env file. Arranca después de `mumble.service` (`After=` + `Requires=`).
- **Healthcheck:** `mumble` comprueba que el proceso `mumble-server` existe (`grep -qx mumble-server /proc/[0-9]*/comm`); `mumble-recorder` comprueba el proceso `ffmpeg` (`grep -qx ffmpeg /proc/[0-9]*/comm`). Se usa `/proc/<pid>/comm` porque ninguna de las dos imágenes trae `procps`/`pgrep`.
- **Traefik:** sin labels; se expone el puerto TCP/UDP 64738 con `PublishPort`.
- **User:** no especificado (el entrypoint de la imagen hace `su-exec` a uid/gid 10000 por defecto dentro del contenedor).

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| MUMBLE_VERBOSE | Environment | true | Verboso |
| MUMBLE_CONFIG_WELCOME_TEXT | Environment | "Bienvenido" | Texto de bienvenida |
| MUMBLE_CONFIG_OPUSTHRESHOLD | Environment | 0 | Umbral OPU |
| MUMBLE_CONFIG_MESSAGEBURST | Environment | 1 | Burst de mensajes |
| MUMBLE_CONFIG_MESSAGELIMIT | Environment | 1 | Límite mensajes |
| MUMBLE_CONFIG_USERS | Environment | 10 | Nº max usuarios |
| MUMBLE_CONFIG_BANDWIDTH | Environment | 512000 | Ancho de banda |
| SERVER | .config/mumble/mumble.env | `mumble` | Host del servidor para el recorder (NetworkAlias dentro de `mumble.network`) |
| MUMBLE_SUPERUSER_PASSWORD | Secret `mumble_superuser_password` | (valor secreto) | Contraseña superusuario |

Notas:
- `MUMBLE_CONFIG_SSLCERT`/`MUMBLE_CONFIG_SSLKEY` se **eliminaron**: apuntaban a `/certs/mumble.${FQDN}/{cert,key}.pem` en un volumen vacío y rompían el TLS de murmur. Sin esas variables, murmur genera su certificado autofirmado en `/data`.
- La variable del recorder es `SERVER` (no `SERVER_IP`), que es lo que espera la imagen.
- El volumen `mumble-certs` se eliminó al dejar de usarse.

## Cómo habilitar / desplegar
1. Secreto (NUNCA `crypta store`): `printf '%s' '<valor>' | podman secret create mumble_superuser_password -`
2. Asegurar `~/.config/mumble/mumble.env.local`: el hook `post_pull` lo crea solo (recorre `$HOME/.config/*/*.env`), pero si se despliega sin ejecutar el hook hay que crearlo a mano (`touch ~/.config/mumble/mumble.env.local`), porque ambos units lo declaran como `EnvironmentFile=` y la unidad fallaría si no existe.
3. `cd .config/containers/available/mumble && qctl install`
4. `systemctl --user daemon-reload`
5. `systemctl --user start mumble mumble-recorder`

## Follow-ups
- **Exposición**: publica `64738/tcp` y `64738/udp` directamente con `PublishPort` (no vía Traefik), por ser un protocolo no HTTP. Ver los invariantes de enrutado en `docs/traefik.md`.
- **TLS**: al quitar `MUMBLE_CONFIG_SSL{CERT,KEY}` el servidor usa un certificado autofirmado generado por murmur (los clientes Mumble aceptan el fingerprint). Si se quiere certificado válido, la vía es ACME integrado (`ACME_DOMAIN`) o montar certs reales en `/data`.
- **RTMP**: `mumble-recorder` apunta a `rtmp://127.0.0.1:1935/live/{name}` (dentro de su propio contenedor), pero **no hay servidor RTMP** en el stack: el recorder no podrá publicar el stream. Pendiente añadir un receptor RTMP (p. ej. nginx-rtmp/mediamtx) o cambiar `FFMPEG_OUT` a fichero local.
- El healthcheck del recorder depende de que exista un proceso `ffmpeg`; si el recorder está conectado pero sin audio/grabación activa, el contenedor puede reportar `unhealthy` sin estar realmente roto.
- El recorder no tiene `ReadOnly` ni `User` y escribe en el directorio de trabajo del contenedor; sin volumen, las grabaciones no persisten.
