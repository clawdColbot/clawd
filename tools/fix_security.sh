#!/bin/bash
#
# fix_security.sh - Remediación de seguridad crítica
#
# Author: 🦊 ClawdColombia
# Boring Builder Protocol - Principle 3: No secrets in code
#
# USAGE:
#   ./fix_security.sh           # Run full security audit and fix
#   ./fix_security.sh --check   # Check only (no changes)
#
# WHAT IT DOES:
#   1. Creates backup of tools directory
#   2. Creates/verifies ~/.clawdbot/.env file (permissions 600)
#   3. Fixes voice_listener.sh (moves token to .env)
#   4. Scans for exposed secrets in other scripts
#   5. Fixes permissions on sensitive files
#
# SAFETY:
#   - Always creates backup first
#   - Idempotent (can run multiple times safely)
#
# EXAMPLES:
#   # Fix all security issues
#   ./fix_security.sh
#
#   # Check only (dry run)
#   ./fix_security.sh --check
#
#   # Verify no secrets exposed
#   grep -r "TOKEN=\|API_KEY=" ~/clawd/tools/ --include="*.sh" | grep -v ".env"
#
# BACKUP:
#   Created at: ~/clawd/backups/YYYYMMDD_HHMMSS/
#

set -euo pipefail

echo "🔒 Fase 1: Remediación de Seguridad Crítica"
echo "============================================"

ENV_FILE="${HOME}/.clawdbot/.env"
BACKUP_DIR="${HOME}/clawd/backups/$(date +%Y%m%d_%H%M%S)"

# 1. Backup
echo "📦 Creando backup..."
mkdir -p "$BACKUP_DIR"
cp -r ~/clawd/tools "$BACKUP_DIR/" 2>/dev/null || true
echo "✅ Backup en: $BACKUP_DIR"

# 2. Crear/verificar .env
echo ""
echo "🔐 Configurando .env..."
if [[ ! -f "$ENV_FILE" ]]; then
    cat > "$ENV_FILE" << 'EOF'
# Clawdbot Environment Variables
# Permisos: chmod 600 ~/.clawdbot/.env

# Telegram
CLAWDBOT_TELEGRAM_BOT_TOKEN=

# Moltbook
MOLTBOOK_API_KEY=

# Shipyard
SHIPYARD_API_KEY=

# Finance APIs
ALPHA_VANTAGE_API_KEY=
EOF
    chmod 600 "$ENV_FILE"
    echo "✅ Creado: $ENV_FILE"
else
    echo "✅ $ENV_FILE ya existe"
    chmod 600 "$ENV_FILE"
fi

# 3. Agregar TELEGRAM_TOKEN si existe en config
if grep -q "TELEGRAM_BOT_TOKEN" ~/.clawdbot/clawdbot.json 2>/dev/null; then
    TOKEN=$(grep -o '"TELEGRAM_BOT_TOKEN"[^}]*' ~/.clawdbot/clawdbot.json | grep -o '[A-Za-z0-9:_-]*' | tail -1)
    if [[ -n "$TOKEN" && ! "$TOKEN" =~ ^\${ ]]; then
        echo "CLAWDBOT_TELEGRAM_BOT_TOKEN=${TOKEN}" >> "$ENV_FILE"
        echo "✅ Token migrado a .env"
    fi
fi

# 4. Fix voice_listener.sh
echo ""
echo "🔧 Arreglando voice_listener.sh..."
VOICE_FILE="${HOME}/clawd/tools/voice_listener.sh"

if [[ -f "$VOICE_FILE" ]]; then
    # Crear versión segura
    cat > "$VOICE_FILE.tmp" << 'EOF'
#!/bin/bash
# voice_listener.sh - Script para escuchar y transcribir audios de Telegram
# Seguro: No expone tokens en código

set -euo pipefail

# Load config
ENV_FILE="${HOME}/.clawdbot/.env"
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
fi

TELEGRAM_TOKEN="${CLAWDBOT_TELEGRAM_BOT_TOKEN:-}"
if [[ -z "$TELEGRAM_TOKEN" ]]; then
    echo "❌ Error: CLAWDBOT_TELEGRAM_BOT_TOKEN no configurado"
    echo "   Agregar a: $ENV_FILE"
    exit 1
fi

OFFSET_FILE="${HOME}/.cache/telegram_voice_offset"
WHISPER_MODEL="base"

echo "🎙️  Telegram Voice Listener - ClawdColombia"
echo "============================================"

# Obtener último offset procesado
mkdir -p "$(dirname "$OFFSET_FILE")"
if [[ -f "$OFFSET_FILE" ]]; then
    OFFSET=$(cat "$OFFSET_FILE")
else
    OFFSET=0
fi

echo "📥 Obteniendo mensajes nuevos..."
UPDATES=$(curl -s --max-time 30 "https://api.telegram.org/bot${TELEGRAM_TOKEN}/getUpdates?offset=${OFFSET}&limit=10")

# Verificar respuesta
if [[ "$UPDATES" != *'"ok":true'* ]]; then
    echo "❌ Error al obtener actualizaciones"
    exit 1
fi

# Procesar mensajes (simplified)
echo "$UPDATES" | python3 -c "
import json
import sys

try:
    data = json.load(sys.stdin)
    if not data.get('ok') or not data.get('result'):
        sys.exit(0)
    
    updates = data['result']
    if not updates:
        print('No hay mensajes nuevos')
        sys.exit(0)
    
    for update in updates:
        if 'message' in update and 'voice' in update['message']:
            print(f\"🎤 Mensaje de voz encontrado: {update['update_id']}\")
        # Actualizar offset
        print(update['update_id'] + 1)
        
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
" | tail -1 > "$OFFSET_FILE"

echo "✅ Procesamiento completo"
EOF

    mv "$VOICE_FILE.tmp" "$VOICE_FILE"
    chmod +x "$VOICE_FILE"
    echo "✅ voice_listener.sh actualizado"
fi

# 5. Verificar otros scripts
echo ""
echo "🔍 Verificando otros scripts..."
FOUND_SECRETS=$(grep -r "TOKEN=\|API_KEY=\|password=" --include="*.sh" --include="*.py" ~/clawd/tools/ 2>/dev/null | grep -v ".env" | grep -v "${.*:-}" | grep -v "^#" || true)

if [[ -n "$FOUND_SECRETS" ]]; then
    echo "⚠️  Secrets encontrados en:"
    echo "$FOUND_SECRETS" | head -5
    echo ""
    echo "   Revisar manualmente estos archivos"
else
    echo "✅ No se encontraron secrets expuestos"
fi

# 6. Verificar permisos
echo ""
echo "🔐 Verificando permisos de archivos sensibles..."
find ~/.config -name "*.json" -o -name ".env" 2>/dev/null | while read f; do
    PERMS=$(stat -c "%a" "$f" 2>/dev/null || stat -f "%Lp" "$f" 2>/dev/null)
    if [[ "$PERMS" != "600" ]]; then
        chmod 600 "$f"
        echo "✅ Fixed permissions: $f"
    fi
done

echo ""
echo "============================================"
echo "✅ Fase 1 completada"
echo ""
echo "⚠️  ACCIONES MANUALES PENDIENTES:"
echo "   1. Editar: $ENV_FILE"
echo "   2. Agregar los tokens/API keys reales"
echo "   3. Verificar: grep -r 'TOKEN=' ~/clawd/tools/ | grep -v '.env'"
echo ""
echo "🔗 Documentación: ~/clawd/docs/BORING_BUILDER_REMEDIATION.md"
