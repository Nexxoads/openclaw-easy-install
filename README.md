# 🦞 OpenClaw — Instalador Comunitario

Instala [OpenClaw](https://openclaw.ai/) en tu máquina local **con un solo comando**. Sin tocar archivos de configuración, sin conocimientos de Docker.

> Proyecto comunitario sin ánimo de lucro. No oficial.

---

## ✅ Requisitos previos

Solo necesitas tener instalado **Docker Desktop**:

| Sistema | Enlace de descarga |
|---|---|
| macOS | https://docs.docker.com/desktop/install/mac-install/ |
| Windows (WSL2) | https://docs.docker.com/desktop/install/windows-install/ |
| Linux (Ubuntu/Debian) | https://docs.docker.com/engine/install/ubuntu/ |

> **Windows:** asegúrate de usar **WSL2** (no PowerShell ni CMD).  
> Guía de instalación de WSL2: https://learn.microsoft.com/es-es/windows/wsl/install

---

## 🚀 Instalación (1 solo comando)

Abre tu terminal, asegúrate de que Docker Desktop está abierto y ejecuta:

```bash
curl -sSL https://raw.githubusercontent.com/nexxoads/openclaw-easy-install/main/install.sh | bash
```

El script hará todo automáticamente:
- ✔ Comprueba que Docker está instalado y en marcha
- ✔ Crea el directorio `~/openclaw-local` con tus datos
- ✔ Descarga la imagen oficial de OpenClaw
- ✔ Arranca el contenedor con `restart: unless-stopped`
- ✔ Muestra las instrucciones de uso al terminar

---

## 📋 Después de instalar

**Configuración inicial (solo la primera vez):**
```bash
docker exec -it openclaw-local node dist/index.js onboard --mode local --no-install-daemon
```

**Comandos útiles del día a día:**

```bash
# Ver si está corriendo
docker ps --filter name=openclaw-local

# Ver logs en tiempo real
docker logs -f openclaw-local

# Parar OpenClaw
docker stop openclaw-local

# Volver a arrancar
docker start openclaw-local

# Reiniciar
docker restart openclaw-local
```

---

## 🗑️ Desinstalación

Para eliminar OpenClaw completamente (contenedor, imagen y datos):

```bash
curl -sSL https://raw.githubusercontent.com/nexxoads/openclaw-easy-install/main/uninstall.sh | bash
```

> ⚠️ Esto eliminará también tus datos en `~/openclaw-local/data`. Haz una copia antes si los necesitas.

---

## 🗂️ Estructura de archivos

```
~/openclaw-local/
├── docker-compose.yml   ← Configuración de Docker
└── data/                ← Tus datos de OpenClaw (persistentes)
```

---

## 🐛 Solución de problemas

**Docker no arranca el contenedor:**
```bash
docker logs openclaw-local
```

**El puerto 18789 ya está en uso:**
Edita `~/openclaw-local/docker-compose.yml` y cambia `"18789:18789"` por otro puerto, por ejemplo `"18790:18789"`. Luego reinicia con:
```bash
cd ~/openclaw-local && docker compose up -d
```

**En WSL2, Docker Desktop no está conectado:**  
Abre Docker Desktop → Settings → Resources → WSL Integration → activa tu distro de Linux.

---

## 🤝 Contribuir

¿Encontraste un bug? ¿Tienes una mejora? Abre un [Issue](https://github.com/nexxoads/openclaw-easy-install/issues) o un Pull Request. Este es un proyecto para la comunidad, hecho con mucho gusto.

---

## ⚠️ Aviso legal

Este instalador no está afiliado oficialmente con los desarrolladores de OpenClaw. Es un proyecto comunitario independiente que facilita la instalación del software original. Todos los créditos de OpenClaw son de sus autores originales.
