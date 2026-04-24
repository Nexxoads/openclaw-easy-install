#!/bin/bash

# ==============================================================================
#  OpenClaw Easy Installer — Proyecto Comunitario
#  Imagen oficial: ghcr.io/openclaw/openclaw:latest
#  Fuente: https://github.com/openclaw/openclaw
#  Compatibilidad: macOS, Linux (Ubuntu/Debian), Windows (WSL2)
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${CYAN}${BOLD}"
echo "  ██████╗ ██████╗ ███████╗███╗   ██╗ ██████╗██╗      █████╗ ██╗    ██╗"
echo " ██╔═══██╗██╔══██╗██╔════╝████╗  ██║██╔════╝██║     ██╔══██╗██║    ██║"
echo " ██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║     ██║     ███████║██║ █╗ ██║"
echo " ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██║     ██║     ██╔══██║██║███╗██║"
echo " ╚██████╔╝██║     ███████╗██║ ╚████║╚██████╗███████╗██║  ██║╚███╔███╔╝"
echo "  ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝ "
echo -e "${NC}"
echo -e "${BOLD}  Instalador Comunitario — openclaw.ai${NC}"
echo ""

print_step()  { echo -e "\n${CYAN}${BOLD}▶ $1${NC}"; }
print_ok()    { echo -e "  ${GREEN}✔ $1${NC}"; }
print_warn()  { echo -e "  ${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "\n  ${RED}✖ ERROR: $1${NC}\n"; exit 1; }

# ── Detectar OS ────────────────────────────────────────────────────────────────
print_step "Detectando sistema operativo..."

OS="unknown"
if grep -qi microsoft /proc/version 2>/dev/null; then
    OS="wsl"
    print_ok "Windows WSL2 detectado"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    # Detectar arquitectura Apple Silicon vs Intel
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        print_ok "macOS detectado (Apple Silicon M1/M2/M3)"
    else
        print_ok "macOS detectado (Intel)"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        print_ok "Linux detectado: ${PRETTY_NAME}"
    else
        print_ok "Linux detectado"
    fi
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    print_error "Estás usando Git Bash/Cygwin. Usa WSL2:\nhttps://learn.microsoft.com/es-es/windows/wsl/install"
else
    print_warn "Sistema no identificado, continuando como Linux..."
    OS="linux"
fi

# ── Comprobar Docker ───────────────────────────────────────────────────────────
print_step "Comprobando Docker..."

if ! command -v docker &>/dev/null; then
    echo ""
    echo -e "  ${RED}✖ Docker no está instalado.${NC}"
    echo ""
    case "$OS" in
        macos) echo "  → https://docs.docker.com/desktop/install/mac-install/" ;;
        wsl)
            echo "  → https://docs.docker.com/desktop/install/windows-install/"
            echo "    Luego: Docker Desktop → Settings → Resources → WSL Integration → activa tu distro"
            ;;
        *)
            echo "  → https://docs.docker.com/engine/install/ubuntu/"
            echo "  → Atajo: curl -fsSL https://get.docker.com | sh && sudo usermod -aG docker \$USER"
            ;;
    esac
    echo ""
    exit 1
fi

print_ok "Docker en PATH: $(docker --version)"

# ── Comprobar daemon ───────────────────────────────────────────────────────────
print_step "Comprobando que Docker está en marcha..."

if ! docker info &>/dev/null; then
    echo ""
    echo -e "  ${RED}✖ Docker no responde.${NC}"
    echo ""
    case "$OS" in
        macos|wsl)
            echo "  → Abre Docker Desktop y espera a que el icono de la ballena"
            echo "    en la barra de menú/tareas deje de animarse."
            ;;
        *)
            echo "  → sudo systemctl start docker"
            echo "  → Si falla: sudo systemctl enable docker && sudo systemctl start docker"
            ;;
    esac
    echo ""
    exit 1
fi

print_ok "El daemon de Docker responde"

# ── Comprobar Docker Compose ───────────────────────────────────────────────────
print_step "Comprobando Docker Compose..."

if docker compose version &>/dev/null 2>&1; then
    COMPOSE_VER=$(docker compose version --short 2>/dev/null || echo "v2")
    print_ok "Docker Compose v2: $COMPOSE_VER"
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &>/dev/null; then
    print_warn "docker-compose v1 encontrado (considera actualizar Docker Desktop)"
    COMPOSE_CMD="docker-compose"
else
    print_error "Docker Compose no encontrado. Actualiza Docker Desktop."
fi

# ── Directorio de instalación ──────────────────────────────────────────────────
INSTALL_DIR="$HOME/openclaw-local"
print_step "Preparando el directorio de instalación..."

if [ -d "$INSTALL_DIR" ]; then
    print_warn "Ya existe una instalación en $INSTALL_DIR"
    echo ""
    read -r -p "  ¿Reinstalar? Los datos en ./data se conservarán [s/N]: " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[sS]$ ]]; then
        echo ""
        echo "  Cancelado. Tu instalación no fue tocada."
        echo ""
        exit 0
    fi
    echo ""
fi

mkdir -p "$INSTALL_DIR/data/workspace"
cd "$INSTALL_DIR"
print_ok "Directorio: $INSTALL_DIR"

# ── Generar/conservar token ────────────────────────────────────────────────────
print_step "Configurando token de seguridad..."

ENV_FILE="$INSTALL_DIR/.env"

if [ -f "$ENV_FILE" ] && grep -q "OPENCLAW_GATEWAY_TOKEN" "$ENV_FILE" 2>/dev/null; then
    print_ok "Token existente conservado"
else
    if command -v openssl &>/dev/null; then
        GATEWAY_TOKEN=$(openssl rand -hex 32)
    else
        GATEWAY_TOKEN=$(LC_ALL=C tr -dc 'a-f0-9' < /dev/urandom | head -c 64)
    fi

    # Escribir .env con todas las variables que usa el compose oficial
    cat > "$ENV_FILE" << EOF
# OpenClaw Easy Installer — generado automáticamente
# Más info: https://openclaw.ai / https://github.com/openclaw/openclaw

OPENCLAW_IMAGE=ghcr.io/openclaw/openclaw:latest
OPENCLAW_GATEWAY_TOKEN=${GATEWAY_TOKEN}
OPENCLAW_CONFIG_DIR=${INSTALL_DIR}/data
OPENCLAW_WORKSPACE_DIR=${INSTALL_DIR}/data/workspace
OPENCLAW_TZ=$(cat /etc/timezone 2>/dev/null || echo "UTC")
EOF

    print_ok "Token generado y guardado en .env"
fi

# ── Crear docker-compose.yml (alineado con el oficial) ─────────────────────────
print_step "Generando docker-compose.yml..."

cat > docker-compose.yml << 'EOF'
# OpenClaw Easy Installer
# Imagen oficial: https://github.com/openclaw/openclaw/pkgs/container/openclaw

services:
  openclaw-gateway:
    image: ${OPENCLAW_IMAGE:-ghcr.io/openclaw/openclaw:latest}
    container_name: openclaw-local
    restart: unless-stopped
    ports:
      - "18789:18789"
    environment:
      HOME: /home/node
      TERM: xterm-256color
      OPENCLAW_GATEWAY_TOKEN: ${OPENCLAW_GATEWAY_TOKEN:-}
      TZ: ${OPENCLAW_TZ:-UTC}
    volumes:
      - ${OPENCLAW_CONFIG_DIR}:/home/node/.openclaw
      - ${OPENCLAW_WORKSPACE_DIR}:/home/node/.openclaw/workspace
    healthcheck:
      test: ["CMD", "curl", "-fsS", "http://127.0.0.1:18789/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
EOF

print_ok "docker-compose.yml creado"

# ── Pull & up ──────────────────────────────────────────────────────────────────
print_step "Descargando imagen oficial (ghcr.io/openclaw/openclaw:latest)..."
print_warn "Puede tardar unos minutos la primera vez (~500MB)"

$COMPOSE_CMD pull

print_step "Arrancando OpenClaw..."

$COMPOSE_CMD up -d

# ── Verificar salud ────────────────────────────────────────────────────────────
print_step "Verificando que OpenClaw está en marcha..."

echo "  Esperando a que el servicio arranque..."
MAX_WAIT=30
COUNT=0
while [ $COUNT -lt $MAX_WAIT ]; do
    if curl -fsS http://127.0.0.1:18789/healthz &>/dev/null; then
        print_ok "OpenClaw responde en http://127.0.0.1:18789 ✓"
        break
    fi
    sleep 2
    COUNT=$((COUNT + 2))
done

if [ $COUNT -ge $MAX_WAIT ]; then
    print_warn "El servicio tarda en responder. Puede estar arrancando aún."
    echo "  Comprueba con: docker logs openclaw-local"
fi

# ── Leer token para mostrarlo ──────────────────────────────────────────────────
TOKEN_VALUE=$(grep "^OPENCLAW_GATEWAY_TOKEN=" "$ENV_FILE" | cut -d'=' -f2)

# ── Resumen final ──────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}  ✅  ¡OpenClaw instalado y funcionando!${NC}"
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}🌐 Panel de control:${NC}"
echo -e "     ${CYAN}http://127.0.0.1:18789${NC}"
echo ""
echo -e "  ${BOLD}🔑 Tu token de acceso:${NC}"
echo -e "     ${YELLOW}${TOKEN_VALUE}${NC}"
echo "     (Pégalo en Settings del panel de control)"
echo "     (Guardado en: $ENV_FILE)"
echo ""
echo -e "  ${BOLD}⚙️  Configuración inicial (solo una vez):${NC}"
echo "     docker exec -it openclaw-local node dist/index.js onboard --mode local --no-install-daemon"
echo ""
echo -e "  ${BOLD}📋 Comandos del día a día:${NC}"
echo "     docker logs -f openclaw-local      # logs en tiempo real"
echo "     docker stop openclaw-local         # parar"
echo "     docker start openclaw-local        # arrancar"
echo "     docker restart openclaw-local      # reiniciar"
echo "     cd $INSTALL_DIR && $COMPOSE_CMD pull && $COMPOSE_CMD up -d  # actualizar"
echo ""
echo -e "  ${BOLD}🗑️  Desinstalar:${NC}"
echo "     curl -sSL https://raw.githubusercontent.com/nexxoads/openclaw-easy-install/main/uninstall.sh | bash"
echo ""
echo -e "  ${BOLD}📁 Datos:${NC} $INSTALL_DIR/data"
echo -e "  ${BOLD}📖 Docs:${NC} https://docs.openclaw.ai"
echo ""
echo -e "  ${YELLOW}¿Problemas?${NC} https://github.com/nexxoads/openclaw-easy-install/issues"
echo ""
