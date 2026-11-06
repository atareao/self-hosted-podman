# PLAN — Import de stacks compose → quadlets (lote piloto)

## Objetivo

Migrar stacks de `docker-compose` del repo origen `/data/dockers/self-hosted` (remote `atareao/self-hosted`, ~122 stacks)
a quadlets Podman rootless en este repo (`/data/self-hosted-podman`), siguiendo el **Canonical quadlet skeleton** de `AGENTS.md`.

## Alcance de esta tanda (piloto)

4 stacks que cubren los patrones distintos del origen:

| Stack | Patrón que cubre |
|-------|------------------|
| `dozzle` | single-service, socket podman, credenciales (usuario/pass) |
| `freshrss` | single-service con bind-mounts de datos + env de config |
| `beszel` | multi-servicio, red interna, volumen compartido, tokens secretos, socket |
| `gitea` | multi-servicio con BD Postgres, red interna, puerto publicado (SSH) |

Los 9 stacks ya migrados (traefik, crowdsec, umami, openobserve, vector, nginx, pocketid, wordpress, dockge) **no se tocan**.

## Reglas de normalización (origen → destino)

- `image`→`Image`, `container_name`→`ContainerName`, `init:true`→`PodmanArgs=--init`, `command`→`Exec`, `ports`→`PublishPort`.
- `AutoUpdate=registry` para imágenes con tag flotante (`:latest`); no para tags pinneados (`gitea:1.19`, `postgres:14`).
- **Redes**: `proxy` externa → `proxy.network` (ya existe en el stack traefik). Red interna → nuevo `<stack>.network`.
- **Volúmenes**: named volume → `<nombre>.volume` (fichero quadlet `[Volume]`). Bind relativo `./x` → `%h/.config/<stack>/x:Z`.
  `/var/run/docker.sock` → `%t/podman/podman.sock:/var/run/docker.sock:ro`. Bind del host absoluto → igual, con `:ro`.
- **Secrets**: credenciales/tokens/keys → `Secret=<nombre>,type=env,target=<VAR>` (crypta). Config no secreta (TZ, dominios, puertos, paths, flags) → `Environment=`.
- **Traefik**: se adopta el patrón YA establecido en el repo (single-router seguro), descartando el del origen (web + middleware redirect):
  ```
  Label=traefik.enable=true
  Label=traefik.http.services.<name>.loadbalancer.server.port=<port>
  Label=traefik.http.routers.<name>.rule=Host(`<stack>.{{ env.FQDN }}`)
  Label=traefik.http.routers.<name>.entrypoints=websecure
  Label=traefik.http.routers.<name>.tls.certresolver=letsencrypt
  Label=traefik.http.routers.<name>.middlewares=seguridadHeaders@file,compresionHeaders@file
  ```
  El entrypoint `web` de traefik ya redirige a `websecure` globalmente, así que el redirect por-router es redundante.
- **Dominio**: `{{ env.FQDN }}` para el servicio principal; `<stack>.{{ env.FQDN }}` para subdominios (igual que openobserve/nginx/pocketid). Se descarta el FQDN por-stack del `sample.env` del origen.
- **Secciones `[Container]`**: las 11 fijas del skeleton, en orden, presentes aunque vacías (cabecera `# ==== Name ====`).
- **`[Install]`**: `WantedBy=default.target`. **`{% raw %}`** solo en ficheros `.jinja`.
- Fichero `.container.jinja` si contiene variables `{{ env.* }}`; si no, `.container`.

## Tareas

1. [x] Reconocimiento del origen y elección del lote piloto.
2. [ ] Crear los ficheros quadlet de `dozzle`, `freshrss`, `beszel`, `gitea`.
3. [ ] Validar los 4 stacks con `/usr/lib/podman/quadlet -user -dryrun` (0 errores/warnings).
4. [ ] Documentar en `AGENTS.md` el mapa global de normalización (redes/binds/dominios/traefik) y renombrar `PLAN.md`→histórico.
5. [ ] Revisión del patrón por el usuario y planificación de las siguientes tandas (~109 stacks restantes).

## Hallazgos / follow-ups

- **`FQDN` NO está en `~/.secrets/secrets.yml`** (`unjinja` exporta las claves en mayúsculas). Las plantillas actuales `{{ env.FQDN }}` no renderizarían el dominio hasta añadir esa clave. Acción: añadir `fqdn:` a `secrets.yml`.
- **Secrets a crear con crypta** antes de arrancar los stacks: `dozzle_username`, `dozzle_password`, `beszel_key`, `beszel_token`, `gitea_db_password`.
- **Gitea SSH**: el origen usa un entrypoint TCP traefik `git` que NO existe en `traefik.yml` (solo `web`/`websecure`). Se resuelve publicando `PublishPort=2222:22`; si se quiere enrutar SSH por traefik, habría que añadir el entrypoint `git` (afecta al stack existente traefik → fuera del alcance del piloto).
- **`openobserve` y `vector`** siguen con credenciales en `{{ env.* }}` (pendiente de migrar a `Secret=`).

## Validación

- Render `.jinja` (quitar `{% raw %}`/`{% endraw %}`, sustituir `{{ env.* }}` por dummy), copiar units + redes compartidas a un dir temporal y ejecutar `QUADLET_UNIT_DIRS=<dir> /usr/lib/podman/quadlet -user -dryrun`.
- Debe generar todas las units (containers + networks + volumes) sin errores ni warnings.
