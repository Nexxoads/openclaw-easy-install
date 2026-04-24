#!/usr/bin/env bash
# OpenClaw Easy Installer — macOS / Linux / WSL2
# Requiere Docker instalado y el daemon en marcha

set -euo pipefail

write_step() { echo ""; echo "▶ $1"; }
write_ok()   { echo "  ✔ $1"; }
write_warn() { echo "  ⚠ $1"; }
write_fail() { echo "" >&2; echo "  ✖ ERROR: $1" >&2; exit 1; }

echo ""
echo "  OpenClaw — Instalador (macOS / Linux / WSL2)"
echo ""

INSTALL_DIR="${HOME}/openclaw-local"
DATA_DIR="${INSTALL_DIR}/data"
REPO_UNINSTALL="https://raw.githubusercontent.com/Nexxoads/openclaw-easy-install/main/uninstall.sh"

write_step "Comprobando Docker..."
if ! command -v docker &>/dev/null; then
  echo "" >&2
  echo "  ✖ Docker no está instalado." >&2
  echo "" >&2
  echo "  Instala Docker Desktop (Mac/Windows) o el motor de Docker (Linux) antes de continuar." >&2
  echo "  https://docs.docker.com/get-docker/" >&2
  echo "" >&2
  exit 1
fi
write_ok "Docker en PATH: $(docker --version 2>/dev/null || true)"

write_step "Comprobando que Docker está en marcha..."
if ! docker info &>/dev/null; then
  echo "" >&2
  echo "  ✖ Docker no responde. Abre Docker Desktop o arranca el servicio dockerd." >&2
  echo "" >&2
  exit 1
fi
write_ok "El daemon de Docker responde"

write_step "Comprobando Docker Compose..."
COMPOSE_V2=0
if docker compose version &>/dev/null; then
  write_ok "Docker Compose v2: $(docker compose version --short 2>/dev/null || echo ok)"
  COMPOSE_V2=1
elif command -v docker-compose &>/dev/null; then
  write_warn "Usando docker-compose v1. Considera actualizar Docker."
else
  write_fail "Docker Compose no encontrado. Actualiza Docker."
fi

write_step "Preparando el directorio de instalación..."
if [[ -d "$INSTALL_DIR" ]]; then
  write_warn "Ya existe una instalación en $INSTALL_DIR"
  read -r -p "  ¿Deseas sobreescribirla y reinstalar? [s/N] " confirm || true
  if [[ ! "${confirm:-}" =~ ^[sS]$ ]]; then
    echo ""
    echo "  Instalación cancelada. No se ha modificado la instalación existente."
    echo ""
    exit 0
  fi
  echo ""
fi

mkdir -p "$DATA_DIR"
cd "$INSTALL_DIR"
write_ok "Directorio: $INSTALL_DIR"

write_step "Generando docker-compose.yml..."
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  openclaw:
    image: phioranex/openclaw-docker:latest
    container_name: openclaw-local
    restart: unless-stopped
    ports:
      - "18789:18789"
    volumes:
      - ./data:/root/.openclaw
    environment:
      - NODE_ENV=production
EOF
write_ok "docker-compose.yml creado"

write_step "Descargando la imagen (puede tardar la primera vez)..."
if [[ "$COMPOSE_V2" -eq 1 ]]; then
  docker compose pull
  write_step "Arrancando OpenClaw..."
  docker compose up -d
else
  docker-compose pull
  write_step "Arrancando OpenClaw..."
  docker-compose up -d
fi

write_step "Verificando contenedor..."
sleep 3
if docker ps --filter "name=openclaw-local" --filter "status=running" --format '{{.Names}}' | grep -q .; then
  write_ok "Contenedor en ejecución"
else
  write_warn "El contenedor puede estar iniciando. Revisa con: docker ps -a && docker logs openclaw-local"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅  OpenClaw instalado (Docker en $INSTALL_DIR)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1) Onboarding (primera vez):"
echo "     docker exec -it openclaw-local node dist/index.js onboard --mode local --no-install-daemon"
echo ""
echo "  2) Logs:   docker logs -f openclaw-local"
echo "  3) Parar:  docker stop openclaw-local"
echo "  4) Inicio: docker start openclaw-local"
echo "  5) Desinstalar:"
echo "     curl -sSL $REPO_UNINSTALL | bash"
echo ""
echo "  Datos: $DATA_DIR"
echo "  Problemas: https://github.com/Nexxoads/openclaw-easy-install/issues"
echo ""
