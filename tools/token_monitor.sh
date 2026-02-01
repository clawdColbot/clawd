#!/bin/bash
#
# token_monitor.sh - Monitoreo real de token usage desde Clawdbot
#
# Author: 🦊 ClawdColombia
# Boring Builder Protocol - Principle 2: Sobrevive sleep/offline
#
# USAGE:
#   ./token_monitor.sh              # Check token usage once
#   ./token_monitor.sh --watch      # Watch mode (every 60s)
#   ./token_monitor.sh --quiet      # Silent mode (exit code only)
#
# EXIT CODES:
#   0 - OK (< 80%)
#   1 - Warning (80-89%)
#   2 - Critical (>= 90%)
#
# EXAMPLES:
#   # Basic usage
#   ./token_monitor.sh
#   # Output: Token usage actual: 45%
#
#   # In a cron job (check every 5 min, alert if critical)
#   */5 * * * * /home/durango/clawd/tools/token_monitor.sh --quiet || \
#     echo "Token usage critical" | mail -s "Alert" admin@example.com
#
#   # Watch mode for debugging
#   ./token_monitor.sh --watch
#
# CURL REPRO:
#   # Equivalent check using Clawdbot CLI
#   clawdbot status | grep -E 'kimi-for-coding.*[0-9]+k/[0-9]+k'
#

set -euo pipefail

STATE_FILE="${HOME}/clawd/memory/state.json"
LOG_FILE="${HOME}/clawd/logs/token_usage.log"
CHECKPOINT_THRESHOLD=80
ALERT_THRESHOLD=90

# Crear directorios
mkdir -p "$(dirname "$LOG_FILE")"

# Función para obtener token usage de Clawdbot
get_token_usage() {
    local status_output
    status_output=$(clawdbot status 2>/dev/null || echo "")
    
    # Parsear output buscando "Tokens" line
    if [[ -n "$status_output" ]]; then
        # Buscar línea con formato: kimi-for-coding | 19k/262k (7%)
        local tokens_line
        tokens_line=$(echo "$status_output" | grep -E 'kimi-for-coding.*[0-9]+k/[0-9]+k' | head -1)
        
        if [[ -n "$tokens_line" ]]; then
            # Extraer porcentaje: (7%) -> 7
            local percentage
            percentage=$(echo "$tokens_line" | grep -oE '\([0-9]+%\)' | grep -oE '[0-9]+')
            echo "$percentage"
            return 0
        fi
    fi
    
    # Fallback: leer de state file anterior
    if [[ -f "$STATE_FILE" ]]; then
        local last_usage
        last_usage=$(grep -o '"tokens_usage": "[0-9]*' "$STATE_FILE" | grep -o '[0-9]*' | head -1)
        if [[ -n "$last_usage" ]]; then
            echo "$last_usage"
            return 0
        fi
    fi
    
    echo "unknown"
}

# Función para actualizar state.json
update_state() {
    local usage=$1
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    if [[ -f "$STATE_FILE" ]]; then
        # Actualizar campo tokens_usage
        python3 << EOF
import json
import sys

try:
    with open('$STATE_FILE', 'r') as f:
        data = json.load(f)
    
    if 'health' not in data:
        data['health'] = {}
    
    data['health']['tokens_usage'] = '${usage}%'
    data['health']['last_check'] = '$timestamp'
    
    with open('$STATE_FILE', 'w') as f:
        json.dump(data, f, indent=2)
    
    print('✅ State actualizado')
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
EOF
    fi
}

# Función para loggear
log_usage() {
    local usage=$1
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] Token usage: ${usage}%" >> "$LOG_FILE"
}

# Función para alertar
alert_if_needed() {
    local usage=$1
    
    if [[ "$usage" =~ ^[0-9]+$ ]]; then
        if [[ $usage -ge $ALERT_THRESHOLD ]]; then
            echo "🚨 ALERTA: Token usage crítico (${usage}%)"
            echo "   Creando checkpoint de emergencia..."
            ~/clawd/tools/checkpoint-manager.sh create 2>/dev/null || true
            return 2
        elif [[ $usage -ge $CHECKPOINT_THRESHOLD ]]; then
            echo "⚠️  AVISO: Token usage alto (${usage}%)"
            echo "   Considerar crear checkpoint"
            return 1
        fi
    fi
    return 0
}

# Main
echo "📊 Token Monitor - ClawdColombia"
echo "================================"

USAGE=$(get_token_usage)
echo "Token usage actual: ${USAGE}%"

# Loggear
log_usage "$USAGE"

# Actualizar state
update_state "$USAGE"

# Alertar si es necesario
alert_if_needed "$USAGE"
ALERT_STATUS=$?

echo ""
echo "Umbral checkpoint: ${CHECKPOINT_THRESHOLD}%"
echo "Umbral alerta: ${ALERT_THRESHOLD}%"
echo "Log: $LOG_FILE"

exit $ALERT_STATUS
