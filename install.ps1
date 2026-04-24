# ==============================================================================
#  OpenClaw Easy Installer — Windows (PowerShell)
#  Proyecto comunitario - instalación con un solo comando
#  Compatibilidad: Windows 10/11 con Docker Desktop
# ==============================================================================

# Requiere PowerShell 5+ (incluido por defecto en Windows 10/11)
#Requires -Version 5.0

$ErrorActionPreference = "Stop"

# ── Colores ────────────────────────────────────────────────────────────────────
function Write-Step   { param($msg) Write-Host "`n▶ $msg" -ForegroundColor Cyan }
function Write-Ok     { param($msg) Write-Host "  ✔ $msg" -ForegroundColor Green }
function Write-Warn   { param($msg) Write-Host "  ⚠ $msg" -ForegroundColor Yellow }
function Write-Fail   { param($msg) Write-Host "`n  ✖ ERROR: $msg`n" -ForegroundColor Red; exit 1 }

# ── Banner ─────────────────────────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  ██████╗ ██████╗ ███████╗███╗   ██╗ ██████╗██╗      █████╗ ██╗    ██╗" -ForegroundColor Cyan
Write-Host " ██╔═══██╗██╔══██╗██╔════╝████╗  ██║██╔════╝██║     ██╔══██╗██║    ██║" -ForegroundColor Cyan
Write-Host " ██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║     ██║     ███████║██║ █╗ ██║" -ForegroundColor Cyan
Write-Host " ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██║     ██║     ██╔══██║██║███╗██║" -ForegroundColor Cyan
Write-Host " ╚██████╔╝██║     ███████╗██║ ╚████║╚██████╗███████╗██║  ██║╚███╔███╔╝" -ForegroundColor Cyan
Write-Host "  ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Instalador Comunitario — Sin configuración manual, sin complicaciones." -ForegroundColor White
Write-Host ""

# ── Detectar versión de Windows ────────────────────────────────────────────────
Write-Step "Detectando sistema operativo..."

$osVersion = [System.Environment]::OSVersion.Version
$caption   = (Get-WmiObject Win32_OperatingSystem).Caption

Write-Ok "Windows detectado: $caption (Build $($osVersion.Build))"

if ($osVersion.Build -lt 19041) {
    Write-Warn "Tu versión de Windows puede ser demasiado antigua para Docker Desktop con WSL2."
    Write-Host "  → Se recomienda Windows 10 versión 2004 (Build 19041) o superior." -ForegroundColor Yellow
    Write-Host "  → También puedes usar Docker con Hyper-V si está disponible." -ForegroundColor Yellow
}

# ── Comprobar arquitectura ─────────────────────────────────────────────────────
$arch = $env:PROCESSOR_ARCHITECTURE
Write-Ok "Arquitectura: $arch"

# ── Comprobar Docker ───────────────────────────────────────────────────────────
Write-Step "Comprobando que Docker está instalado..."

$dockerPath = Get-Command docker -ErrorAction SilentlyContinue

if (-not $dockerPath) {
    Write-Host ""
    Write-Host "  ✖ Docker no está instalado." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Por favor, instala Docker Desktop antes de continuar:" -ForegroundColor White
    Write-Host "  → https://docs.docker.com/desktop/install/windows-install/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Pasos recomendados:" -ForegroundColor White
    Write-Host "    1. Descarga Docker Desktop desde el enlace de arriba"
    Write-Host "    2. Durante la instalación, activa la opción 'Use WSL 2 instead of Hyper-V'"
    Write-Host "    3. Reinicia el ordenador si se solicita"
    Write-Host "    4. Abre Docker Desktop y espera a que arranque"
    Write-Host "    5. Vuelve a ejecutar este script"
    Write-Host ""
    exit 1
}

$dockerVersion = docker --version
Write-Ok "Docker encontrado: $dockerVersion"

# ── Comprobar que el daemon está corriendo ─────────────────────────────────────
Write-Step "Comprobando que Docker está en marcha..."

try {
    $null = docker info 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Docker no responde" }
    Write-Ok "Docker Desktop está corriendo"
} catch {
    Write-Host ""
    Write-Host "  ✖ Docker está instalado pero no está arrancado." -ForegroundColor Red
    Write-Host ""
    Write-Host "  → Busca 'Docker Desktop' en el menú Inicio y ábrelo." -ForegroundColor Yellow
    Write-Host "  → Espera a que el icono de la ballena en la barra de tareas deje de animarse." -ForegroundColor Yellow
    Write-Host "  → Luego vuelve a ejecutar este script." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# ── Comprobar Docker Compose ───────────────────────────────────────────────────
Write-Step "Comprobando Docker Compose..."

$composeCmd = $null

try {
    $null = docker compose version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $composeVersion = docker compose version --short
        Write-Ok "Docker Compose v2 disponible: $composeVersion"
        $composeCmd = "docker compose"
    }
} catch {}

if (-not $composeCmd) {
    $legacyCompose = Get-Command docker-compose -ErrorAction SilentlyContinue
    if ($legacyCompose) {
        Write-Warn "Usando docker-compose v1. Considera actualizar Docker Desktop."
        $composeCmd = "docker-compose"
    } else {
        Write-Fail "Docker Compose no encontrado. Actualiza Docker Desktop a la versión más reciente."
    }
}

# ── Crear directorio de instalación ───────────────────────────────────────────
$installDir = Join-Path $env:USERPROFILE "openclaw-local"
$dataDir    = Join-Path $installDir "data"

Write-Step "Preparando el directorio de instalación..."

if (Test-Path $installDir) {
    Write-Warn "Ya existe una instalación en $installDir"
    Write-Host ""
    $confirm = Read-Host "  ¿Deseas sobreescribirla y reinstalar? [s/N]"
    if ($confirm -notmatch '^[sS]$') {
        Write-Host ""
        Write-Host "  Instalación cancelada. Tu instalación existente no ha sido tocada." -ForegroundColor Yellow
        Write-Host ""
        exit 0
    }
    Write-Host ""
}

New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
Set-Location $installDir
Write-Ok "Directorio creado en: $installDir"

# ── Crear docker-compose.yml ───────────────────────────────────────────────────
Write-Step "Generando fichero de configuración..."

$composeContent = @"
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
"@

$composeContent | Out-File -FilePath (Join-Path $installDir "docker-compose.yml") -Encoding UTF8
Write-Ok "docker-compose.yml creado"

# ── Descargar imagen y arrancar ────────────────────────────────────────────────
Write-Step "Descargando imagen de OpenClaw (puede tardar unos minutos la primera vez)..."

Set-Location $installDir

if ($composeCmd -eq "docker compose") {
    docker compose pull
    Write-Step "Arrancando OpenClaw..."
    docker compose up -d
} else {
    docker-compose pull
    Write-Step "Arrancando OpenClaw..."
    docker-compose up -d
}

# ── Verificar que el contenedor está corriendo ─────────────────────────────────
Write-Step "Verificando que OpenClaw está funcionando..."

Start-Sleep -Seconds 3

$running = docker ps --filter "name=openclaw-local" --filter "status=running" | Select-String "openclaw-local"

if ($running) {
    Write-Ok "Contenedor arrancado y corriendo"
} else {
    Write-Warn "El contenedor puede estar tardando en inicializarse."
    Write-Host "  Comprueba el estado con:" -ForegroundColor Yellow
    Write-Host "    docker ps -a" -ForegroundColor White
    Write-Host "    docker logs openclaw-local" -ForegroundColor White
}

# ── Instrucciones finales ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  ✅  ¡OpenClaw está instalado y funcionando en tu máquina!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "  📋 Próximos pasos:" -ForegroundColor White
Write-Host ""
Write-Host "  1. Configura OpenClaw (solo la primera vez):" -ForegroundColor Cyan
Write-Host "     docker exec -it openclaw-local node dist/index.js onboard --mode local --no-install-daemon"
Write-Host ""
Write-Host "  2. Ver los logs en tiempo real:" -ForegroundColor Cyan
Write-Host "     docker logs -f openclaw-local"
Write-Host ""
Write-Host "  3. Parar OpenClaw:" -ForegroundColor Cyan
Write-Host "     docker stop openclaw-local"
Write-Host ""
Write-Host "  4. Volver a arrancar:" -ForegroundColor Cyan
Write-Host "     docker start openclaw-local"
Write-Host ""
Write-Host "  5. Desinstalar completamente:" -ForegroundColor Cyan
Write-Host "     irm https://raw.githubusercontent.com/Nexxoads/openclaw-easy-install/main/uninstall.ps1 | iex"
Write-Host ""
Write-Host "  📁 Tus datos están guardados en: $installDir\data" -ForegroundColor White
Write-Host ""
Write-Host "  ¿Problemas? Abre un issue en:" -ForegroundColor Yellow
Write-Host "  https://github.com/Nexxoads/openclaw-easy-install/issues"
Write-Host ""
