# ferrishare — Ferrishare es un servicio de compartición de archivos interno

## Qué es
App: ferrishare
Imagen: ghcr.io/tobiasmarschner/ferrishare
Nº contenedores: 1
Red: proxy.network
Dominio: subdominio `ferrishare.${FQDN}`
Puerto interno: 3000

## Ficheros
- Quadlet(s): /data/self-hosted-podman/.config/containers/available/ferrishare/ferrishare.container
- Volumen(es): /data/self-hosted-podman/.config/containers/available/ferrishare/ferrishare-data.volume
- Script de provisioning: /data/self-hosted-podman/.config/containers/available/ferrishare/ferrishare-init.py
- Config no secreta:
- Secretos:

## Cómo funciona
Red proxy.network, volumen ferrishare-data.volume, socket del daemon (none), healthcheck (none), enrutado Traefik, User/UserNS/NoNewPrivileges (none).

Antes del primer arranque ferrishare exige `./data/config.toml`. El binario solo lo genera por un wizard
**interactivo** (`ferrishare --init`) que hashea la contraseña de admin con argon2id. El script
`ferrishare-init.py` lo automatiza: abre un PTY, responde a todos los prompts (los `Text`/`Select`/`Confirm`
ya traen valor inicial, así que se aceptan con ENTER) y escribe `config.toml` en el volumen nombrado.

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `FH_ADMIN_PW` | entorno del script | (generado) | Contraseña de admin; si no se define, el script genera una aleatoria y la imprime. |

## Cómo habilitar / desplegar
1. **(Solo la primera vez)** Generar la config dentro del volumen nombrado:
   `python3 .config/containers/available/ferrishare/ferrishare-init.py`
   (o `FH_ADMIN_PW='...' python3 .config/containers/available/ferrishare/ferrishare-init.py`).
   Guarda la contraseña que imprime: **no es recuperable** (los secretos de Podman son write-only y el
   hash argon2id de `config.toml` no se puede revertir).
2. Secretos: (ninguno; NUNCA `crypta store`).
3. `cd .config/containers/available/ferrishare && qctl install`
4. `systemctl --user daemon-reload`

## Follow-ups
- El script depende de los textos de prompt de la versión actual del wizard de ferrishare (en inglés).
  Si upstream los cambia, hay que ajustar `build_steps()`.

## Estado de despliegue

Probado en producción (`new_atareao`) el 2026-11-09 (issue #11): `ferrishare-init.py` genera `config.toml`
(verificado: hash `argon2id`; defaults `app_name=FerriShare`, `interface=0.0.0.0:3000`, `proxy_depth=1`,
`maximum_filesize=25M`, `maximum_quota=5G`, `log_level=INFO`, `privacy=true`, `legal=false`, `demo_mode=false`),
desplegado y verificado end-to-end (router Traefik + cert LE + HTTP 200) y **purgado ese mismo día**.
Estado actual: **no desplegado** (el script queda en el repo).
