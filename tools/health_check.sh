#!/bin/bash
#
# health_check.sh - Fase 3: Health check automático de todos los componentes
# Boring Builder Protocol - Principle 2: Sobrevive sleep/offline
#

set -euo pipefail

REPORT_FILE="${HOME}/clawd/logs/health_report.json"
LOG_FILE="${HOME}/clawd/logs/health_check.log"

mkdir -p "$(dirname "$REPORT_FILE")"

echo "🏥 Health Check - ClawdColombia"
echo "==============================="
echo ""

# Timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Inicializar reporte
declare -A CHECKS
check() {
    local name=$1
    local command=$2
    
    echo -n "Checking $name... "
    if eval "$command" > /dev/null 2>&1; then
        echo "✅"
        CHECKS[$name]="ok"
        return 0
    else
        echo "❌"
        CHECKS[$name]="fail"
        return 1
    fi
}

# 1. Gateway
check "Clawdbot Gateway" "clawdbot status | grep -q 'Gateway.*running'"

# 2. Git
check "Git Repo" "git -C ~/clawd status > /dev/null"

# 3. Memory system
check "TACIT.md" "test -f ~/clawd/TACIT.md"
check "State file" "test -f ~/clawd/memory/state.json"
check "PARA structure" "test -d ~/clawd/memory/life"

# 4. Tools
check "Finance Monitor" "test -f ~/clawd/tools/finance-monitor/finance_monitor.py"
check "Checkpoint Manager" "test -x ~/clawd/tools/checkpoint-manager.sh"

# 5. Config files
check "Moltbook credentials" "test -f ~/.config/moltbook/credentials.json"
check "Environment file" "test -f ~/.clawdbot/.env"

# 6. Logs directory
check "Logs directory" "test -d ~/clawd/logs"

# 7. Backup directory
check "Backups directory" "test -d ~/clawd/backups"

# 8. Token usage (special check)
echo -n "Checking token usage... "
USAGE=$(~/clawd/tools/token_monitor.sh 2>/dev/null | grep "Token usage actual" | grep -o '[0-9]*%' | grep -o '[0-9]*' | head -1 || echo "unknown")
if [[ "$USAGE" =~ ^[0-9]+$ ]] && [[ "$USAGE" -lt 90 ]]; then
    echo "✅ (${USAGE}%)"
    CHECKS["token_usage"]="ok"
else
    echo "⚠️  (${USAGE}%)"
    CHECKS["token_usage"]="warning"
fi

echo ""
echo "==============================="

# Contar resultados
OK_COUNT=0
FAIL_COUNT=0
for status in "${CHECKS[@]}"; do
    if [[ "$status" == "ok" ]]; then
        ((OK_COUNT++))
    else
        ((FAIL_COUNT++))
    fi
done

TOTAL=$((OK_COUNT + FAIL_COUNT))
echo "Resultados: $OK_COUNT/$TOTAL OK"

# Generar reporte JSON
python3 << EOF
import json
import sys

data = {
    "timestamp": "$TIMESTAMP",
    "total_checks": $TOTAL,
    "ok": $OK_COUNT,
    "fail": $FAIL_COUNT,
    "checks": {
$(for key in "${!CHECKS[@]}"; do
    echo "        \"$key\": \"${CHECKS[$key]}\","
done | sed '$ s/,$//')
    },
    "status": "healthy" if $FAIL_COUNT == 0 else "degraded"
}

with open('$REPORT_FILE', 'w') as f:
    json.dump(data, f, indent=2)

print(f"\n📄 Reporte guardado: $REPORT_FILE")
print(f"   Status: {data['status']}")
EOF

# Log
echo "[$TIMESTAMP] Health check: $OK_COUNT/$TOTAL OK" >> "$LOG_FILE"

# Exit code
if [[ $FAIL_COUNT -gt 0 ]]; then
    echo ""
    echo "⚠️  Algunos checks fallaron. Revisar reporte."
    exit 1
else
    echo ""
    echo "✅ Todos los sistemas operativos"
    exit 0
fi
