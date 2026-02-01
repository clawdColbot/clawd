#!/bin/bash
#
# recovery_check.sh - Verificación y recuperación post-crash/restart
#
# Author: 🦊 ClawdColombia
# Boring Builder Protocol - Principle 2: Sobrevive sleep/offline
#
# USAGE:
#   ./recovery_check.sh              # Full recovery check
#   ./recovery_check.sh --quick      # Quick check (no logging)
#
# WHAT IT DOES:
#   1. Detects session gaps (potential crashes)
#   2. Recovers pending tasks from state.json
#   3. Lists active projects
#   4. Suggests recent checkpoints to review
#   5. Updates session counter
#
# OUTPUT:
#   - Last session timestamp
#   - Pending tasks list
#   - Active projects status
#   - Recent checkpoints found
#   - Updated session count
#
# EXAMPLES:
#   # Run at session start
#   ./recovery_check.sh
#
#   # After suspected crash
#   ./recovery_check.sh
#   # Then: cat ~/clawd/memory/checkpoints/checkpoint_*.md
#
#   # Quick check without logging
#   ./recovery_check.sh --quick
#
# INTEGRATION:
#   # Add to .bashrc or session startup
#   ~/clawd/tools/recovery_check.sh 2>/dev/null || true
#
# FILES:
#   Reads:  ~/clawd/memory/state.json
#   Reads:  ~/clawd/memory/checkpoints/checkpoint_*.md
#   Writes: ~/clawd/logs/recovery.log
#

set -euo pipefail

STATE_FILE="${HOME}/clawd/memory/state.json"
RECOVERY_LOG="${HOME}/clawd/logs/recovery.log"

mkdir -p "$(dirname "$RECOVERY_LOG")"

echo "🔄 Recovery Check - ClawdColombia"
echo "================================="
echo ""

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Función para loggear
log_recovery() {
    echo "[$TIMESTAMP] $1" >> "$RECOVERY_LOG"
}

# 1. Verificar si hay un crash anterior
check_last_session() {
    if [[ -f "$STATE_FILE" ]]; then
        local last_session
        last_session=$(grep -o '"last_session": "[^"]*"' "$STATE_FILE" | cut -d'"' -f4)
        
        if [[ -n "$last_session" ]]; then
            echo "📅 Última sesión: $last_session"
            
            # Calcular tiempo desde última sesión
            local last_epoch
            last_epoch=$(date -d "$last_session" +%s 2>/dev/null || echo 0)
            local now_epoch
            now_epoch=$(date +%s)
            local diff_hours=$(( (now_epoch - last_epoch) / 3600 ))
            
            if [[ $diff_hours -gt 24 ]]; then
                echo "⚠️  Gap de ${diff_hours}h detectado - posible crash o reinicio"
                log_recovery "Gap detectado: ${diff_hours}h desde última sesión"
                return 1
            fi
        fi
    fi
    return 0
}

# 2. Recuperar tareas pendientes
recover_pending_tasks() {
    if [[ -f "$STATE_FILE" ]]; then
        echo "📋 Tareas pendientes:"
        python3 << EOF 2>/dev/null || true
import json
import sys

try:
    with open('$STATE_FILE', 'r') as f:
        data = json.load(f)
    
    pending = data.get('pending_items', [])
    if pending:
        print(f"   {len(pending)} tarea(s) pendiente(s):")
        for item in pending[:5]:  # Mostrar max 5
            print(f"   - {item}")
    else:
        print("   ✅ No hay tareas pendientes")
        
except Exception as e:
    print(f"   ⚠️  Error leyendo state: {e}")
EOF
    fi
}

# 3. Verificar proyectos activos
recover_projects() {
    if [[ -f "$STATE_FILE" ]]; then
        echo ""
        echo "🚀 Proyectos activos:"
        python3 << EOF 2>/dev/null || true
import json

try:
    with open('$STATE_FILE', 'r') as f:
        data = json.load(f)
    
    projects = data.get('projects', {})
    for name, status in projects.items():
        if 'active' in status.lower():
            print(f"   🟢 {name}: {status}")
        elif 'paused' in status.lower():
            print(f"   ⏸️  {name}: {status}")
        else:
            print(f"   ⚪ {name}: {status}")
except:
    pass
EOF
    fi
}

# 4. Verificar si hay checkpoints pendientes de revisar
check_pending_checkpoints() {
    local checkpoint_dir="${HOME}/clawd/memory/checkpoints"
    if [[ -d "$checkpoint_dir" ]]; then
        local last_checkpoint
        last_checkpoint=$(ls -t "$checkpoint_dir"/checkpoint_*.md 2>/dev/null | head -1)
        
        if [[ -n "$last_checkpoint" ]]; then
            local checkpoint_time
            checkpoint_time=$(stat -c %Y "$last_checkpoint" 2>/dev/null || stat -f %m "$last_checkpoint" 2>/dev/null)
            local now
            now=$(date +%s)
            local diff_hours=$(( (now - checkpoint_time) / 3600 ))
            
            if [[ $diff_hours -lt 24 ]]; then
                echo ""
                echo "📄 Checkpoint reciente encontrado (${diff_hours}h):"
                echo "   $last_checkpoint"
                echo "   Sugerencia: ~/clawd/tools/checkpoint-manager.sh read"
            fi
        fi
    fi
}

# 5. Actualizar estado de sesión actual
update_session() {
    local current_time
    current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    python3 << EOF 2>/dev/null || true
import json

try:
    with open('$STATE_FILE', 'r') as f:
        data = json.load(f)
    
    data['last_session'] = '$current_time'
    
    # Incrementar contador de sesiones
    session_count = data.get('session_count', 0)
    data['session_count'] = session_count + 1
    
    with open('$STATE_FILE', 'w') as f:
        json.dump(data, f, indent=2)
    
    print("")
    print(f"✅ Sesión actualizada: #{session_count + 1}")
except Exception as e:
    print(f"⚠️  Error actualizando sesión: {e}")
EOF
}

# Main
check_last_session || true
recover_pending_tasks
recover_projects
check_pending_checkpoints
update_session

echo ""
echo "================================="
echo "✅ Recovery check completado"
echo ""
echo "Próximos pasos sugeridos:"
echo "   1. Leer último checkpoint si es necesario"
echo "   2. Revisar tareas pendientes"
echo "   3. Ejecutar health_check.sh"

log_recovery "Recovery check completado"
