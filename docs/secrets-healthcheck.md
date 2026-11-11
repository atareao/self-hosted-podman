# Driver de secretos externo (crypta) y healthcheck

## Qué es

Con Podman 5.7.0 (prod `new_atareao`), los quadlets que combinan un secreto
`Secret=<name>,type=env` (driver `shell` -> `crypta` -> `sops`) con un `HealthCmd`
no llegan a `healthy`: el healthcheck automático falla con `Error: <id>: no such secret`.

## Ficheros implicados

- `.config/environment.d/crypta.conf` — entorno que necesita el driver.
- `~/.secrets/sops/age/key.txt` — clave age para descifrar el store SOPS.
- `.config/containers/containers.conf` — `[secrets] driver = "shell"` y `[secrets.opts]` con `crypta store/lookup/delete/list`.

## Cómo funciona (causa raíz)

El healthcheck automático de Podman **no lo ejecuta conmon**: Podman lo lanza como
**unit transitoria** `systemd-run --user … podman healthcheck run <ctr>`, que
**solo hereda el entorno del systemd user manager** (no el `Environment=` del quadlet).
Para construir el exec del healthcheck, Podman re-resuelve los secretos `type=env`
invocando el driver `shell` (`crypta lookup <id>`). Si en ese entorno no están
`~/.local/bin` (donde viven `crypta` y `sops`) ni `SOPS_AGE_KEY_FILE`, el driver falla
y Podman reporta `Error: <id>: no such secret`.

No es un fallo de crypta ni de SOPS: es entorno ausente en la unit transitoria.

## Síntomas

- Contenedor `unhealthy` / unit `activating`.
- En `journalctl --user`: `Started …timer - [systemd-run] /usr/bin/podman healthcheck run <ctr>` y luego `Error: <id>: no such secret`.
- `podman healthcheck run <ctr>` a mano funciona (corre con el entorno completo del shell).

## Diagnóstico rápido

```sh
# con el entorno del user manager (reproduce el fallo)
systemd-run --user --wait --collect --pipe /bin/sh -c 'crypta lookup <id>; echo rc=$?'
# con el entorno corregido
systemd-run --user --wait --collect --pipe /bin/sh -c 'PATH=$HOME/.local/bin:$PATH SOPS_AGE_KEY_FILE=$HOME/.secrets/sops/age/key.txt crypta lookup <id>; echo rc=$?'
```

## Fix

```ini
# ~/.config/environment.d/crypta.conf
PATH=$PATH:$HOME/.local/bin
SOPS_AGE_KEY_FILE=$HOME/.secrets/sops/age/key.txt
```

Aplicar: `systemctl --user daemon-reexec`. Las units ya en ejecución conservan su
`Environment=` propio; no hace falta recrear contenedores por este cambio.

**No** es necesario migrar las units a `type=mount` ni quitar `HealthCmd`: el fallo
es de entorno, no de las units.

## Verificación

```sh
podman run -d --name hctest --secret <name>,type=env \
  --health-cmd 'test -n "$<TARGET>"' --health-interval 5s --health-retries 3 \
  docker.io/library/alpine:3 sh -c 'sleep 60'
sleep 12
podman inspect --format '{{.State.Health.Status}}' hctest   # -> healthy
```

## Decisiones / follow-ups

- Alternativa defensiva: usar rutas absolutas en `[secrets.opts]` de `containers.conf`.
- Reporte upstream (opcional): la unit transitoria del healthcheck debería heredar el
  entorno del contenedor/unit, o documentarse.
- Referencia: issue #23 / `plans/PLAN-028.md`.
