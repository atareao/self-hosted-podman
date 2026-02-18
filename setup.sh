#!/bin/bash

# --- CONFIGURACIÓN ---
NUEVO_USUARIO="admin"
USUARIO_APPS="apps"
NUEVO_PUERTO_SSH="2222"
DOMINIO="tudominio.es"

# CONTRASEÑAS (Cámbialas por unas seguras)
PASS_ADMIN="ContraseñaSeguraAdmin123!"
PASS_APPS="ContraseñaSeguraApps456!"

# PEGA AQUÍ TU CLAVE PÚBLICA
MI_CLAVE_PUBLICA="tu_clave_publica_aqui"

# Actualización y Dependencias
apt update && apt upgrade -y
apt install -y ufw fail2ban libpam-tmpdir needrestart unattended-upgrades libcap2-bin
# Herramientas para podman y otras utilidades
install - y git ansifilter yadm age yq jq batcat zoxide neovim apache2-utils fish podman
# Crear admin, asignar pass y desbloquear
useradd -m -s /bin/bash "$NUEVO_USUARIO"
echo "$NUEVO_USUARIO:$PASS_ADMIN" | chpasswd
usermod -aG sudo "$NUEVO_USUARIO"
echo "$NUEVO_USUARIO ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/90-admin-user

# Configurar SSH Key para admin (Esto permite el acceso)
mkdir -p /home/"$NUEVO_USUARIO"/.ssh
echo "$MI_CLAVE_PUBLICA" > /home/"$NUEVO_USUARIO"/.ssh/authorized_keys
chown -R "$NUEVO_USUARIO":"$NUEVO_USUARIO" /home/"$NUEVO_USUARIO"/.ssh
chmod 700 /home/"$NUEVO_USUARIO"/.ssh
chmod 600 /home/"$NUEVO_USUARIO"/.ssh/authorized_keys

# Crear usuario apps y asignar pass
useradd -m -s /bin/bash "$USUARIO_APPS"
echo "$USUARIO_APPS:$PASS_APPS" | chpasswd

# Hardening del Kernel (Sysctl)
cat <<EOF >> /etc/sysctl.d/99-hardening.conf
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.ip_unprivileged_port_start=80
kernel.kptr_restrict = 2
kernel.perf_event_paranoid = 3
net.core.rmem_max=2500000
net.core.wmem_max=2500000
EOF
sysctl -p /etc/sysctl.d/99-hardening.conf

# Hardening de SSH (ESTRICTO: Solo llave, sin password)
cat <<EOF > /etc/ssh/sshd_config.d/hardening.conf
Port $NUEVO_PUERTO_SSH
PermitRootLogin no
MaxAuthTries 3
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM no
AllowUsers $NUEVO_USUARIO
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
EOF
systemctl restart ssh
systemctl daemon-reload
systemctl restart ssh.socket

# Fail2Ban con Baneo Agresivo (24h)
cat <<EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
port = $NUEVO_PUERTO_SSH
maxretry = 2
bantime = 24h
findtime = 1h
EOF
systemctl restart fail2ban

# Firewall (UFW) - Soporte HTTP/3
ufw default deny incoming
ufw default allow outgoing
ufw allow "$NUEVO_PUERTO_SSH"/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 443/udp
ufw --force enable

echo "--------------------------------------------------------"
echo "SERVIDOR LISTO Y PROTEGIDO"
echo "Usuario '$NUEVO_USUARIO' desbloqueado y con sudo."
echo "Usuario '$USUARIO_APPS' listo para apps."
echo "SSH configurado en puerto $NUEVO_PUERTO_SSH (Solo llave)."
echo "--------------------------------------------------------"
