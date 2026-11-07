# 🐋 Self-Hosted Podman Infrastructure

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Podman](https://img.shields.io/badge/Podman-892CA0?style=flat&logo=podman&logoColor=white)](https://podman.io/)
[![Traefik](https://img.shields.io/badge/Traefik-24A1C1?style=flat&logo=traefikproxy&logoColor=white)](https://traefik.io/)
[![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black)](https://www.linux.org/)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat&logo=github&logoColor=white)](https://github.com/atareao/self-hosted-podman)

> **Infraestructura completa de auto-alojamiento con Podman rootless: quadlets, secretos cifrados y configuración declarativa.**

Conjunto de **dotfiles** (gestionados con [yadm](https://yadm.io/)) que despliegan servicios auto-alojados sobre **Podman rootless**, con proxy reverso [Traefik](https://traefik.io/), autenticación OIDC con PocketID, secretos cifrados con SOPS+age y configuración declarativa mediante **quadlets**.

Este repositorio es la **única fuente de verdad**. En el servidor **no se edita nada a mano**: solo se hace `yadm pull` y el hook de despliegue se encarga del resto.

---

## 🧭 Cómo funciona (arquitectura)

```
    DEV (este repo)                     PROD (usuario runner · antes podman)
 ┌───────────────────┐   git push    ┌──────────────────────────────┐
 │  dotfiles + units │ ────────────► │  yadm pull  ──► post_pull    │
 │  (quadlets, .env) │               │   ├─ unjinja (secretos+FQDN) │
 └───────────────────┘               │   ├─ scaffold *.env.local    │
                                     │   └─ systemctl --user        │
                                     │        daemon-reload         │
                                     └──────────────────────────────┘
```

### Quadlets: `available/` es la fuente de verdad

- `.config/containers/available/<stack>/` contiene las unidades (`*.container`, `*.volume`, `*.network`, `*.pod`, `*.kube`) de cada stack. **Es inerte**: nada arranca hasta enlazarlo.
- `.config/containers/systemd/` es el **directorio destino** que systemd/Podman leen de verdad. Solo contiene `.gitkeep`; los ficheros llegan como **symlinks** desde `available/<stack>/`.
- Habilitar/deshabilitar se hace con **`qctl`**, desde el directorio del stack (`cd .config/containers/available/<stack> && qctl install` / `qctl uninstall`), nunca copiando ficheros a mano.
- Todo es **rootless** (`systemctl --user`). Los servicios usan `WantedBy=default.target`.

### Convención de nombres de unidad

El directorio destino es **plano**, así que el **basename de cada unidad debe ser único en TODO el repositorio** (igual que `ContainerName=` en Podman). Convención:

| Unidad                 | Nombre                              |
| ---------------------- | ----------------------------------- |
| **Principal** del stack | `<stack>.container` (p. ej. `miniflux`) |
| **Apéndices**           | `<stack>-<rol>.container` (`miniflux-postgresql`, `miniflux-redis`, `mumble-recorder`) |

- `NetworkAlias=` **no** es global (vive dentro de su red) y **no** debe cambiarse a la ligera: es el host por el que las apps conectan a sus bases de datos.
- Guardas: **`qctl check`** detecta colisiones duras (basename y `ContainerName`) y `qctl install` hace un *pre-scan atómico* (si algún unidad colisiona, no enlaza ninguna).

### Configuración: `.env` versionado + `.env.local` por máquina

- `.config/<stack>/<stack>.env` — configuración **no secreta** del stack (TZ, puertos, rutas, flags, emails). **Versionado**.
- `.config/<stack>/<stack>.env.local` — *overrides* específicos de la máquina. **Gitignored**; lo crea (vacío) el hook `post_pull` si falta.
- En el quadlet se inyectan **en este orden**, con ruta **absoluta** (la relativa se resolvería contra `systemd/`):

  ```ini
  EnvironmentFile=%h/.config/<stack>/<stack>.env
  EnvironmentFile=%h/.config/<stack>/<stack>.env.local
  ```

### Secretos y FQDN

- **Credenciales** (passwords, tokens, claves) → **nunca** en `.env`. Van por [crypta](https://github.com/atareao/crypta) y se inyectan como `Secret=`:

  ```ini
  Secret=<nombre>,type=env,target=<VAR>
  ```

- El **FQDN no es un secreto** y **no** vive en SOPS: está en `~/.config/environment.d/fqdn.conf` (`FQDN=tu.dominio`), que systemd inyecta en cada unidad de usuario. En los quadlets se escribe `${FQDN}` (systemd lo expande, incluso en las labels de Traefik).

### Plantillas (`*.jinja`)

Solo queda **una** plantilla, y es un fichero que consume una **app en tiempo de ejecución** (no systemd):

- `.config/traefik/dynamic/dashboard-auth.yml.jinja`

La renderiza **`unjinja`** (exporta los secretos de SOPS como variables `UPPERCASE` + el `FQDN`, renderiza con [jinrender](https://github.com/atareao/jinrender) y limpia las variables). El resto de config va por `.env` y quadlets normales.

> **`vector.yaml` ya NO es plantilla.** Es un fichero **plano** versionado que usa la interpolación `${VAR}` **nativa de Vector**. La config no secreta (`OO_USER_EMAIL`) vive en `.config/vector/vector.env` (inyectado con `EnvironmentFile=`) y las credenciales llegan por `Secret=`. O sea: no necesita Jinja en absoluto.

---

## 🚀 Características

- ✅ **Contenedores rootless** con Podman + quadlets y `AutoUpdate=registry`.
- ✅ **Proxy reverso y TLS automático** con Traefik (entrypoint `web`→`websecure` global).
- ✅ **Autenticación OIDC centralizada** con PocketID.
- ✅ **Secretos cifrados** con SOPS + age, inyectados vía Podman secrets (`crypta`).
- ✅ **Configuración declarativa** con dotfiles yaml (yadm) + plantillas jinja.
- ✅ **Guardas de integridad**: `qctl check`, `qctl install` atómico.
- ✅ **Relevo de sesión** en `HANDOFF.md`.

---

## 📁 Estructura del repositorio

```
.config/
├── containers/
│   ├── available/<stack>/        # fuente de verdad: quadlets de cada stack
│   └── systemd/                  # destino real: symlinks (lo lee systemd) — solo .gitkeep
├── <stack>/<stack>.env           # config NO secreta del stack (versionada)
├── environment.d/fqdn.conf       # FQDN del host (no secreto, gitignored) + .example
├── fish/
│   ├── config.fish               # añade ~/.local/bin al PATH, zoxide, starship
│   └── functions/                # unjinja, jcu, jcf, scupdate, genpass, yadmalt
├── traefik/dynamic/*.jinja       # plantilla de auth del dashboard (la única)
├── vector/vector.yaml            # config de Vector (PLANA; ${VAR} nativo) + vector.env (no secreto)
└── yadm/hooks/post_pull          # hook de despliegue (render + scaffold + daemon-reload)
setup.sh                          # bootstrap del host (root): usuarios, SSH, nftables
setup_apps.sh                     # bootstrap ONE-SHOT del usuario apps (runner): podman.socket, crypta, secretos, herramientas
```

---

## 📋 Requisitos

### Herramientas del sistema

| Herramienta       | Descripción                          | Instalación                              |
| ----------------- | ------------------------------------ | ---------------------------------------- |
| **git**           | Control de versiones                 | `sudo apt install git`                   |
| **yadm**          | Gestor de dotfiles                   | `sudo apt install yadm`                  |
| **age**           | Cifrado moderno                      | `sudo apt install age`                   |
| **bat**           | Visor de archivos mejorado           | `sudo apt install batcat`                |
| **zoxide**        | Navegador de directorios             | `sudo apt install zoxide`                |
| **ansifilter**    | Limpia ANSI de los journals          | `sudo apt install ansifilter`            |
| **apache2-utils** | Utilidades web (`htpasswd`)          | `sudo apt install apache2-utils`         |
| **fish**          | Shell interactivo                    | `sudo apt install fish`                  |
| **podman**        | Motor de contenedores                | `sudo apt install podman`                |

### Herramientas en `~/.local/bin`

| Herramienta   | Descripción                          | Instalación        |
| ------------- | ------------------------------------ | ------------------ |
| **sops**      | Cifrado de secretos                  | Binario (ver abajo)|
| **jinrender** | Motor de plantillas                  | Binario (ver abajo)|
| **crypta**    | Gestión de secretos simplificada     | Binario (ver abajo)|
| **yq**        | Procesador YAML/JSON (mikefarah)     | Binario (ver abajo)|
| **starship**  | Prompt personalizable                | Binario (ver abajo)|
| **qctl**      | CLI para gestionar quadlets          | Binario (ver abajo)|
| **nevi**      | Editor de terminal (Vim moderno)     | `cargo install`    |
| **rust/cargo**| Toolchain de Rust (para `nevi`)      | `rustup`           |

> ⚠️ **Regla de oro**: cualquier **binario descargado de GitHub** va a **`~/.local/bin` del usuario de aplicaciones** (`runner`, uid 1002; se llamaba `podman`/`apps` antes del rename de PLAN-008). Nunca a rutas de sistema, nunca con `sudo`. `~/.local/bin` ya está en el `PATH` vía `.config/fish/config.fish`.

---

## 🔧 Instalación

### 1. Dependencias del sistema

```bash
sudo apt update
sudo apt install -y git ansifilter yadm age bat zoxide apache2-utils fish podman
mkdir -p ~/.local/bin
```

### 2. Toolchain de Rust (necesario para `nevi`)

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"   # o reabre la shell
```

Dependencias de compilación de Nevi (Debian/Ubuntu):

```bash
sudo apt install -y build-essential cmake pkg-config libssl-dev zlib1g-dev \
  libx11-dev libxcb1-dev libxcb-render0-dev libxcb-shape0-dev libxcb-xfixes0-dev
```

### 3. Herramientas en `~/.local/bin`

```bash
# SOPS - Gestión de secretos
curl -LO https://github.com/getsops/sops/releases/download/v3.13.0/sops-v3.13.0.linux.amd64
install -m 755 sops-v3.13.0.linux.amd64 ~/.local/bin/sops && rm sops-v3.13.0.linux.amd64

# Jinrender - Motor de plantillas
curl -LO https://github.com/atareao/jinrender/releases/download/v0.1.2/jinrender-linux-x86_64
install -m 755 jinrender-linux-x86_64 ~/.local/bin/jinrender && rm jinrender-linux-x86_64

# Crypta - Gestión de secretos simplificada
curl -LO https://github.com/atareao/crypta/releases/download/v0.3.0/crypta-linux-x86_64
install -m 755 crypta-linux-x86_64 ~/.local/bin/crypta && rm crypta-linux-x86_64

# yq (mikefarah) - Procesador YAML/JSON (binario único, última release + checksum SHA-256)
curl -LO https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
curl -LO https://github.com/mikefarah/yq/releases/latest/download/checksums
curl -LO https://github.com/mikefarah/yq/releases/latest/download/checksums_hashes_order
COL=$(($(grep -n '^SHA-256$' checksums_hashes_order | cut -d: -f1) + 1))
EXPECTED=$(awk -v c="$COL" '$1=="yq_linux_amd64"{print $c}' checksums)
echo "$EXPECTED  yq_linux_amd64" | sha256sum -c -
install -m 755 yq_linux_amd64 ~/.local/bin/yq && rm -f yq_linux_amd64 checksums checksums_hashes_order

# Starship - Mejora del prompt
curl -LO https://github.com/starship/starship/releases/download/v1.27.0/starship-x86_64-unknown-linux-musl.tar.gz
tar xzf starship-x86_64-unknown-linux-musl.tar.gz
install -m 755 starship ~/.local/bin/starship && rm starship starship-*.tar.gz
```

### 4. `qctl` — gestor de quadlets

Descarga **siempre la última versión** publicada (binario estático x86_64 + checksum):

```bash
cd /tmp
curl -LO https://github.com/atareao/qctl/releases/latest/download/qctl-linux-x86_64
curl -LO https://github.com/atareao/qctl/releases/latest/download/qctl-linux-x86_64.sha256
sha256sum -c qctl-linux-x86_64.sha256
install -m 755 qctl-linux-x86_64 ~/.local/bin/qctl
rm -f qctl-linux-x86_64 qctl-linux-x86_64.sha256
qctl --version
```

Completions para fish:

```bash
qctl completions fish > ~/.config/fish/completions/qctl.fish
```

### 5. `nevi` — editor (reemplaza a Neovim)

[Nevi](https://github.com/anthonyamaro15/nevi) es un editor de terminal escrito en Rust, inspirado en Neovim, con LSP, tree-sitter y fuzzy-finding **integrados** (no necesita plugins, ni `ripgrep`/`fzf`/`fd` en runtime). Requiere **Rust ≥ 1.85**.

```bash
# --root ~/.local instala el binario en ~/.local/bin/nevi
cargo install --git https://github.com/anthonyamaro15/nevi --root "$HOME/.local" --locked
nevi --version
```

Primer uso:

```bash
nevi .            # abre un directorio
nevi fichero.rs   # abre un fichero
:checkhealth      # config, LSP y herramientas disponibles
```

Su configuración vive en `~/.config/nevi/` (`config.toml`, `languages.toml`, `themes/`), independiente del repositorio.

---

## ⚙️ Configuración inicial

### 1. Inicializar secretos y dotfiles

```bash
# Almacén de secretos cifrado
crypta init

# Desplegar los dotfiles
yadm init -b main
yadm remote add origin https://github.com/atareao/self-hosted-podman.git
yadm pull origin main
yadmalt
```

### 2. Configurar el dominio (FQDN)

El FQDN **no es un secreto**: vive en `~/.config/environment.d/fqdn.conf` (gitignored).

```bash
cp ~/.config/environment.d/fqdn.conf.example ~/.config/environment.d/fqdn.conf
# edita la línea:  FQDN=tu.dominio.com

systemctl --user daemon-reexec     # reinyecta el entorno en el user manager
```

### 3. Renderizar plantillas y recargar

```bash
unjinja                            # secretos + FQDN -> render de los *.jinja
systemctl --user daemon-reload
```

### 4. Arrancar los servicios base

```bash
cd .config/containers/available/traefik && qctl install
cd ../pocketid && qctl install     # qctl se ejecuta desde el dir del stack
qctl status                        # ver estado de todos los stacks
```

### 5. Autenticación (PocketID)

1. Navega a `https://auth.<tu-dominio>/setup` y crea el usuario administrador.
2. Añade **Traefik** como cliente OIDC:
   - **Callback**: `https://*.<tu-dominio>/oidc/callback`
   - **Grupos permitidos**: sin restricciones

```bash
echo "tu-client-id"     | crypta store oidc_client_id
echo "tu-client-secret" | crypta store oidc_client_secret
unjinja && scupdate traefik
```

> Aquí `crypta store` **sí es lo correcto**: estos valores los consume `unjinja` desde `secrets.yml` para renderizar una plantilla `.jinja`, no un `Secret=` de Podman.

---

## 🧩 Gestión de stacks

### `qctl` (recomendado)

CLI en Rust para instalar/desinstalar symlinks, arrancar/parar servicios `systemctl --user`, actualizar imágenes, ver estado y limpiar volúmenes.

> 📌 `qctl` descubre quadlets **en `./quadlets/` o en el directorio actual, en el primer nivel** (no recursivo). **Ejecútalo desde dentro del directorio del stack**: `cd ~/.config/containers/available/traefik && qctl status`. Desde la raíz del repo no encuentra nada.

| Comando | Para qué |
| ------- | -------- |
| `qctl install` | Enlaza los quadlets del proyecto actual en `~/.config/containers/systemd` |
| `qctl start [SERVICE]` | Instala (si falta) y arranca uno o todos |
| `qctl stop [SERVICE]` / `qctl restart [SERVICE]` | Para / reinicia |
| `qctl status [SERVICE] [--compact]` | Estado en tabla (o compacto para scripts) |
| `qctl menu` | Menú interactivo (arrancar/parar/reiniciar/logs) |
| `qctl update [SERVICE]` | `podman pull` de las imágenes (`Image=`) |
| `qctl clean-volumes [--yes]` | Borra los volúmenes declarados en `VolumeName=` |
| `qctl check <QUADLET>` | Verifica con `/usr/lib/podman/quadlet` |
| `qctl logs <SERVICE>` / `qctl logsf <SERVICE>` | Logs (estático / *follow*) |
| `qctl completions <SHELL>` | Genera completions |

Añade **`--dry-run`** (no muta nada) o **`--timeout <SEG>`** (por defecto 60 s) a las operaciones que invocan herramientas externas.

### Ciclo de vida de un stack con `qctl`

Flujo completo para desplegar, verificar y retirar un stack (ejemplo real probado con `ittools`):

```bash
# 1. Desplegar: entrar en el stack y enlazar/arrancar
cd ~/.config/containers/available/ittools
qctl install            # enlaza los quadlets en ~/.config/containers/systemd
qctl start              # arranca vía systemctl --user

# 2. Verificar
qctl status             # estado en tabla (🟢 = running)
qctl logs ittools       # logs estáticos (qctl logsf para seguir en vivo)
journalctl --user -u ittools -n 20 --no-pager
curl -sS -o /dev/null -w '%{http_code}\n' https://ittools.servidorlinux.es/

# 3. Retirar tras una prueba
qctl stop               # para el servicio
qctl uninstall          # desenlaza las unidades del target dir
```

Notas:

- `qctl install`/`uninstall` solo gestionan los **symlinks** en `~/.config/containers/systemd`; nunca borran los quadlets de `available/`.
- `qctl stop` para pero **no** desenlaza: la unidad sigue existiendo y volvería a arrancar en el siguiente arranque. Para sacarla de juego usa `qctl uninstall`.
- Para limpiar los datos de una prueba: `qctl clean-volumes --yes` (borra los volúmenes declarados con `VolumeName=`).
- La primera vez que se publica un subdominio, Traefik emite el certificado Let's Encrypt por HTTP-01 automáticamente; compruébalo con `curl -I https://<stack>.servidorlinux.es`.
- Verificación visual: abre la URL en el navegador; el DNS comodín `*.servidorlinux.es` ya apunta al servidor.

### Gestión de stacks (`qctl`) y funciones fish

| Comando | Descripción |
| ------- | ----------- |
| `qctl install` | Enlaza las unidades del stack (pre-scan atómico anti-colisión) + `daemon-reload` |
| `qctl uninstall` | Para los servicios y desenlaza el stack |
| `qctl status` | Estado (link + run) de las unidades; por defecto, todo el target dir |
| `qctl status --compact` | Igual, en TSV sin formato: `<unit>`, `<linked\|missing>`, `<running\|stopped\|->` por línea |
| `qctl check` | Detecta colisiones duras de basename/`ContainerName` y avisa de nombres fuera de convención |
| `unjinja` | Renderiza los `*.jinja` (secretos + FQDN) |
| `scupdate <unit>` | `daemon-reload` + `restart` de las unidades indicadas |
| `jcu <unit>` / `jcf <unit>` | Logs limpios (`ansifilter` + `batcat`); `jcf` sigue en vivo |
| `genpass [len]` | Genera una contraseña aleatoria (OpenSSL) |

> `qctl` descubre quadlets en el directorio actual: ejecútalo desde el directorio del stack (`cd .config/containers/available/<stack> && qctl install`). Desde la raíz del repo no encuentra nada.

### Añadir un stack nuevo

1. Crea `.config/containers/available/<stack>/` con sus quadlets (`<stack>.container`, `<stack>-<rol>.container`, `.volume`, `.network`).
2. Respeta el **esqueleto canónico** de quadlets (secciones en orden, ver `AGENTS.md`).
3. Config no secreta → `.config/<stack>/<stack>.env` (versionado) + `EnvironmentFile=%h/...`.
4. Credenciales → **`podman secret create <nombre> -`** (a fuego: nunca `crypta store`) y `Secret=<nombre>,type=env,target=<VAR>`.
5. Labels de Traefik con `Host(` <stack>.${FQDN} `)`.
6. **`qctl check`** (0 colisiones) y valida con el generador real (ver *Verificación*).
7. `cd .config/containers/available/<stack> && qctl install`.
8. **Commit con gitmoji** y `push` a `main`; en producción, `yadm pull`.

---

## 🔐 Secretos y configuración

### Crear un secreto

```bash
openssl rand -base64 32 | podman secret create mi_password -     # o:  genpass 32 | podman secret create mi_password -
```

> ⚠️ **A FUEGO — `podman secret create`, NUNCA `crypta store`.** Los secretos de Podman se resuelven por el **ID** del secreto (driver `shell` → `crypta`): `podman secret create` hace que Podman genere el ID y le entregue el valor a `crypta`; `crypta store <nombre>` escribe una clave huérfana bajo el nombre literal que Podman jamás encontrará (`no secret with name or id`).
>
> La **única excepción** es `crypta store`, usado para la **plantilla `.jinja`** que renderiza `unjinja` (`dashboard-auth.yml.jinja`), porque `unjinja` lee `secrets.yml` directamente.

Un nombre de `Secret=` **debe existir** (vía `podman secret create`) **antes** de arrancar la unidad, o el contenedor no inicia.

### Config no secreta

```bash
# defaults versionados
$EDITOR .config/<stack>/<stack>.env
# override por máquina (gitignored, no se versiona)
$EDITOR ~/.config/<stack>/<stack>.env.local
```

---

## 🔑 Acceso a producción (`rr`)

La infraestructura corre en `new_atareao` bajo el usuario **`runner`** (uid 1002, podman
rootless). No se accede a ese usuario por SSH directo: se entra como **`lorenzo`** (admin, grupo
`sudo`, sin password a runner) y se eleva con `sudo -u runner`.

Para operar producción existe el wrapper **`rr`**, en dos copias que cooperan:

- **En el servidor** (`~/bin/rr` de `lorenzo`): ejecuta `sudo -n -u runner -H env
  XDG_RUNTIME_DIR=/run/user/1002 PATH=… SOPS_AGE_KEY_FILE=… bash -lc "cd && <cmd>"`. Aporta el
  entorno completo de systemd user + crypta/sops + `~/.local/bin`, y fuerza bash (el login shell
  de `runner` es fish).
- **En tu máquina** (`~/bin/rr` de tu login): envía el comando al remoto por **base64** (evita
  que fish —local y el login shell del servidor— rompa las comillas/pipes) y lo ejecuta a través
  del `rr` remoto.

Uso:

```bash
rr                          # shell interactivo de runner (pide TTY)
rr "podman ps"              # ejecuta un comando como runner, sin TTY
rr 'journalctl --user -u errserve.service -n 20'
rr "crypta lookup oidc_client_id"   # secretos SOPS+age (SOPS_AGE_KEY_FILE ya exportado)
```

Reglas:

- **Nunca** SSH directo como `runner`; siempre vía `lorenzo` → `rr` (mantiene la separación:
  `runner` es cuenta de servicio sin sudo; `lorenzo` es el humano con sudo).
- El shell de `runner` es **fish**; `rr` fuerza `bash` explícitamente.

## 🔄 Actualización

### A. Desplegar cambios del repo en producción

Este repo es la **única fuente de verdad**. El flujo es siempre el mismo:

1. **En dev**: edita, valida, commit con **gitmoji** y `git push origin main`.
2. **En el servidor**:

   ```bash
   rr "yadm pull"        # vía el wrapper rr (operar como runner, env completo)
   # equivalente sin wrapper:
   sudo -u runner bash -c 'cd "$HOME" && yadm pull'
   ```

3. El hook **`post_pull`** hace automáticamente:
   - comprueba que el FQDN está definido,
   - **`unjinja`** (renderiza los `*.jinja` con los secretos y el FQDN),
   - **crea los `<stack>.env.local`** que falten (scaffold vacío),
   - **`systemctl --user daemon-reload`**.

4. Si el cambio afecta a unidades **en ejecución**, reaplica:

   ```bash
   scupdate <unit>          # daemon-reload + restart
   # o
   qctl restart <stack>     # desde dentro del directorio del stack
   ```

### B. Actualizar imágenes de contenedor

Los quadlets llevan `AutoUpdate=registry`. Dos vías:

```bash
# manual: pull de las imágenes y reinicio del stack
cd ~/.config/containers/available/<stack> && qctl update && qctl restart

# automática (requiere podman.socket, ya habilitado por setup_apps.sh)
podman auto-update
```

Tras cambiar una imagen, `systemctl --user daemon-reload` y reinicia la unidad.

### C. Actualizar las herramientas

```bash
# qctl -> última release de GitHub (a ~/.local/bin)
cd /tmp && curl -LO https://github.com/atareao/qctl/releases/latest/download/qctl-linux-x86_64 \
  && curl -LO https://github.com/atareao/qctl/releases/latest/download/qctl-linux-x86_64.sha256 \
  && sha256sum -c qctl-linux-x86_64.sha256 \
  && install -m 755 qctl-linux-x86_64 ~/.local/bin/qctl \
  && rm -f qctl-linux-x86_64*

# nevi (recompila e reinstala desde la rama principal)
cargo install --git https://github.com/anthonyamaro15/nevi --root "$HOME/.local" --locked --force
```

---

## 🧪 Verificación y resolución de problemas

```bash
systemctl --user daemon-reload            # recarga unidades tras tocar quadlets
qctl status                               # desde dentro del directorio del stack
qctl check                                # colisiones de nombres (debe salir "Sin colisiones duras")
systemctl --user status <unit>            # detalle de una unidad
jcu <unit>        # logs limpios         #  jcf <unit>  -> en vivo
```

**Validar un stack con el generador real de quadlet** (sin tocar `~/.config/containers/systemd`):

```bash
QUADLET_UNIT_DIRS=<dir-con-units-y-redes> /usr/lib/podman/quadlet -user -dryrun
```

> ⚠️ El binario real es **`/usr/lib/podman/quadlet`** (en algunos hosts `qi` apunta a `/usr/libexec/podman/quadlet`, que **no existe**). Copia en el directorio temporal las `.network`/`.volume` referenciadas o dará `unable to translate dependency for <net>.network`.

### Trampas conocidas

- **`EnvironmentFile` relativo** se resuelve contra el directorio del unit (`systemd/`), **no** contra el destino del symlink → usa **siempre** ruta absoluta `%h/...`.
- Quadlet **no** soporta el prefijo `-` en `EnvironmentFile`.
- `{% raw %}` solo en ficheros `.jinja`; un `.container` plano debe llevar el `{{ ... }}` literal (añadir los marcadores ahí es un error de sintaxis de systemd).
- Rootless: `WantedBy=default.target` (nunca `multi-user.target`).
- FQDN deploy: editar `fqdn.conf` → `systemctl --user daemon-reexec` y **reiniciar** la unidad (las unidades en marcha conservan el valor antiguo).
- Los hooks y funciones del repo son **fish**, no bash.
- **`yq`**: se instala **mikefarah/yq** (v4, binario único) en `~/.local/bin`; el que da `apt` es kislyuk/yq (v3, sobre `jq`). `unjinja`/`yadmalt` usan una expresión válida en ambos y suben a mayúsculas con `string upper` de fish. Ya no se instala `jq`.
- **PATH en shells no interactivos**: el hook `post_pull` y `fish -c` no ejecutan `config.fish`, así que `unjinja`/`yadmalt` fijan por sí mismos `~/.local/bin` en `PATH` y `SOPS_AGE_KEY_FILE` (si no, `sops`/`jinrender` no se encuentran y el render falla en silencio).

---

## 🌐 Acceso a servicios

| Servicio              | URL                                | Descripción                |
| --------------------- | ---------------------------------- | -------------------------- |
| **Traefik Dashboard** | `https://traefik.<tu-dominio>`     | Panel del proxy            |
| **PocketID**          | `https://auth.<tu-dominio>`        | Autenticación OIDC         |
| **WordPress**         | `https://blog.<tu-dominio>`        | Sitio principal            |

---

## 📚 Documentación adicional

- [`AGENTS.md`](AGENTS.md) — guía interna: modelo de quadlets, esqueleto canónico, migración desde docker-compose, secretos, naming.
- [`HANDOFF.md`](HANDOFF.md) — relevo de la última sesión (local, no se despliega).
- [qctl](https://github.com/atareao/qctl) · [nevi](https://github.com/anthonyamaro15/nevi) · [jinrender](https://github.com/atareao/jinrender) · [crypta](https://github.com/atareao/crypta)

## 🤝 Contribuir

1. Fork el repositorio.
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`).
3. Commit con **gitmoji + conventional commits** (`✨ feat(scope): …`).
4. Push y abre un Pull Request.

## 📄 Licencia

MIT. Ver [LICENSE](LICENSE).

---

<div align="center">
  <b>Hecho con ❤️ para la comunidad de auto-alojamiento</b>
</div>
