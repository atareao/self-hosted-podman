#!/bin/bash

# --- CONFIGURACIÓN ---
DOMINIO="tudominio.es"
echo "--------------------------------------------------------"
# Persistencia de usuario
loginctl enable-linger $USER
# Habilitar e iniciar el socket de Podman
systemctl --user enable --now podman.socket
echo "--------------------------------------------------------"
# Instalación de herramientas útiles para administración y desarrollo
mkdir -p ~/.local/bin
# SOPS - Gestión de secretos
curl -LO https://github.com/getsops/sops/releases/download/v3.11.0/sops-v3.11.0.linux.amd64
mv sops-v3.11.0.linux.amd64 ~/.local/bin/sops
chmod +x ~/.local/bin/sops
# Jinrender - Motor de templates
curl -LO https://github.com/atareao/jinrender/releases/download/v0.1.2/jinrender-linux-x86_64
mv jinrender-linux-x86_64 ~/.local/bin/jinrender
chmod +x ~/.local/bin/jinrender
# Crypta - Gestión de secretos simplificada
curl -LO https://github.com/atareao/crypta/releases/download/v0.1.8/crypta-linux-x86_64
mv crypta-linux-x86_64 ~/.local/bin/crypta
chmod +x ~/.local/bin/crypta
# Starship - Mejora del prompt
curl -LO https://github.com/starship/starship/releases/download/v1.24.2/starship-i686-unknown-linux-musl.tar.gz -o starship.tar.gz
tar xvzf starship.tar.gz
mv starship ~/.local/bin/starship
chmod +x ~/.local/bin/starship
# Hardening
chmod 700 ~/.local/bin
chmod 700 ~/.secrets
chmod 600 ~/.secrets/sops/age/key.txt
chmod 700 ~/.local/share/containers
chmod 700 ~/.gnupg
chmod 700 ~/.ssh
# Inicializar gestión de secretos
crypta init
crytpa set --key fqdn --value "$DOMINIO"
# Incializar secretos para podman
openssl rand -hex 16 | podman secret create pocketid_encryption_key -
openssl rand -base64 32 | podman secret create temporal -
openssl rand -base64 32 | podman secret create wordpress_db_password -
openssl rand -base64 32 | podman secret create mariadb_root_password -
# Configurar dotfiles con YADM
yadm init -b main
yadm remote add origin https://github.com/atareao/self-hosted-podman.git
yadm pull origin main
yadmalt


