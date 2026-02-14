# [Auto](Auto.md) alojamiento con Podman (Self Hosted with Podman)

## Herramientas a instalar

- git
- yadm
- sops
- age
- yq
- jinrender
- crypta

```bash
sudo apt install git yadm age yq
mkdir -p ~/.local/bin
curl -LO https://github.com/getsops/sops/releases/download/v3.11.0/sops-v3.11.0.linux.amd64
mv sops-v3.11.0.linux.amd64 ~/.local/bin/sops
chmod +x /usr/local/bin/sops
curl -LO https://github.com/atareao/jinrender/releases/download/v0.1.2/jinrender-linux-x86_64
mv jinrender-linux-x86_64 ~/.local/bin/jinrender
chmod +x /usr/local/bin/jinrender
curl -LO https://github.com/atareao/crypta/releases/download/v0.1.8/crypta-linux-x86_64
mv crypta-linux-x86_64 ~/.local/bin/crypta
chmod +x /usr/local/bin/crypta
```

### Configuración

```bash
crypta init
yadm init
yadm remote add origin https://github.com/atareao/self-hosted-podman.git
yadm pull
yadmalt
```

Ahora configura tu fqdn, solo el dominio. Para ello ejecuta el siguiente comando,

```bash
crypta set --key fqdn --value "tuservidor.es"
```

Ahora realiza la sustitución de todas las variables de entorno. Para esto simplemente tienes que ejecutar el siguiente comando,

```bash
unjinja
```

Y levanta tus servicios

```bash
systemctl --user daemon-reload
systemctl --user start traefik wordpress pocketid
```

Vamos a configurar PocketID, para esto ves a `https://auth.tuservidor.es/setup` y configura el usuario y credenciales.

Una vez completado este paso, tienes que añadir `traefik` como cliente OIDC, Donde lo único que tienes que configurar es el Nombre del cliente y la URL de devolución de llamada que será `https://*.tuservidor.es/oidc/callback`. Y, por último en **Grupos de usuarios permitidos** selecciona la opción **Sin restricciones**.

Ahora toca completar los credenciales de `traefik` para esto ejecuta el siguiente comando,

```bash
openssl rand -hex 16 | crypta store oidc_secret
echo "<El client-id de PocketID>" | crypta store oidc_client_id
echo "<El client-secret de PocketID>" | crypta store oidc_client_secret
```

Y de nuevo ejecuta el comando `unjinja` para que se sustituyan las variables de entorno y reinicia `traefik` para que los cambios surtan efecto. Y con esto ya puedes acceder al dashboard de `traefik` a través de `https://traefik.tuservidor.es`.

