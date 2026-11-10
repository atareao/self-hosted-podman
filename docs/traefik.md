# traefik — Edge router rootless (reverse proxy + TLS)

## Qué es

Traefik es el **edge router** del host: reverse proxy que descubre los servicios por labels, termina el TLS (Let's Encrypt) y los publica en la red `proxy`. Es el núcleo del stack self-hosted.

- **App / imagen (`Image=`):** `docker.io/library/traefik:latest`, contenedor `traefik`.
- **Nº contenedores:** 1.
- **Red:** `proxy.network` (red edge, `NetworkName=proxy`, `DisableDNS=true`, `Options=isolate=strict`), que el resto de stacks se unen para ser enrutados.
- **Dominio:** no declara labels `traefik.*` (es el propio router). Sirve `${FQDN}` y todos los subdominios `<stack>.${FQDN}` según los routers de cada stack.
- **Puertos:** no usa `PublishPort`; escucha 80/443 mediante **socket activation** de systemd (`Sockets=http.socket https.socket`, `Requires=http.socket https.socket podman.socket`).
- **Extra:** `AddHost=auth.${FQDN}:host-gateway` para que el contenedor resuelva el servicio de auth del host.

## Ficheros

- Quadlet(s): `.config/containers/available/traefik/traefik.container`
- Volumen(es):
  - `.config/containers/available/traefik/traefik-certs.volume` (certificados)
  - `.config/containers/available/traefik/traefik-plugins.volume` (persistencia de plugins)
- Red(es): `.config/containers/available/traefik/proxy.network`
- Config no secreta: no existe `.env` de stack (no hay `.config/traefik/.env`). La configuración vive en ficheros: `~/.config/traefik/traefik.yml` (estática) y `~/.config/traefik/dynamic/` (dinámica, incluye `dashboard-auth.yml.jinja`).
- Secretos: `cf_dns_api_token`.

## Cómo funciona

- **Redes:** `proxy.network` es la red edge compartida; el resto de stacks se unen a ella para que Traefik los descubra. Se define con `DisableDNS=true` y `Options=isolate=strict`.
- **Descubrimiento de servicios:** monta el socket de Podman del usuario en solo lectura (`%t/podman/podman.sock:/var/run/docker.sock:ro`) y `Notify=true`, de modo que Traefik detecta los contenedores y sus labels `traefik.*` en caliente.
- **Volúmenes:**
  - `%h/.config/traefik/traefik.yml` → `/etc/traefik/traefik.yml` (config estática, `:ro,Z`).
  - `traefik-certs.volume` → `/etc/traefik/certs` (`:rw,Z`): certificados gestionados por Podman.
  - `%t/podman/podman.sock` → `/var/run/docker.sock` (`:ro`).
  - `%h/.config/traefik/dynamic` → `/etc/traefik/dynamic` (`:ro,Z`): config dinámica (middlewares `seguridadHeaders@file`, `compresionHeaders@file`, etc.).
  - `traefik-plugins.volume` → `/plugins-storage` (`:rw,Z`): plugins descargados.
- **Secretos:** `cf_dns_api_token` se inyecta como variable de entorno con `Secret=cf_dns_api_token,type=env,target=CF_DNS_API_TOKEN` (driver `crypta`); se usa para el challenge DNS de Let's Encrypt. No hay `EnvironmentFile`.
- **Healthcheck:** `HealthCmd=traefik healthcheck --ping`, `HealthInterval=30s`, `HealthRetries=3`, `HealthTimeout=5s`, `HealthStartPeriod=10s`.
- **Enrutado:** al ser el router, no lleva labels; el enrutado se define en los quadlets de cada stack (`traefik.http.routers.<x>.rule=Host(\`<x>.${FQDN}\`)`, `entrypoints=websecure`, `tls.certresolver=letsencrypt`).
- **Hardening (el más endurecido del repo):** `ReadOnly=true`, `NoNewPrivileges=true`, `SecurityLabelDisable=true`.
- **Recursos:** `Memory=512M` (en `[Container]`) y `CPUWeight=50` (en `[Service]`, prioridad de CPU reducida).
- **Arranque:** `After=network-online.target http.socket https.socket podman.socket` + `Requires=http.socket https.socket podman.socket`; `Restart=always` (sin `RestartSec`/límites de arranque), `WantedBy=default.target`. `PodmanArgs=--init`.

## Variables / configuración

| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| `TZ` | `traefik.container` (`Environment=`) | `Europe/Madrid` | Zona horaria del contenedor |
| `CF_DNS_API_TOKEN` | `traefik.container` (`Secret=cf_dns_api_token`) | *(secreto)* | Token de API de Cloudflare para el challenge DNS-01 de Let's Encrypt |
| `FQDN` | `traefik.container` (`AddHost=auth.${FQDN}:host-gateway`) y labels de los demás stacks | *(inyectada por systemd desde `~/.config/environment.d/fqdn.conf`)* | Dominio raíz del host |
| `http.socket` / `https.socket` | `traefik.container` (`[Service] Sockets=`) | — | Sockets systemd que activan los puertos 80/443 rootless |

No hay `.env` de stack para este servicio.

## Cómo habilitar / desplegar

1. Crear el secreto (con `podman secret create`, **nunca** `crypta store`):

```bash
printf '%s' '<valor>' | podman secret create cf_dns_api_token -
```

2. `cd .config/containers/available/traefik && qctl install`
3. `systemctl --user daemon-reload`

## Follow-ups

- Requiere que existan y estén activos `.config/systemd/user/http.socket` y `https.socket` (puertos 80/443 rootless); sin ellos Traefik no arranca (`Requires=`).
- Requiere `~/.config/traefik/traefik.yml` y `~/.config/traefik/dynamic/` presentes en el host; el stack no los versiona (solo el quadlet).
- `Image=traefik:latest` sin `AutoUpdate=registry`: la actualización es manual.
- `Restart=always` sin `RestartSec` ni límites de arranque, a diferencia del resto de stacks.

## Certificados y resolvers ACME

En `.config/traefik/traefik.yml` hay **dos** `certificatesResolvers`:

- `letsencrypt` — CA de **producción** (`https://acme-v02.api.letsencrypt.org/directory`), reto **HTTP-01** por el entrypoint `web`, storage `/etc/traefik/certs/acme.json`. Es el que usan los stacks de producción.
- `letsencrypt-staging` — CA de **staging** (`https://acme-staging-v02.api.letsencrypt.org/directory`), mismo reto HTTP-01, storage `/etc/traefik/certs/acme-staging.json`. Se usa **solo en rondas de verificación E2E** (los stacks de prueba), para no agotar la cuota de producción de Let's Encrypt (límite: 50 certificados por dominio registrado cada 168 h — nos topamos con un 429 durante PLAN-022).

- **Cómo usar staging en un stack de prueba:** en su quadlet, `Label=traefik.http.routers.<x>.tls.certresolver=letsencrypt-staging` (en reposo, todos los quadlets versionados apuntan al resolver de producción `letsencrypt`).
- Los certificados emitidos por la CA staging **no son de confianza** para los navegadores; sirven para validar que el reto ACME y el enrutado funcionan.
- **Nota:** el dominio `servidorlinux.es` tiene los NS en `dondominio` (no Cloudflare), así que el `cf_dns_api_token` presente no sirve para un reto DNS-01/wildcard del apex; por eso el reto es HTTP-01 por subdominio y la cuota se consume rápido en rondas grandes.
