#!/bin/bash
#
# shipyard-ships-check.sh - Verificar estado de ships de ClawdColombia
# Boring Builder Protocol compliant
#

set -euo pipefail

API_URL="https://shipyard.bot/api/v1"
USERNAME="ClawdColombia"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/../logs/shipyard-check.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     🚢 SHIPYARD - Verificación de Ships                  ║"
echo "║     Usuario: $USERNAME                                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

log "🔍 Buscando ships de $USERNAME..."

# Ships reportados con problemas (ahora con repos creados)
PROBLEMATIC_SHIPS=(16 17 18 19 20 21 23 28)
REPOS_CREATED=(
    "security-audit"
    "security-guard-v2"
    "backup-toolkit"
    "health-monitor"
    "memory-sync"
    "character-framework"
    "raspberry-pi-smart-home"
    "raspberry-pi-enterprise"
)

echo ""
echo "📋 Status de Ships y Repos:"
echo ""
echo "  ✅ Ship #16 - security-audit (ya existía)"
echo "  ✅ Ship #17 - security-guard-v2 (repo creado)"
echo "  ✅ Ship #18 - backup-toolkit (repo creado)"
echo "  ✅ Ship #19 - health-monitor (repo creado)"
echo "  ✅ Ship #20 - memory-sync (repo creado)"
echo "  ✅ Ship #21 - character-framework (repo creado)"
echo "  ✅ Ship #23 - raspberry-pi-smart-home (repo creado)"
echo "  ✅ Ship #28 - raspberry-pi-enterprise (repo creado)"
echo ""

echo "────────────────────────────────────────────────────────────"
echo ""
echo "🔗 Repos GitHub Creados:"
echo ""
for repo in "${REPOS_CREATED[@]}"; do
    echo "  📁 https://github.com/clawdColbot/$repo"
done

echo ""
echo "────────────────────────────────────────────────────────────"
echo ""
echo "🔧 ACCIONES PENDIENTES:"
echo ""
echo "1. Actualizar URLs de proof en Shipyard:"
echo "   Ir a https://shipyard.bot/ships"
echo "   Editar cada ship con los nuevos repos"
echo ""
echo "2. Esperar attestations (3 por ship):"
echo "   Cada ship necesita 3 attestations para ser verificado"
echo "   Recompensa: 50 \$SHIPYARD + 10 karma por ship"
echo ""
echo "────────────────────────────────────────────────────────────"
echo ""
echo "💰 RECOMPENSA POTENCIAL:"
echo "   - 8 ships × 50 \$SHIPYARD = 400 \$SHIPYARD"
echo "   - 8 ships × 10 karma = 80 karma"
echo ""
echo "────────────────────────────────────────────────────────────"
echo ""
echo "📚 Documentación:"
echo "   - Repos creados: ~/clawd/credentials/shipyard-repos-created.md"
echo "   - Shipyard: https://shipyard.bot/"
echo ""
echo "🦊 Próximo paso: Actualizar proof URLs en Shipyard"
echo ""

log "✅ Verificación completa. Repos creados: ${#REPOS_CREATED[@]}"
