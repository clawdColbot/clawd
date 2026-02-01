#!/bin/bash
# 🦊 Gateway Health Monitor - Script de respaldo para systemd
# Se ejecuta cada minuto vía cron para verificar que el gateway esté vivo

LOG_FILE="/tmp/clawdbot/gateway-monitor.log"
GATEWAY_URL="ws://127.0.0.1:18789"
PID_FILE="/tmp/clawdbot/gateway-monitor.pid"

# Crear directorio de logs si no existe
mkdir -p "$(dirname "$LOG_FILE")"

# Evitar múltiples instancias
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Monitor already running (PID: $OLD_PID)" >> "$LOG_FILE"
        exit 0
    fi
fi
echo $$ > "$PID_FILE"

# Función para loggear
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Función para verificar si el gateway responde
check_gateway() {
    # Usar nc (netcat) para verificar si el puerto está abierto
    if command -v nc >/dev/null 2>&1; then
        timeout 2 nc -z 127.0.0.1 18789 2>/dev/null
        return $?
    fi
    
    # Fallback: usar /dev/tcp
    timeout 2 bash -c 'echo > /dev/tcp/127.0.0.1/18789' 2>/dev/null
    return $?
}

# Función para reiniciar el gateway
restart_gateway() {
    log "⚠️ Gateway no responde, intentando reinicio..."
    
    # Intentar reinicio graceful
    systemctl --user restart clawdbot-gateway.service
    
    # Esperar a que arranque
    sleep 5
    
    # Verificar si arrancó
    if check_gateway; then
        log "✅ Gateway reiniciado exitosamente"
        
        # Notificar (opcional - requiere configuración de canal)
        # clawdbot message send --message "🦊 Gateway reiniciado automáticamente" --target "andres"
    else
        log "❌ Falló el reinicio del gateway"
    fi
}

# Main
check_gateway
if [ $? -ne 0 ]; then
    restart_gateway
else
    # Log silencioso de check exitoso (solo cada 10 minutos para no llenar logs)
    MINUTE=$(date '+%M')
    if [ "${MINUTE:1:1}" == "0" ]; then
        log "✓ Gateway healthy"
    fi
fi

# Limpiar PID file
rm -f "$PID_FILE"
