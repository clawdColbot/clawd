#!/bin/bash
#==============================================================================
# install-clawdbot-pi.sh - Instalación completa de Clawdbot en Raspberry Pi
# Para asistente de voz local con integración SmartThings/Home Assistant
#==============================================================================

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "=========================================="
echo "🦊  CLAWDBOT PI INSTALLER"
echo "   Smart Home Voice Assistant"
echo "=========================================="
echo ""

# Verificar arquitectura
if [[ "$(uname -m)" != "aarch64" ]]; then
    log_warn "Este script está optimizado para Raspberry Pi 64-bit"
    log_warn "Arquitectura detectada: $(uname -m)"
    read -p "¿Continuar de todos modos? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 1. Actualizar sistema
log_info "Actualizando sistema..."
sudo apt-get update && sudo apt-get upgrade -y
log_success "Sistema actualizado"

# 2. Instalar dependencias
log_info "Instalando dependencias..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    alsa-utils \
    libasound2-dev \
    libportaudio2 \
    libatlas-base-dev \
    ffmpeg \
    portaudio19-dev \
    sox \
    libsox-fmt-all

log_success "Dependencias instaladas"

# 3. Instalar Node.js 22+
log_info "Instalando Node.js 22..."
if ! command -v node &> /dev/null || [[ "$(node -v | cut -d'v' -f2 | cut -d'.' -f1)" -lt 22 ]]; then
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi
log_success "Node.js $(node -v) instalado"

# 4. Instalar Clawdbot
log_info "Instalando Clawdbot..."
sudo npm install -g clawdbot
log_success "Clawdbot instalado"

# 5. Crear estructura de directorios
log_info "Creando estructura de directorios..."
mkdir -p ~/clawd/{memory,tools,credentials,docs,backups}
mkdir -p ~/.clawdbot
mkdir -p ~/.config/systemd/user
log_success "Directorios creados"

# 6. Configurar audio
log_info "Configurando audio..."
cat > /tmp/setup-audio.sh << 'AUDIOEOF'
#!/bin/bash
# Detectar dispositivos de audio
echo "Dispositivos de audio detectados:"
echo "=== Tarjetas ==="
aplay -l 2>/dev/null || echo "No hay dispositivos de reproducción"
echo ""
echo "=== Micrófonos ===" 
arecord -l 2>/dev/null || echo "No hay dispositivos de grabación"
echo ""
echo "Configurando ReSpeaker si está presente..."
# Configuración específica para ReSpeaker Lite
if arecord -l | grep -q "seeed"; then
    echo "ReSpeaker detectado!"
    # Configurar como dispositivo default
    cat > ~/.asoundrc << 'EOF'
pcm.!default {
    type asym
    playback.pcm {
        type plug
        slave.pcm "hw:0,0"
    }
    capture.pcm {
        type plug
        slave.pcm "hw:1,0"
    }
}
EOF
fi
AUDIOEOF
chmod +x /tmp/setup-audio.sh
/tmp/setup-audio.sh

log_success "Audio configurado"

# 7. Instalar herramientas de voz
log_info "Instalando herramientas de voz..."

# Whisper (transcripción)
pip3 install --user openai-whisper

# Piper TTS (texto a voz local)
log_info "Descargando Piper TTS..."
mkdir -p ~/piper
pushd ~/piper > /dev/null
wget -q https://github.com/rhasspy/piper/releases/download/v1.2.0/piper_arm64.tar.gz
tar -xzf piper_arm64.tar.gz
rm piper_arm64.tar.gz
popd > /dev/null

# Porcupine Wake Word (detección de "Hey Clawd")
pip3 install --user pvporcupine

log_success "Herramientas de voz instaladas"

# 8. Instalar integraciones
log_info "Instalando integraciones de Smart Home..."

# Home Assistant CLI
pip3 install --user homeassistant-cli

# SmartThings CLI (si existe)
if command -v smartthings &> /dev/null; then
    log_info "SmartThings CLI ya instalado"
else
    log_warn "SmartThings CLI no encontrado. Instalar manualmente desde:"
    log_warn "https://github.com/SmartThingsCommunity/smartthings-cli"
fi

log_success "Integraciones instaladas"

# 9. Configurar servicio systemd
log_info "Configurando servicio systemd..."

cat > ~/.config/systemd/user/clawdbot-gateway.service << 'EOF'
[Unit]
Description=Clawdbot Gateway
After=network.target sound.target

[Service]
Type=simple
ExecStart=%h/.nvm/versions/node/v22.22.0/bin/clawdbot gateway start
Restart=always
RestartSec=10
Environment="PATH=%h/.local/bin:/usr/local/bin:/usr/bin:/bin"
Environment="HOME=%h"

[Install]
WantedBy=default.target
EOF

# Recargar systemd
systemctl --user daemon-reload
log_success "Servicio configurado"

# 10. Crear scripts de utilidad
log_info "Creando scripts de utilidad..."

cat > ~/clawd/tools/start-voice-assistant.sh << 'EOF'
#!/bin/bash
# Script para iniciar el asistente de voz

echo "🎙️  Iniciando asistente de voz Clawdbot..."
echo "Presiona Ctrl+C para detener"
echo ""

# Verificar que el gateway esté corriendo
if ! pgrep -f "clawdbot.*gateway" > /dev/null; then
    echo "⚠️  Gateway no está corriendo. Iniciando..."
    clawdbot gateway start &
    sleep 5
fi

# Ejecutar listener de voz
python3 ~/clawd/tools/voice-listener.py
EOF
chmod +x ~/clawd/tools/start-voice-assistant.sh

cat > ~/clawd/tools/test-audio.sh << 'EOF'
#!/bin/bash
# Test de audio completo

echo "🎵 Test de Audio Clawdbot"
echo "=========================="
echo ""

echo "1. Probando reproducción..."
speaker-test -t wav -c 2 -l 1 || echo "❌ Error en reproducción"

echo ""
echo "2. Probando grabación (5 segundos)..."
arecord -d 5 -f cd /tmp/test.wav && echo "✅ Grabación exitosa"

echo ""
echo "3. Reproduciendo grabación..."
aplay /tmp/test.wav || echo "❌ Error reproduciendo"

echo ""
echo "4. Test completado"
EOF
chmod +x ~/clawd/tools/test-audio.sh

# 11. Configurar entorno
log_info "Configurando variables de entorno..."

cat >> ~/.bashrc << 'EOF'

# Clawdbot Smart Home
export PATH="$HOME/.local/bin:$HOME/piper:$PATH"
export CLAWD_HOME="$HOME/clawd"
export PIPER_HOME="$HOME/piper"

# Aliases
alias clawd-start='clawdbot gateway start'
alias clawd-status='clawdbot status'
alias clawd-logs='clawdbot logs'
alias clawd-voice='~/clawd/tools/start-voice-assistant.sh'
alias clawd-test-audio='~/clawd/tools/test-audio.sh'
EOF

log_success "Scripts de utilidad creados"

# 12. Mensaje final
echo ""
echo "=========================================="
echo "✅ INSTALACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Próximos pasos:"
echo ""
echo "1. Reiniciar la terminal o ejecutar:"
echo "   source ~/.bashrc"
echo ""
echo "2. Iniciar el gateway:"
echo "   clawdbot gateway start"
echo ""
echo "3. Verificar estado:"
echo "   clawdbot status"
echo ""
echo "4. Probar audio:"
echo "   ~/clawd/tools/test-audio.sh"
echo ""
echo "5. Configurar SmartThings:"
echo "   ~/clawd/tools/setup-samsung.sh"
echo ""
echo "Documentación: ~/clawd/docs/"
echo ""
echo "🦊 Clawdbot está listo para tu Smart Home!"
echo "=========================================="
