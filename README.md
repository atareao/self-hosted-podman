# 🐋 Self-Hosted Podman Infrastructure

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Podman](https://img.shields.io/badge/Podman-892CA0?style=flat&logo=podman&logoColor=white)](https://podman.io/)
[![Traefik](https://img.shields.io/badge/Traefik-24A1C1?style=flat&logo=traefikproxy&logoColor=white)](https://traefik.io/)
[![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black)](https://www.linux.org/)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat&logo=github&logoColor=white)](https://github.com/atareao/self-hosted-podman)

> **Infraestructura completa de auto-alojamiento usando Podman con gestión automática de secretos y configuración declarativa.**

Una solución robusta y segura para desplegar servicios auto-alojados utilizando Podman, con autenticación OIDC integrada, proxy reverso automático y gestión de secretos cifrados.

## 🚀 Características

- ✅ **Gestión de contenedores**: Basado en Podman para máxima seguridad
- ✅ **Proxy reverso automático**: Traefik con SSL/TLS automático
- ✅ **Autenticación OIDC**: PocketID para autenticación centralizada
- ✅ **Gestión de secretos**: Cifrado con SOPS y AGE
- ✅ **Configuración declarativa**: Dotfiles gestionados con YADM
- ✅ **Templating**: Jinrender para configuración dinámica

## 📋 Requisitos

### Herramientas necesarias

| Herramienta       | Descripción                          | Instalación                      |
| ----------------- | ------------------------------------ | -------------------------------- |
| **git**           | Control de versiones                 | `sudo apt install git`           |
| **ansifilter**    | Para los journals                    | `sudo apt install ansifilter`    |
| **yadm**          | Gestor de dotfiles                   | `sudo apt install yadm`          |
| **sops**          | Cifrado de secretos                  | Manual (ver abajo)               |
| **age**           | Cifrado moderno                      | `sudo apt install age`           |
| **yq**            | Procesador YAML/JSON                 | `sudo apt install yq`            |
| **jinrender**     | Motor de templates                   | Manual (ver abajo)               |
| **crypta**        | Gestión de secretos                  | Manual (ver abajo)               |
| **bat**           | Visualizador de archivos mejorado    | `sudo apt install batcat`        |
| **jq**            | Procesador JSON                      | `sudo apt install jq`            |
| **zoxide**        | Navegador de directorios inteligente | `sudo apt install zoxide`        |
| **neovim**        | Editor de texto avanzado             | `sudo apt install neovim`        |
| **apache2-utils** | Utilidades web (htpasswd)            | `sudo apt install apache2-utils` |
| **starship**      | Prompt personalizable                | Manual (ver abajo)               |
| **fish**          | Shell interactivo amigable           | `sudo apt install fish`          |
| **podman**        | Motor de contenedores                | `sudo apt install podman`        |

## 🔧 Instalación

### 1. Instalar dependencias del sistema

```bash
sudo apt update && sudo apt install git ansifilter yadm age yq jq batcat zoxide neovim apache2-utils fish podman
mkdir -p ~/.local/bin
```

### 2. Instalar herramientas adicionales

```bash
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
curl -LO https://github.com/starship/starship/releases/download/v1.27.0/starship-i686-unknown-linux-musl.tar.gz -o starship.tar.gz
tar xvzf starship.tar.gz
mv starship ~/.local/bin/starship
chmod +x ~/.local/bin/starship
```

## 🛠️ Configuración inicial

### 1. Inicializar el entorno

```bash
# Inicializar gestión de secretos
crypta init

# Configurar dotfiles con YADM
yadm init
yadm remote add origin https://github.com/atareao/self-hosted-podman.git
yadm pull
yadmalt
```

### 2. Configurar dominio

> ⚠️ **Importante**: Configura tu FQDN antes de continuar

```bash
crypta set --key fqdn --value "tudominio.com"
```

### 3. Generar configuración

```bash
# Aplicar templates con las variables configuradas
unjinja
```

### 4. Iniciar servicios base

```bash
systemctl --user daemon-reload
systemctl --user start traefik wordpress pocketid
```

## 🔐 Configuración de autenticación

### 1. Configurar PocketID

1. Navega a `https://auth.tudominio.com/setup`
2. Configura usuario y credenciales administrativas
3. Añade **Traefik** como cliente OIDC con:
   - **Nombre del cliente**: `traefik`
   - **URL de callback**: `https://*.tudominio.com/oidc/callback`
   - **Grupos permitidos**: `Sin restricciones`

### 2. Configurar credenciales OIDC

```bash
# Generar secreto aleatorio
openssl rand -hex 16 | crypta store oidc_secret

# Almacenar credenciales de PocketID (reemplaza con valores reales)
echo "tu-client-id" | crypta store oidc_client_id
echo "tu-client-secret" | crypta store oidc_client_secret

# Aplicar configuración actualizada
unjinja

# Reiniciar Traefik
systemctl --user restart traefik
```

## 🌐 Acceso a servicios

Una vez completada la configuración:

| Servicio              | URL                               | Descripción                |
| --------------------- | --------------------------------- | -------------------------- |
| **Traefik Dashboard** | `https://traefik.tudominio.com`   | Panel de control del proxy |
| **PocketID**          | `https://auth.tudominio.com`      | Servidor de autenticación  |
| **WordPress**         | `https://blog.tudominio.com` | Sitio web principal        |

## 📚 Documentación adicional

- [Configuración automática](Auto.md)
- [Guía de resolución de problemas](#)
- [Añadir nuevos servicios](#)

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Añadir nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crea un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.

---

<div align="center">
  <b>Hecho con ❤️ para la comunidad de auto-alojamiento</b>
</div>
