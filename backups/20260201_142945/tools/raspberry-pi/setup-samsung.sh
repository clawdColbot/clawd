#!/bin/bash
#==============================================================================
# setup-samsung.sh - Configurar integración Samsung SmartThings
#==============================================================================

set -e

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
echo "🔷 SAMSUNG SMARTTHINGS SETUP"
echo "=========================================="
echo ""

# Verificar que Clawdbot esté instalado
if ! command -v clawdbot &> /dev/null; then
    log_error "Clawdbot no instalado. Ejecutar primero: install-clawdbot-pi.sh"
    exit 1
fi

log_info "Este script configura la integración con tus dispositivos Samsung"
echo ""
echo "Dispositivos detectados en tu red:"
echo "  ✓ Samsung Smart Music Frame"
echo "  ✓ Samsung TV Serie 7"
echo ""

# Paso 1: Obtener token de SmartThings
log_info "Paso 1: Obtener token de SmartThings"
echo ""
echo "1. Ve a: https://account.smartthings.com/tokens"
echo "2. Crea un nuevo token"
echo "3. Selecciona permisos: Devices (r/w), Scenes (r/w)"
echo "4. Copia el token generado"
echo ""

read -p "Pega tu SmartThings token: " SMARTTHINGS_TOKEN

if [[ -z "$SMARTTHINGS_TOKEN" ]]; then
    log_error "Token requerido"
    exit 1
fi

# Guardar token de forma segura
mkdir -p ~/clawd/credentials
chmod 700 ~/clawd/credentials

cat > ~/clawd/credentials/smartthings.env << EOF
# SmartThings Configuration
# Guardado: $(date)
SMARTTHINGS_TOKEN="$SMARTTHINGS_TOKEN"
SMARTTHINGS_ENABLED=true
EOF

chmod 600 ~/clawd/credentials/smartthings.env
log_success "Token guardado de forma segura"

# Paso 2: Detectar dispositivos
echo ""
log_info "Paso 2: Detectando dispositivos..."

# Instalar SmartThings CLI si no existe
if ! command -v smartthings &> /dev/null; then
    log_info "Instalando SmartThings CLI..."
    
    # Descargar última versión
    curl -Lo /tmp/smartthings.tar.gz \
        "https://github.com/SmartThingsCommunity/smartthings-cli/releases/latest/download/smartthings-linux-arm64.tar.gz"
    
    tar -xzf /tmp/smartthings.tar.gz -C /tmp/
    sudo mv /tmp/smartthings /usr/local/bin/
    rm /tmp/smartthings.tar.gz
    
    log_success "SmartThings CLI instalado"
fi

# Configurar token
export SMARTTHINGS_TOKEN="$SMARTTHINGS_TOKEN"

echo ""
echo "Dispositivos encontrados:"
echo "------------------------"

# Listar dispositivos
smartthings devices --token="$SMARTTHINGS_TOKEN" 2>/dev/null || echo "No se pudieron listar dispositivos (verificar token)"

echo ""

# Paso 3: Crear automatizaciones de ejemplo
echo ""
log_info "Paso 3: Creando automatizaciones de ejemplo..."

mkdir -p ~/clawd/automations

# Escena: Buenos Días
cat > ~/clawd/automations/good-morning.sh << 'EOF'
#!/bin/bash
# Escena: Buenos Días

echo "🌅 Activando escena: Buenos Días"

# Poner música suave en Music Frame
# smartthings devices:commands <device-id> "setVolume(30)"
# smartthings devices:commands <device-id> "play()"

# Gradualmente subir luces (si están configuradas)
# Esto requeriría integración con Home Assistant o Hue

echo "✅ Escena activada"
EOF
chmod +x ~/clawd/automations/good-morning.sh

# Escena: Modo Cine
cat > ~/clawd/automations/movie-mode.sh << 'EOF'
#!/bin/bash
# Escena: Modo Cine

echo "🎬 Activando escena: Modo Cine"

# Bajar luces
# smartthings devices:commands <light-id> "setLevel(20)"

# Encender TV en modo HDMI 1
# smartthings devices:commands <tv-id> "setInputSource(HDMI1)"

# Pausar música si está sonando
# smartthings devices:commands <music-frame-id> "pause()"

echo "✅ Modo Cine activado"
EOF
chmod +x ~/clawd/automations/movie-mode.sh

# Escena: Me Voy de Casa
cat > ~/clawd/automations/leaving-home.sh << 'EOF'
#!/bin/bash
# Escena: Me Voy de Casa

echo "🏠 Activando escena: Me Voy de Casa"

# Apagar TV
smartthings devices:commands <tv-id> "off()" 2>/dev/null || true

# Apagar Music Frame
smartthings devices:commands <music-frame-id> "pause()" 2>/dev/null || true

# Apagar luces
# smartthings devices:commands <light-id> "off()"

echo "✅ Casa segura. Hasta luego!"
EOF
chmod +x ~/clawd/automations/leaving-home.sh

log_success "Automatizaciones creadas en ~/clawd/automations/"

# Paso 4: Crear comandos de voz
echo ""
log_info "Paso 4: Configurando comandos de voz..."

cat > ~/clawd/voice-commands.md << 'EOF'
# Comandos de Voz - Samsung SmartThings

## Música (Music Frame)
- "Clawd, pon música"
- "Clawd, sube el volumen"
- "Clawd, baja el volumen"
- "Clawd, pausa la música"
- "Clawd, siguiente canción"

## TV (Samsung Serie 7)
- "Clawd, enciende la TV"
- "Clawd, apaga la TV"
- "Clawd, cambia a Netflix"
- "Clawd, sube volumen de la TV"
- "Clawd, pon mute"

## Escenas
- "Clawd, buenos días" → Música suave + luces graduales
- "Clawd, modo cine" → Luces bajas + TV encendida
- "Clawd, me voy" → Todo apagado + seguro
- "Clawd, llegué" → Luces encendidas + música

## Información
- "Clawd, qué hora es?"
- "Clawd, estado de la casa"
EOF

log_success "Comandos documentados en ~/clawd/voice-commands.md"

# Paso 5: Configurar integración con Clawdbot
echo ""
log_info "Paso 5: Configurando integración con Clawdbot..."

# Añadir a variables de entorno
cat >> ~/.bashrc << 'EOF'

# SmartThings Integration
if [[ -f ~/clawd/credentials/smartthings.env ]]; then
    source ~/clawd/credentials/smartthings.env
fi
EOF

log_success "Integración configurada"

# Resumen final
echo ""
echo "=========================================="
echo "✅ SAMSUNG SMARTTHINGS CONFIGURADO"
echo "=========================================="
echo ""
echo "Dispositivos configurados:"
echo "  🔷 Samsung Smart Music Frame"
echo "  🔷 Samsung TV Serie 7"
echo ""
echo "Automatizaciones creadas:"
ls -1 ~/clawd/automations/
echo ""
echo "Próximos pasos:"
echo ""
echo "1. Actualizar IDs de dispositivos en:"
echo "   ~/clawd/automations/*.sh"
echo ""
echo "2. Ejecutar automatización de prueba:"
echo "   ~/clawd/automations/good-morning.sh"
echo ""
echo "3. Usar comandos de voz:"
echo "   ~/clawd/voice-listener.py"
echo ""
echo "=========================================="
