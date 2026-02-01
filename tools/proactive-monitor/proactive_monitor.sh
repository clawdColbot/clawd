#!/bin/bash
#
# proactive_monitor.sh - Sistema de monitoreo proactivo
# Ejecuta checks periódicos y envía alertas
#

CONFIG_DIR="${HOME}/clawd/config"
ALERT_LOG="${HOME}/clawd/logs/proactive_alerts.log"
mkdir -p "$(dirname "$ALERT_LOG")"

# Configuración de alertas (esto se puede editar)
THRESHOLDS=(
    "disk:80:⚠️ Disco al {value}%"
    "memory:90:⚠️ RAM al {value}%"
    "crypto_btc:5:📉 BTC bajó {value}%"
    "crypto_eth:7:📉 ETH bajó {value}%"
)

# Función para enviar alerta
send_alert() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log a archivo
    echo "[$timestamp] $message" >> "$ALERT_LOG"
    
    # Enviar a Telegram (si está configurado)
    if [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d "chat_id=${TELEGRAM_CHAT_ID}" \
            -d "text=🔔 ${message}" > /dev/null 2>&1
    fi
    
    echo "🚨 ALERTA: $message"
}

# Check: Uso de disco
check_disk() {
    local usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$usage" -gt 80 ]; then
        send_alert "⚠️ Disco duro al ${usage}% - Considera limpiar archivos"
    fi
}

# Check: Uso de RAM
check_memory() {
    local usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
    if [ "$usage" -gt 90 ]; then
        send_alert "⚠️ RAM al ${usage}% - Sistema sobrecargado"
    fi
}

# Check: Procesos zombie
check_zombies() {
    local zombies=$(ps aux | grep -c "<defunct>")
    if [ "$zombies" -gt 5 ]; then
        send_alert "👻 Hay ${zombies} procesos zombie - Requiere atención"
    fi
}

# Check: Emails no leídos (si himalaya está configurado)
check_emails() {
    if command -v himalaya &> /dev/null; then
        local unread=$(himalaya list --page-size 100 2>/dev/null | grep -c "UNREAD" || echo "0")
        if [ "$unread" -gt 10 ]; then
            send_alert "📧 Tienes ${unread} emails no leídos"
        fi
    fi
}

# Check: Precios de crypto (usando API pública)
check_crypto() {
    # Solo ejecutar cada 30 minutos para no saturar la API
    local cache_file="/tmp/crypto_cache.json"
    local cache_age=1800  # 30 minutos
    
    if [ -f "$cache_file" ]; then
        local file_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [ "$file_age" -lt "$cache_age" ]; then
            return  # Usar cache
        fi
    fi
    
    # Obtener precios
    curl -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd" \
        > "$cache_file" 2>/dev/null
    
    # Aquí iría lógica de comparación con precios anteriores
    # Por ahora solo notificamos si hay cambio significativo
}

# Check: Tareas pendientes vencidas
check_tasks() {
    # Si hay sistema de tareas, verificar vencidas
    local tasks_file="${HOME}/clawd/memory/active-tasks.md"
    if [ -f "$tasks_file" ]; then
        local overdue=$(grep -c "VENCIDO\|OVERDUE" "$tasks_file" 2>/dev/null || echo "0")
        if [ "$overdue" -gt 0 ]; then
            send_alert "📋 Tienes ${overdue} tareas vencidas"
        fi
    fi
}

# Check: Estado de Clawdbot
check_clawdbot() {
    if ! pgrep -f "clawdbot" > /dev/null; then
        send_alert "🔴 Clawdbot no está corriendo - Reinicio necesario"
    fi
}

# Menú principal
case "${1:-run}" in
    run)
        echo "🔍 Ejecutando checks proactivos..."
        check_disk
        check_memory
        check_zombies
        check_emails
        check_tasks
        check_clawdbot
        echo "✅ Checks completados"
        ;;
    
    install-cron)
        # Instalar en cron cada 15 minutos
        (crontab -l 2>/dev/null; echo "*/15 * * * * ${HOME}/clawd/tools/proactive-monitor/proactive_monitor.sh run >> ${HOME}/clawd/logs/proactive_monitor.log 2>&1") | crontab -
        echo "✅ Cron instalado - Checks cada 15 minutos"
        ;;
    
    status)
        echo "📊 Estado del Sistema:"
        echo "  Disco: $(df -h / | tail -1 | awk '{print $5}')"
        echo "  RAM: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100}')"
        echo "  Procesos: $(ps aux | wc -l)"
        echo ""
        echo "📋 Últimas alertas:"
        tail -5 "$ALERT_LOG" 2>/dev/null || echo "  Sin alertas recientes"
        ;;
    
    test-alert)
        send_alert "🧪 Esta es una alerta de prueba"
        ;;
    
    *)
        echo "Uso: $0 [run|install-cron|status|test-alert]"
        ;;
esac
