# Gestión de stacks con `qctl`

## Qué es

`qctl` es el CLI único para gestionar los stacks de este repo: enlaza/desenlaza quadlets en el
directorio que lee Podman, arranca y para unidades, audita colisiones de nombres y muestra estado.
Sustituye por completo a los antiguos helpers fish `qenable`/`qdisable`/`qlist`/`qcheck`, que se
eliminaron para no mantener dos implementaciones de la misma lógica.

> ⚠️ **Todos los comandos se ejecutan desde el directorio del stack.**
> `qctl` descubre quadlets de forma **no recursiva** en el directorio actual (`./quadlets/` o `.`).
> Desde la raíz del repo no encuentra nada:
> `cd .config/containers/available/<stack> && qctl install`.

## Ficheros implicados

- `.config/containers/available/<stack>/` — **fuente de verdad**. Un directorio por stack con sus
  quadlets (`*.container`, `*.volume`, `*.network`, `*.pod`, `*.kube`; alguno como `*.jinja`).
- `.config/containers/systemd/` — **target dir** que lee Podman/systemd. Solo contiene `.gitkeep`;
  los ficheros llegan como **symlinks** desde `available/<stack>/`.
- `~/.local/bin/qctl` — binario estático del usuario de apps.
- `/data/rust/qctl` — repositorio origen del binario (fuera de este repo).

## Cómo funciona

### Modelo `available/` → symlinks en `systemd/`

`available/` es inerte: un stack no hace nada hasta que sus ficheros se enlazan en
`.config/containers/systemd/` y se recarga systemd. Eso es exactamente lo que hace `qctl install`:

1. Descubre los quadlets del stack en el directorio actual (no recursivo).
2. **Pre-scan atómico anti-colisión**: comprueba el basename de cada unit y cada `ContainerName=`
   contra el resto de stacks del *stacks root*. Si hay choque, **aborta sin enlazar nada**.
3. Crea los symlinks en `.config/containers/systemd/` y ejecuta `daemon-reload`.

`qctl uninstall` hace lo inverso: para los servicios y desenlaza. **Nunca** borra los quadlets de
`available/`.

### `unjinja` antes de `install`

Si el stack tiene plantillas `.jinja`, hay que renderizarlas **antes** de enlazar; `qctl install` solo
enlaza ficheros ya renderizados. En este repo queda una única plantilla
(`.config/traefik/dynamic/dashboard-auth.yml.jinja`) y el hook `post_pull` ejecuta `unjinja`
automáticamente tras un `yadm pull`.

### Descubrimiento no recursivo

El descubrimiento es de **primer nivel**: `qctl` no baja a subdirectorios. De ahí la regla de oro de
ejecutarlo desde dentro de `.config/containers/available/<stack>`.

## Mapeo de los antiguos helpers fish → `qctl`

| Helper eliminado | Equivalente actual |
|---|---|
| `qenable <stack>` | `cd .config/containers/available/<stack> && qctl install` |
| `qdisable <stack>` | `cd .config/containers/available/<stack> && qctl uninstall` |
| `qlist` | `qctl status` (o `qctl status --compact` para scripts, `qctl status --project` limitado al stack actual) |
| `qcheck` | `qctl check` (sin argumentos = auditoría global) |

Comandos disponibles:

| Comando | Descripción |
|---|---|
| `qctl install` | Enlaza los quadlets del stack + `daemon-reload` (pre-scan atómico) |
| `qctl uninstall` | Para los servicios y desenlaza el stack |
| `qctl status [--compact] [--project]` | Estado (link + run); `--compact` = TSV; `--project` = solo el stack actual |
| `qctl check [<quadlet>]` | Sin args audita todos los stacks (colisiones duras → exit ≠ 0; nombres fuera de convención → WARN); con arg valida un fichero |
| `qctl start\|stop\|restart [<unit>]` | Ciclo de vida de las unidades |
| `qctl update [<unit>]` | `podman pull` de las imágenes declaradas |
| `qctl reload` | `daemon-reload` |
| `qctl clean-volumes` | Borra los volúmenes declarados por el stack |
| `qctl menu` | Menú interactivo |
| `qctl logs\|logsf <unit>` | Logs estáticos / en vivo |
| `--dry-run` | Muestra lo que haría sin tocar nada (flag global) |
| `--stacks-root <dir>` | Override del stacks root (default `$HOME/.config/containers/available`) |

## Instalación del binario

Release **v0.6.0** de `atareao/qctl` (tag remoto = commit `9b4bcac`). El binario estático se publica
como `qctl-linux-x86_64` junto a su `.sha256`:

```sh
curl -LO https://github.com/atareao/qctl/releases/latest/download/qctl-linux-x86_64
curl -LO https://github.com/atareao/qctl/releases/latest/download/qctl-linux-x86_64.sha256
sha256sum -c qctl-linux-x86_64.sha256
install -m 755 qctl-linux-x86_64 ~/.local/bin/qctl
rm -f qctl-linux-x86_64 qctl-linux-x86_64.sha256
```

SHA-256 del binario v0.6.0 verificado:

```
7accceb0f6e63b3d21407d10757a4d497b56802e41434aafb0f4a31b8147058b
```

Se instala en `~/.local/bin` del usuario de apps (nunca en rutas de sistema); ese directorio ya está
en `PATH`.

### Por qué se eliminaron los helpers fish

- **Una sola implementación**: `install`/`uninstall`/`status`/`check` viven en `qctl`; los scripts
  fish duplicaban la lógica y se desincronizaban.
- **La guarda de colisión pasó a `qctl`**: el pre-scan atómico de `qenable` se movió a `install` y la
  auditoría de `qcheck` a `check` (sin argumentos), así que borrar los helpers **no** perdió ninguna
  protección.
- **Menos superficie**: las funciones no se cargaban en shells no interactivos (el hook `post_pull` y
  `fish -c` no ejecutan `config.fish`), lo que ya obligaba a duplicar fijaciones de `PATH`.

## Verificación

```sh
cd .config/containers/available/<stack>

qctl status            # estado legible (🟢 = running)
qctl status --compact  # TSV: <unit> <linked|missing> <running|stopped|->
qctl check             # auditoría global: colisiones duras + avisos de convención
```

- `qctl check` con **rc=0** y avisos (WARN) de convención es un resultado correcto: los avisos no
  fallan la auditoría.
- El catch-all de Traefik se prueba desde fuera: una ruta o subdominio inexistentes deben devolver la
  página de error servida por `errserve` (404 real, no el 404 por defecto de Traefik).

## Desinstalar y purgar un stack

`qctl uninstall` sólo **para y desenlaza** (nunca borra los quadlets de `available/`). Todo lo que el
stack dejó al ejecutarse —secretos, volúmenes, datos en binds e imágenes— sobrevive y hay que
retirarlo a mano si se quiere una limpieza total. Procedimiento completo, desde el directorio del stack:

```sh
cd .config/containers/available/<stack>

# 1. Parar y desenlazar (no borra los quadlets de available/)
qctl uninstall

# 2. Volúmenes declarados por el stack (*.volume)
qctl clean-volumes                  # o: podman volume rm <v1> <v2> ...

# 3. Secretos del stack (los nombres van en las líneas Secret= del quadlet)
podman secret rm <secreto> ...

# 4. Datos en bind mounts de la app
rm -rf ~/.config/<stack>
# Si el contenedor corría con User=<uid> y los ficheros quedaron con uid mapeado
# (p. ej. navidrome, User=1000:1000), el rm falla con «Permission denied»: usar
podman unshare rm -rf ~/.config/<stack>

# 5. Imágenes (opcional)
podman rmi <imagen>:<tag> ...
```

Notas:
- **No hay `qctl` para secretos, binds ni imágenes**: se limpian con `podman`.
- Los volúmenes nombrados se listan con `podman volume ls`; los del stack se declaran en sus `*.volume` (`VolumeName=`).
- **Binds con uid mapeado**: si el contenedor define `User=<uid>` (p. ej. `User=1000:1000`), los
  ficheros del bind quedan propiedad del subuid y `rm -rf` desde el host falla con «Permission denied»;
  hay que borrarlos dentro del namespace con `podman unshare rm -rf <ruta>`.
- Tras purgar, verificar que no quedan restos: `podman ps -a`, `podman volume ls`, `podman secret ls`,
  `podman images`, y que no haya symlinks en `~/.config/containers/systemd/`.

## Resultado del despliegue de `errserve` en prod

Host `new_atareao` (usuario `runner`), 2026-11-07:

1. `yadm pull` hasta `ffb8b00`; el hook `post_pull` renderizó la plantilla y scaffoldó
   `.config/errserve/errserve.env` + `.config/errserve/errserve.env.local` (vacío; el stack no
   necesita overrides).
2. `cd .config/containers/available/errserve && qctl install` → `errserve.container` enlazado en
   `~/.config/containers/systemd`.
3. `qctl start errserve` → unidad `active`, contenedor `errserve` **healthy**
   (`ghcr.io/atareao/errserve:latest`, escucha `0.0.0.0:8080`, red `proxy.network`,
   `NetworkAlias=errserve`). Sin secretos ni volúmenes.
4. `qctl check` → **rc=0** con 2 avisos de convención: `proxy.network` (stack `traefik`) y
   `security.network` (stack `vector`). Son redes **compartidas**, no units de stack → falso positivo
   conocido de la regla actual.
5. `qctl status --compact` → `errserve`, `pocketid` y `traefik` los tres `linked` + `running`.
6. Pruebas HTTPS externas: subdominio inexistente y ruta inexistente → **404 real** servido por
   `errserve` (router `errserve-catchall@docker`, prioridad 1; middleware `errpages` 400-599 →
   `/{status}`); `auth.servidorlinux.es` → 200 con TLS válido; `traefik.servidorlinux.es` → 401
   (basic auth) con TLS válido. PocketID vive en `auth.servidorlinux.es`, **no** en
   `pocketid.servidorlinux.es`.
7. Limpieza: en prod había 3 units **untracked obsoletas**
   (`.config/containers/available/{miniflux/miniflux_db,mumble/recorder,wakapi/wakapi_db}.container`)
   que ensuciaban `qctl check`; no estaban enlazadas ni tenían contenedor. Se copiaron a
   `/tmp/stale-units-20261107064140` y se borraron. No se borró nada versionado.

## Decisiones

- **`qctl` como única vía** de gestión de stacks: se retiran los helpers fish y las completions
  asociadas.
- **Flujo `cd <stack> && qctl ...`**: se pierde el "operar por nombre desde cualquier sitio" de
  `qenable`, a cambio de un descubrimiento simple y predecible (no recursivo).
- **`check` con y sin argumento**: sin args = auditoría global (colisiones duras → exit ≠ 0; nombres
  fuera de convención → WARN, no falla); con arg = validación puntual de un quadlet.
- **Stacks root configurable** con `--stacks-root` (default `$HOME/.config/containers/available`).
- **Binario estático verificado por SHA-256** en `~/.local/bin`; nunca rutas de sistema.

## Follow-ups

- **Falso positivo de `qctl check`** con redes compartidas (`proxy.network`, `security.network`):
  hoy las marca como nombres fuera de convención. Habría que excluir redes compartidas de la regla.
- **Regla de convención configurable**: la regla `<stack>.<ext>` / `<stack>-<rol>` está fija en el
  código; valorar hacerla configurable.
- **Volumen `CONTENT_DIR` para `errserve`** si se quieren páginas de error propias.
- Si se quiere certificado propio para el catch-all TLS, añadir `tls.certresolver` al router de
  `errserve` (hoy usa el certificado por defecto de Traefik).