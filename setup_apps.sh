#!/bin/bash

# --- CONFIGURACIÓN ---
DOMINIO="tudominio.es"
echo "--------------------------------------------------------"
# Persistencia de usuario
loginctl enable-linger $USER
# Habilitar e iniciar el socket de Podman
systemctl --user enable --now podman.socket
echo "--------------------------------------------------------"
# Instalación de herramientas útiles para administración y desarrollo.
# REGLA: cualquier binario descargado de GitHub va a ~/.local/bin (NUNCA a rutas de sistema).
mkdir -p ~/.local/bin
# SOPS - Gestión de secretos
curl -LO https://github.com/getsops/sops/releases/download/v3.13.0/sops-v3.13.0.linux.amd64
mv sops-v3.13.0.linux.amd64 ~/.local/bin/sops
chmod +x ~/.local/bin/sops
# Jinrender - Motor de templates
curl -LO https://github.com/atareao/jinrender/releases/download/v0.1.2/jinrender-linux-x86_64
mv jinrender-linux-x86_64 ~/.local/bin/jinrender
chmod +x ~/.local/bin/jinrender
# Crypta - Gestión de secretos simplificada
curl -LO https://github.com/atareao/crypta/releases/download/v0.3.0/crypta-linux-x86_64
mv crypta-linux-x86_64 ~/.local/bin/crypta
chmod +x ~/.local/bin/crypta
# Starship - Mejora del prompt
curl -LO https://github.com/starship/starship/releases/download/v1.27.0/starship-x86_64-unknown-linux-musl.tar.gz
tar xzf starship-x86_64-unknown-linux-musl.tar.gz
mv starship ~/.local/bin/starship
chmod +x ~/.local/bin/starship
rm -f starship-x86_64-unknown-linux-musl.tar.gz
# yq (mikefarah) - Procesador YAML/JSON (binario estatico; ultima release + checksum)
curl -LO https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
curl -LO https://github.com/mikefarah/yq/releases/latest/download/checksums
curl -LO https://github.com/mikefarah/yq/releases/latest/download/checksums_hashes_order
# 'checksums' es una tabla multihash; SHA-256 es el campo (nº de linea de orden + 1)
COL=$(($(grep -n '^SHA-256$' checksums_hashes_order | cut -d: -f1) + 1))
EXPECTED=$(awk -v c="$COL" '$1=="yq_linux_amd64"{print $c}' checksums)
echo "$EXPECTED  yq_linux_amd64" | sha256sum -c -
mv yq_linux_amd64 ~/.local/bin/yq
chmod +x ~/.local/bin/yq
rm -f checksums checksums_hashes_order
# qctl - Gestión de quadlets (siempre la última release, binario estático + checksum)
curl -LO https://github.com/atareao/qctl/releases/latest/download/qctl-linux-x86_64
curl -LO https://github.com/atareao/qctl/releases/latest/download/qctl-linux-x86_64.sha256
sha256sum -c qctl-linux-x86_64.sha256
mv qctl-linux-x86_64 ~/.local/bin/qctl
chmod +x ~/.local/bin/qctl
rm -f qctl-linux-x86_64.sha256
mkdir -p ~/.config/fish/completions
~/.local/bin/qctl completions fish > ~/.config/fish/completions/qctl.fish
# Rust toolchain + nevi (editor en Rust; reemplaza a neovim)
if ! command -v cargo >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
. "$HOME/.cargo/env"
# --root ~/.local -> binario en ~/.local/bin/nevi
cargo install --git https://github.com/anthonyamaro15/nevi --root "$HOME/.local" --locked
# Hardening
chmod 700 ~/.local/bin
chmod 700 ~/.secrets
chmod 600 ~/.secrets/sops/age/key.txt
chmod 700 ~/.local/share/containers
chmod 700 ~/.gnupg
chmod 700 ~/.ssh
# Inicializar gestión de secretos
crypta init
# FQDN del host: NO es un secreto -> ~/.config/environment.d/fqdn.conf (systemd lo inyecta)
mkdir -p ~/.config/environment.d
echo "FQDN=$DOMINIO" > ~/.config/environment.d/fqdn.conf
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
