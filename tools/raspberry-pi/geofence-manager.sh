#!/bin/bash
#==============================================================================
# geofence-manager.sh - Gestión de geofencing para la casa
# Detecta cuando el usuario entra/sale de la zona segura
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

GEOFENCE_DIR="$HOME/clawd/geofence"
mkdir -p "$GEOFENCE_DIR"

# Coordenadas del hogar (configurar durante setup)
HOME_LAT="${HOME_LATITUDE:-0}"
HOME_LON="${HOME_LONGITUDE:-0}"
RADIUS_METERS="${GEOFENCE_RADIUS:-200}"  # Radio de 200m

# Estado actual
STATE_FILE="$GEOFENCE_DIR/state"
LOG_FILE="$GEOFENCE_DIR/events.log"

# Inicializar estado
if [[ ! -f "$STATE_FILE" ]]; then
    echo "unknown" > "$STATE_FILE"
fi

get_current_location() {
    """Obtener ubicación actual del usuario (via app móvil o IP)"""
    # Método 1: API de geolocalización IP (aproximado)
    local ip_location
    ip_location=$(curl -s "https://ipapi.co/json/" 2>/dev/null | jq -r '.latitude, .longitude' 2>/dev/null || echo "0 0")
    
    echo "$ip_location"
}

calculate_distance() {
    """Calcular distancia entre dos puntos (fórmula haversine)"""
    local lat1=$1
    local lon1=$2
    local lat2=$3
    local lon2=$4
    
    # Usar Python para cálculo preciso
    python3 << EOF
import math

def haversine(lat1, lon1, lat2, lon2):
    R = 6371000  # Radio de la Tierra en metros
    
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)
    
    a = math.sin(delta_phi/2)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    
    return R * c

distance = haversine($lat1, $lon1, $lat2, $lon2)
print(int(distance))
EOF
}

check_geofence() {
    """Verificar si el usuario está dentro del perímetro"""
    
    if [[ "$HOME_LAT" == "0" || "$HOME_LON" == "0" ]]; then
        log_warn "Coordenadas del hogar no configuradas"
        return 1
    fi
    
    # Obtener ubicación actual
    read -r CURRENT_LAT CURRENT_LON <<< "$(get_current_location)"
    
    if [[ "$CURRENT_LAT" == "0" && "$CURRENT_LON" == "0" ]]; then
        log_error "No se pudo obtener ubicación actual"
        return 1
    fi
    
    # Calcular distancia
    DISTANCE=$(calculate_distance "$HOME_LAT" "$HOME_LON" "$CURRENT_LAT" "$CURRENT_LON")
    
    log_info "Distancia al hogar: ${DISTANCE}m"
    
    if [[ $DISTANCE -le $RADIUS_METERS ]]; then
        echo "inside"
    else
        echo "outside"
    fi
}

on_enter_home() {
    """Acciones al llegar a casa"""
    log_success "🎉 Usuario llegó a casa!"
    
    # Log del evento
    echo "$(date -Iseconds) ENTER_HOME" >> "$LOG_FILE"
    
    # Activar escena "llegada"
    if [[ -x "$HOME/clawd/automations/arriving-home.sh" ]]; then
        "$HOME/clawd/automations/arriving-home.sh"
    fi
    
    # Notificar a Clawdbot
    curl -s -X POST http://localhost:18789/api/notify \
        -H "Content-Type: application/json" \
        -d '{"message": "Bienvenido a casa, Andres", "source": "geofence"}' 2>/dev/null || true
}

on_leave_home() {
    """Acciones al salir de casa"""
    log_warn "👋 Usuario salió de casa"
    
    # Log del evento
    echo "$(date -Iseconds) LEAVE_HOME" >> "$LOG_FILE"
    
    # Activar escena "salida"
    if [[ -x "$HOME/clawd/automations/leaving-home.sh" ]]; then
        "$HOME/clawd/automations/leaving-home.sh"
    fi
}

monitor_loop() {
    """Loop de monitoreo continuo"""
    log_info "Iniciando monitoreo de geofence..."
    log_info "Radio: ${RADIUS_METERS}m alrededor de [${HOME_LAT}, ${HOME_LON}]"
    
    while true; do
        CURRENT_STATE=$(check_geofence)
        PREVIOUS_STATE=$(cat "$STATE_FILE")
        
        # Detectar cambios
        if [[ "$CURRENT_STATE" != "$PREVIOUS_STATE" ]]; then
            echo "$CURRENT_STATE" > "$STATE_FILE"
            
            if [[ "$CURRENT_STATE" == "inside" && "$PREVIOUS_STATE" == "outside" ]]; then
                on_enter_home
            elif [[ "$CURRENT_STATE" == "outside" && "$PREVIOUS_STATE" == "inside" ]]; then
                on_leave_home
            fi
        fi
        
        # Verificar cada 2 minutos
        sleep 120
    done
}

setup_geofence() {
    """Configurar coordenadas del hogar"""
    echo "📍 Configuración de Geofence"
    echo "============================"
    
    read -p "Latitud del hogar: " lat
    read -p "Longitud del hogar: " lon
    read -p "Radio en metros (default 200): " radius
    
    radius=${radius:-200}
    
    cat > "$GEOFENCE_DIR/config" << EOF
HOME_LATITUDE=$lat
HOME_LONGITUDE=$lon
GEOFENCE_RADIUS=$radius
EOF
    
    log_success "Geofence configurado!"
    echo "Coordenadas: [$lat, $lon]"
    echo "Radio: ${radius}m"
}

show_status() {
    """Mostrar estado actual"""
    echo "📊 Estado de Geofence"
    echo "===================="
    
    if [[ -f "$GEOFENCE_DIR/config" ]]; then
        source "$GEOFENCE_DIR/config"
        echo "📍 Hogar: [$HOME_LATITUDE, $HOME_LONGITUDE]"
        echo "⭕ Radio: ${GEOFENCE_RADIUS}m"
    else
        echo "⚠️  No configurado"
    fi
    
    if [[ -f "$STATE_FILE" ]]; then
        STATE=$(cat "$STATE_FILE")
        if [[ "$STATE" == "inside" ]]; then
            echo "🏠 Estado: EN CASA"
        elif [[ "$STATE" == "outside" ]]; then
            echo "🚶 Estado: FUERA"
        else
            echo "❓ Estado: DESCONOCIDO"
        fi
    fi
    
    if [[ -f "$LOG_FILE" ]]; then
        echo ""
        echo "📜 Últimos eventos:"
        tail -5 "$LOG_FILE"
    fi
}

# Main
case "${1:-status}" in
    setup)
        setup_geofence
        ;;
    monitor)
        monitor_loop
        ;;
    status)
        show_status
        ;;
    check)
        check_geofence
        ;;
    *)
        echo "Uso: $0 {setup|monitor|status|check}"
        exit 1
        ;;
esac
