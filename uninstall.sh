#!/bin/bash

# ==============================================================================
#  OpenClaw Easy Uninstaller
#  Elimina el contenedor, la imagen y los archivos de configuración
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${RED}${BOLD}  OpenClaw — Desinstalador${NC}"
echo ""
echo -e "  ${YELLOW}Este proceso eliminará:${NC}"
echo "  • El contenedor Docker 'openclaw-local'"
echo "  • La imagen Docker descargada"
echo "  • El directorio $HOME/openclaw-local (¡incluyendo tus datos!)"
echo ""
# Leer desde /dev/tty para que funcione tanto con curl|bash como ejecutando el script directamente
read -r -p "  ¿Estás seguro de que quieres desinstalar OpenClaw? [s/N]: " CONFIRM </dev/tty

if [[ ! "$CONFIRM" =~ ^[sS]$ ]]; then
    echo ""
    echo "  Desinstalación cancelada."
    echo ""
    exit 0
fi

echo ""

# Parar y eliminar el contenedor
if docker ps -a --filter "name=openclaw-local" | grep -q openclaw-local; then
    echo -e "  ${CYAN}▶ Parando y eliminando el contenedor...${NC}"
    docker stop openclaw-local 2>/dev/null || true
    docker rm openclaw-local 2>/dev/null || true
    echo -e "  ${GREEN}✔ Contenedor eliminado${NC}"
else
    echo -e "  ${YELLOW}⚠ No se encontró el contenedor 'openclaw-local'${NC}"
fi

# Eliminar la imagen
if docker images ghcr.io/openclaw/openclaw | grep -q "openclaw"; then
    echo -e "  ${CYAN}▶ Eliminando imagen Docker...${NC}"
    docker rmi ghcr.io/openclaw/openclaw:latest 2>/dev/null || true
    echo -e "  ${GREEN}✔ Imagen eliminada${NC}"
else
    echo -e "  ${YELLOW}⚠ No se encontró la imagen Docker${NC}"
fi

# Eliminar el directorio de datos
INSTALL_DIR="$HOME/openclaw-local"
if [ -d "$INSTALL_DIR" ]; then
    echo -e "  ${CYAN}▶ Eliminando archivos locales...${NC}"
    rm -rf "$INSTALL_DIR"
    echo -e "  ${GREEN}✔ Directorio $INSTALL_DIR eliminado${NC}"
else
    echo -e "  ${YELLOW}⚠ No se encontró el directorio $INSTALL_DIR${NC}"
fi

echo ""
echo -e "${GREEN}${BOLD}  ✅ OpenClaw ha sido desinstalado completamente.${NC}"
echo ""
