# ==============================================================================
#  OpenClaw Easy Uninstaller — Windows (PowerShell)
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "  OpenClaw — Desinstalador (Windows)" -ForegroundColor Red
Write-Host ""
Write-Host "  Este proceso eliminará:" -ForegroundColor Yellow
Write-Host "  • El contenedor Docker 'openclaw-local'"
Write-Host "  • La imagen Docker descargada"
Write-Host "  • El directorio $env:USERPROFILE\openclaw-local (¡incluyendo tus datos!)"
Write-Host ""
$confirm = Read-Host "  ¿Estás seguro de que quieres desinstalar OpenClaw? [s/N]"

if ($confirm -notmatch '^[sS]$') {
    Write-Host ""
    Write-Host "  Desinstalación cancelada." -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

Write-Host ""

# Parar y eliminar contenedor
$container = docker ps -a --filter "name=openclaw-local" | Select-String "openclaw-local"
if ($container) {
    Write-Host "  ▶ Parando y eliminando el contenedor..." -ForegroundColor Cyan
    docker stop openclaw-local 2>$null
    docker rm   openclaw-local 2>$null
    Write-Host "  ✔ Contenedor eliminado" -ForegroundColor Green
} else {
    Write-Host "  ⚠ No se encontró el contenedor 'openclaw-local'" -ForegroundColor Yellow
}

# Eliminar imagen
$image = docker images phioranex/openclaw-docker | Select-String "openclaw-docker"
if ($image) {
    Write-Host "  ▶ Eliminando imagen Docker..." -ForegroundColor Cyan
    docker rmi phioranex/openclaw-docker:latest 2>$null
    Write-Host "  ✔ Imagen eliminada" -ForegroundColor Green
} else {
    Write-Host "  ⚠ No se encontró la imagen Docker" -ForegroundColor Yellow
}

# Eliminar directorio
$installDir = Join-Path $env:USERPROFILE "openclaw-local"
if (Test-Path $installDir) {
    Write-Host "  ▶ Eliminando archivos locales..." -ForegroundColor Cyan
    Remove-Item -Recurse -Force $installDir
    Write-Host "  ✔ Directorio eliminado" -ForegroundColor Green
} else {
    Write-Host "  ⚠ No se encontró el directorio $installDir" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  ✅ OpenClaw ha sido desinstalado completamente." -ForegroundColor Green
Write-Host ""
