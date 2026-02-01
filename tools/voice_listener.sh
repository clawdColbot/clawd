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
