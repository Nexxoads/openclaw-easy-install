#!/usr/bin/env bash
# OpenClaw — Desinstalador (macOS / Linux / WSL2)

set -euo pipefail

echo ""
echo "  OpenClaw — Desinstalador (Unix)"
echo ""
echo "  Se eliminará:"
echo "  • Contenedor 'openclaw-local'"
echo "  • Imagen phioranex/openclaw-docker (si existe localmente)"
echo "  • directorio $HOME/openclaw-local (incluye tus datos)"
echo ""
read -r -p "  ¿Desinstalar OpenClaw? [s/N] " confirm || true
if [[ ! "${confirm:-}" =~ ^[sS]$ ]]; then
  echo ""
  echo "  Desinstalación cancelada."
  echo ""
  exit 0
fi

echo ""
if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q '^openclaw-local$'; then
  echo "  ▶ Eliminando contenedor..."
  docker stop openclaw-local 2>/dev/null || true
  docker rm openclaw-local 2>/dev/null || true
  echo "  ✔ Contenedor eliminado"
else
  echo "  ⚠ No se encontró el contenedor 'openclaw-local'"
fi

if docker images -q phioranex/openclaw-docker 2>/dev/null | grep -q .; then
  echo "  ▶ Eliminando imagen..."
  docker rmi phioranex/openclaw-docker:latest 2>/dev/null || true
  echo "  ✔ Imagen eliminada (si no la usa otro contenedor)"
else
  echo "  ⚠ No se encontró la imagen en local"
fi

INSTALL_DIR="${HOME}/openclaw-local"
if [[ -d "$INSTALL_DIR" ]]; then
  echo "  ▶ Eliminando $INSTALL_DIR..."
  rm -rf "$INSTALL_DIR"
  echo "  ✔ Directorio eliminado"
else
  echo "  ⚠ No se encontró $INSTALL_DIR"
fi

echo ""
echo "  ✅ Desinstalación completada."
echo ""
