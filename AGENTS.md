# AGENTS.md

Dotfiles repository (`yadm`) for a rootless Podman + Traefik self-hosted stack. Not an application: no build, test, lint or typecheck. Everything here lands directly in `$HOME`.

## Install model

- Deployed with `yadm` (clone/pull into `$HOME`), **not** cloned to an arbitrary dir. Paths in the repo are relative to `$HOME`.
- `setup.sh` and `setup_apps.sh` are one-shot host bootstrap scripts (root: users/SSH/nftables; apps user: podman.socket, crypta, secret creation). They are **not** part of the dotfiles flow — do not run them to "install" the repo.
- After a `yadm pull`, the `.config/yadm/hooks/post_pull` hook runs `unjinja` automatically to regenerate templates.

## Quadlet layout (the special part)

- `.config/containers/available/<stack>/` is the **source of truth**. Each stack is a directory holding quadlet units: `*.container`, `*.volume`, `*.network`, `*.pod`, `*.kube` (some as `*.jinja` templates).
- `.config/containers/systemd/` is the **target dir** Podman/systemd actually reads. It only contains `.gitkeep`; files arrive as **symlinks** from `available/<stack>/`.
- `available/` is inert. A stack does nothing until its files are linked into `systemd/` and `systemctl --user daemon-reload` runs.
- Enabling/disabling is done with `qctl`, run from inside the stack dir: `cd .config/containers/available/<stack> && qctl install` / `qctl uninstall`; `qctl status` shows state. `qctl install` refuses to overwrite a real file or a symlink owned by another stack (collision guard).
- Files that contain template variables are `.jinja`; files without them are plain `.container`/`.volume`/... (e.g. `available/umami/umamidb.container`).

## Acceso a producción (usuario `runner`)

Este repo se despliega como dotfiles (yadm) en el home del **usuario de apps** del servidor de
producción `new_atareao`: **`runner`** (uid 1002; se llamaba `podman` antes del rename de
PLAN-008; en docs/planes antiguas puede aparecer como `apps`). Rootless podman, `systemctl --user`,
bus `/run/user/1002`. El usuario **no tiene sudo** y no se accede por SSH directo.

El SSH a `new_atareao` entra como **`lorenzo`** (uid 1001, grupo `sudo`, NOPASSWD a runner). Para
operar como `runner` se usa el wrapper **`rr`** — dos copias cooperantes:

- `~/bin/rr` en `lorenzo` (servidor): `sudo -n -u runner -H env XDG_RUNTIME_DIR=/run/user/1002 \
  PATH=/usr/local/bin:/usr/bin:%h/.local/bin SOPS_AGE_KEY_FILE=… bash -lc "cd && cmd"`.
- `~/bin/rr` en la máquina que inicia la sesión: envía el comando al remoto por **base64** (el
  login shell del servidor es fish; no confíes en quoting por SSH).

Si pasas un comando a `rr "<cmd>"` se ejecuta como runner con el entorno completo (systemd user
bus + crypta + `SOPS_AGE_KEY_FILE`). Cero argumentos → shell interactivo de runner.

Reglas invariantes:

- Operar el servidor **solo** como `runner` (vía `lorenzo` + `rr`), nunca como `lorenzo` directo
  para tocar el stack, y nunca SSH directo como `runner`.
- El hook `post_pull` de yadm requiere `unjinja` y el FQDN; se ejecuta en el `yadm pull` hecho
  como runner.
- Este repo trabaja directo en `main` (ver sección Git), no imposes gitflow/PR en él.

## qctl

- `qctl` (source at `/data/rust/qctl`) discovers quadlets **non-recursively** in `./quadlets/` or the current directory only.
- Run it **from inside a stack dir**, e.g. `cd .config/containers/available/traefik && qctl status`. Run from the repo root it finds nothing.
- It targets the same `~/.config/containers/systemd` symlink dir as `qctl install`.
- Binario en `~/.local/bin/qctl` del usuario de apps (estatico x86_64 + checksum, de la ultima release `atareao/qctl`).

## Quadlet validation

- The quadlet generator binary is `/usr/lib/podman/quadlet` (NOT `/usr/libexec/podman/quadlet`, which does not exist on this host even though the `qi` fish abbreviation references it).
- Validate a stack in isolation without touching `~/.config/containers/systemd`: render any `.jinja` (emulate `unjinja`: drop `{% raw %}`/`{% endraw %}` markers, substitute `{{ env.* }}`), copy the units plus any referenced shared networks (e.g. `traefik/proxy.network`) into a temp dir, then `QUADLET_UNIT_DIRS=<dir> /usr/lib/podman/quadlet -user -dryrun`. Missing shared networks show up as `unable to translate dependency for <net>.network`.

## Templating & secrets

- La configuración no secreta de cada stack se mantiene en el archivo `.config/<stack>/<stack>.env`. Este archivo está versionado y debe contener todas las variables de entorno públicas de la stack. Los overrides específicos de cada máquina se generan automáticamente en `.config/<stack>/<stack>.env.local`, que es ignorado por Git y creado por el hook `post_pull`. Los `.env.local` se cargan después del `.env` para sobreescribir valores cuando sea necesario, tal y como lo hace el sistema con `EnvironmentFile`. 
- En el quadlet, se inyecta la configuración con `EnvironmentFile=%h/.config/<stack>/<stack>.env`, y luego se añaden los `.env.local` con `EnvironmentFile=%h/.config/<stack>/<stack>.env.local`. Estas dos líneas deben estar en el orden descrito; la segunda anula la primera.
- Solo queda **un** archivo de plantilla `.jinja`: `.config/traefik/dynamic/dashboard-auth.yml.jinja`. `vector.yaml` se convirtió a fichero **plano**: usa la interpolación `${VAR}` nativa de Vector, con la config no secreta en `.config/vector/vector.env` y las credenciales por `Secret=`/`EnvironmentFile=` en el quadlet. Los demás `.container.jinja` ya son `.container`.
- `unjinja`/`yadmalt` read `$HOME/.secrets/secrets.yml` (SOPS + age, key at `~/.secrets/sops/age/key.txt`), export each key as an UPPERCASE env var, render, then unset them. `secrets.yml` es **solo para secretos** (y para la plantilla `.jinja` restante); la config no secreta de cada stack vive en su `.env` de stack (ver primer bullet). The host domain is **not** here.
- **Host domain (FQDN) is NOT a secret and does NOT live in SOPS.** It lives in `~/.config/environment.d/fqdn.conf` (plain text, `FQDN=<your-domain>`), which systemd injects into every user unit (verified). In quadlets write `${FQDN}` — systemd expands it in the generated `ExecStart`, including Traefik `Host(...)` labels. Files consumed at **runtime by an app** (not by systemd), e.g. `traefik/dynamic/dashboard-auth.yml.jinja`, cannot use `${FQDN}`; for those `unjinja` exports `FQDN` from `fqdn.conf` so `{{ env.FQDN }}` resolves host-specifically. `unjinja` also sets `SOPS_AGE_KEY_FILE` itself so it works from non-interactive shells (the `post_pull` hook).
- Deploy of the domain: the real `fqdn.conf` is **gitignored** (host-specific); `fqdn.conf.example` is versioned. After `cp fqdn.conf.example fqdn.conf` and editing it: `systemctl --user daemon-reexec` then `systemctl --user restart <stack>` (running units keep the old value until restarted).
- **Credentials go through Podman secrets, not `{{ env.* }}`**: use `Secret=<name>,type=env,target=<VAR>`. **⚠️ A FUEGO — el secreto se crea con `podman secret create`, NUNCA con `crypta store`** (p. ej. `openssl rand -base64 32 | podman secret create umamidb_password -`). Motivo: el driver `shell` de Podman resuelve los secretos por el **ID** del secreto, así que `podman secret create` hace que Podman genere el ID y le entregue el valor a `crypta`; `crypta store <name>` escribe una clave huérfana bajo el nombre literal que Podman nunca encuentra (`no secret with name or id`). El driver `crypta` está configurado en `containers.conf`. Un valor que deba componerse (p. ej. un `DATABASE_URL` completo) se guarda entero como un secreto y se inyecta con `type=env,target=DATABASE_URL`. **Única excepción**: `crypta store` SÍ se usa para la plantilla `.jinja` que renderiza `unjinja` (que lee `secrets.yml` directamente).
- Any `Secret=` name in a quadlet must be **created with `podman secret create`** before the unit starts (a fuego: never `crypta store`).

### Naming de units

- El **nombre del fichero del unit** debe ser único en TODO el repo: los units se enlazan a un directorio plano (`~/.config/containers/systemd/`). Igual para `ContainerName=` (Podman lo exige único global). `NetworkAlias=` NO es global (vive en su red) y no colisiona.
- Convención: el unit **principal** se llama como el directorio del stack (`<stack>.container`); los demás son apéndices `<stack>-<rol>.container` (p.ej. `miniflux`, `miniflux-postgresql`, `miniflux-redis`).
- Herramienta: `qctl check` detecta colisiones duras de basename/`ContainerName=` y avisa de units que no siguen la convención; `qctl install` aborta si detecta colisión de nombre global (pre-scan atómico: no enlaza nada si algún unit colisiona).

## Canonical quadlet skeleton

Every `.container`/`.container.jinja` MUST use the same `[Container]` sections, in the same order, even when a section is empty — an empty section keeps only its header. This is the mandatory target shape for `docker-compose.yml` migrations; do not invent new section names or reorder them. Header format is exactly `# ==== Name ====`.

Copy-paste template (all 11 sections always present):

```ini
[Unit]
Description=<desc>
After=<deps>
Requires=<deps>

[Container]
# ==== Image ====
Image=<image>
ContainerName=<name>
AutoUpdate=registry
PodmanArgs=--init

# ==== Command ====

# ==== Ports ====

# ==== Volumes ====

# ==== Networks ====

# ==== Secrets ====

# ==== Environment ====

# ==== Labels ====

# ==== Healthcheck ====

# ==== Hardening ====

# ==== Resources ====

[Service]
Environment=SOPS_AGE_KEY_FILE=%h/.secrets/sops/age/key.txt
Environment=PATH=/usr/local/bin:/usr/bin:%h/.local/bin
Restart=<always|on-failure>
RestartSec=10s
StartLimitIntervalSec=300
StartLimitBurst=3
TimeoutStartSec=<seconds>
{% raw %}   # only in .jinja files, NEVER in plain .container
ExecStartPost=/usr/bin/bash -c 'while [ "$(podman inspect --format "{{.State.Health.Status}}" <name>)" != "healthy" ]; do sleep 2; done'
{% endraw %}

[Install]
WantedBy=default.target
```

Sections and the keys that belong in each, in order:

1. `Image` — `Image`, `ContainerName`, `AutoUpdate`, `Notify`, `PodmanArgs`
2. `Command` — `Exec`
3. `Ports` — `PublishPort`
4. `Volumes` — `Volume`
5. `Networks` — `Network`, `NetworkAlias`, `AddHost`
6. `Secrets` — `Secret`
7. `Environment` — `Environment`
8. `Labels` — `Label` (Traefik labels)
9. `Healthcheck` — `HealthCmd`, `HealthInterval`, `HealthRetries`, `HealthTimeout`, `HealthStartPeriod`
10. `Hardening` — `ReadOnly`, `NoNewPrivileges`, `SecurityLabelDisable`, `AddCapability`, `User`, `Group`
11. `Resources` — `Memory`, `PidsLimit`

Parser acceptance (verified against `/usr/lib/podman/quadlet` 6.1.4 on this host):

- Accepted in `[Container]`: `Image`, `ContainerName`, `AutoUpdate`, `Notify`, `PodmanArgs`, `Exec`, `PublishPort`, `Volume`, `Network`, `NetworkAlias`, `AddHost`, `Secret`, `Environment`, `Label`, `HealthCmd`, `HealthInterval`, `HealthRetries`, `HealthTimeout`, `HealthStartPeriod`, `ReadOnly`, `NoNewPrivileges`, `SecurityLabelDisable`, `AddCapability`, `User`, `Group`, `Memory`, `PidsLimit`.
- REJECTED in `[Container]`: `CPUShares` (generator error `unsupported key`), `MemoryLimit` (systemd-only). For limits not expressible in `[Container]`, use `CPUWeight` / `MemoryLimit` (or `MemoryMax`) in `[Service]`.
- systemd-only, keep in `[Service]`: `Sockets`, `CPUWeight`, `MemoryLimit`/`MemoryMax`, `ExecStartPre`, `ExecStartPost`.

Composition rules:

- The eleven `[Container]` sections are fixed; `[Unit]` (`Description`, then `After`, then `Requires`) and `[Service]`/`[Install]` follow the fixed shapes above.
- Rootless units MUST use `WantedBy=default.target` (never `multi-user.target` — it is not pulled in by the user manager, so the container would not autostart).
- `{% raw %}`/`{% endraw %}` around a shell `{{ ... }}` ONLY in `.jinja` files; a plain `.container` must carry the literal `{{.State.Health.Status}}` unescaped (adding the markers there is a systemd syntax error).
- File naming: a unit is `.jinja` iff it contains any **template** variable (`{{ env.* }}` other than FQDN); otherwise plain (e.g. `available/umami/umamidb.container`). `${FQDN}` is NOT a template variable — it is expanded by systemd at runtime, so a unit using only `${FQDN}` is a plain `.container`.
- `docker-compose.yml` mapping: `image`→`Image`, `container_name`→`ContainerName`, `command`→`Exec`, `init: true`→`PodmanArgs=--init`, `ports`→`PublishPort`, `volumes`→`Volume`, `networks`→`Network`, `secrets`→`Secret`, `environment`→`Environment`, `labels`→`Label`, `healthcheck`→`Health*`, `cap_add`→`AddCapability`, `read_only`→`ReadOnly`, `user`→`User`, `deploy.resources.limits`→`Memory`/`PidsLimit`, `restart`→`Restart=` (systemd values only — NEVER `unless-stopped`).
- Credenciales migradas: `openobserve` inyecta su password con `Secret=openobserve_root_password,type=env,target=ZO_ROOT_USER_PASSWORD`. `vector` usa `vector.yaml` **plano** con interpolación `${VAR}` nativa: la config no secreta (`OO_USER_EMAIL`) va por `EnvironmentFile=%h/.config/vector/vector.env` y `OO_USER_PASSWORD` **reutiliza el mismo** `Secret=openobserve_root_password` (garantiza que el login coincide). `VECTOR_INGEST_PASSWORD` queda como `Secret=` pendiente (CrowdSec aún sin ingest).

## Import: docker-compose → quadlet

Rules applied when migrating a stack from the compose origin repo (`atareao/self-hosted`) to quadlets here. Merge the base `docker-compose.yml` with the `.traefik.yml` overlay (ignore `.caddy.yml`).

- **Networks**: external `proxy` → `proxy.network` (already in the traefik stack). A compose-internal network → a new `<stack>.network` unit in the stack dir.
- **Volumes**: named volume → `<name>.volume` unit. Relative bind `./x` → `%h/.config/<stack>/x` (append `:Z`). `/var/run/docker.sock` → `%t/podman/podman.sock:/var/run/docker.sock:ro`. Keep host absolute binds as-is.
- **Secrets vs config**: credentials/tokens/keys/passwords → `Secret=<name>,type=env,target=<VAR>` (crypta). Non-secret config (TZ, domains, ports, paths, feature flags) → `Environment=`.
- **Traefik labels**: normalize the origin's `web` + `https-redirect` middleware + `-secure` router into the single secure router used repo-wide:
  ```
  Label=traefik.enable=true
  Label=traefik.http.services.<name>.loadbalancer.server.port=<port>
  Label=traefik.http.routers.<name>.rule=Host(`<stack>.${FQDN}`)
  Label=traefik.http.routers.<name>.entrypoints=websecure
  Label=traefik.http.routers.<name>.tls.certresolver=letsencrypt
  Label=traefik.http.routers.<name>.middlewares=seguridadHeaders@file,compresionHeaders@file
  ```
  The `web` entrypoint already redirects to `websecure` globally (static `traefik.yml`), so per-router redirect middlewares are dropped.
- **Domain**: `${FQDN}` for the main service; `<stack>.${FQDN}` for subdomains (as openobserve/nginx/pocketid). Drop the origin's per-stack `FQDN` from `sample.env`.
- **HTTP ports**: compose `ports:` for HTTP services behind traefik disappear (traefik reaches the container port via the service label). Only publish ports that must be reachable directly (e.g. gitea SSH).
- **Drop**: `version:`, `x-dockge`, `depends_on` (replaced by `After=`/`Requires=`), `restart: unless-stopped` → `Restart=always`/`on-failure`.
- **Podman secrets**: any `Secret=` name must be created with **`podman secret create <name> -`** before the unit starts (a fuego: NEVER `crypta store`, Podman cannot resolve it); list them per stack.

## Other gotchas

- `.config/systemd/user/http.socket` / `https.socket` provide rootless socket-activated ports 80/443 for Traefik.
- `proxy.network` (Traefik edge network) lives in the `traefik` stack; other stacks join it via `Network=proxy.network`.
- `qctl install` only links rendered units: run `unjinja` first so `*.jinja` exist as `.container`/`.volume`/`.network` before enabling a stack.

## Git

- This repo works **directly on `main`** with conventional gitmoji commits. Do not impose gitflow feature branches / PR flow here (that rule is for other projects).
- Remote: `git@github.com:atareao/self-hosted-podman.git`.

## Verification (no test suite)

- `systemctl --user daemon-reload` then `qctl status` from a stack dir to confirm link + run state.
- Logs: `journalctl --user -u <unit>`; helpers `jcu <unit>` (once) and `jcf <unit>` (follow), both piped through `ansifilter` + `batcat`.

## Plans y documentación

Organización de planes y documentación de features (obligatorio):

- **`plans/`** — todos los planes del proyecto, numerados secuencialmente: `PLAN-001.md`, `PLAN-002.md`, … Cada plan nuevo toma el siguiente número libre. Cuando un plan se completa o archiva **no se borra**: se renombra a `plans/PLAN-<NNN>-ARCHIVED.md`.
  - El siguiente número libre es el menor entero positivo no usado en `plans/` (se ignora el sufijo `-ARCHIVED`).
- **`docs/`** — documentación de cada feature/stack creada, un fichero por feature: `docs/<feature>.md`. Debe cubrir: qué es, ficheros implicados, cómo funciona, variables/config, cómo habilitar y desplegar, decisiones de migración (compose→quadlet) y follow-ups.
- **Flujo al crear una feature/stack:**
  1. Crear `plans/PLAN-<NNN>.md` (siguiente número libre).
  2. Implementar y validar.
  3. Crear `docs/<feature>.md`.
  4. Al cerrar: marcar las tareas del plan y renombrarlo a `plans/PLAN-<NNN>-ARCHIVED.md`.
