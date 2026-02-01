#!/bin/bash
# voice_listener.sh - Script para escuchar y transcribir audios de Telegram
# Se ejecuta periódicamente para procesar mensajes de voz pendientes

TELEGRAM_TOKEN="8170451463:AAGCy-9rG4_y4KNyYulQxvueCGzn-vrYHhQ"
OFFSET_FILE="/tmp/telegram_voice_offset"
WHISPER_MODEL="base"

echo "🎙️  Telegram Voice Listener - ClawdColombia"
echo "============================================"

# Obtener último offset procesado
if [ -f "$OFFSET_FILE" ]; then
    OFFSET=$(cat "$OFFSET_FILE")
else
    OFFSET=0
fi

# Obtener actualizaciones de Telegram
echo "📥 Obteniendo mensajes nuevos..."
UPDATES=$(curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/getUpdates?offset=${OFFSET}&limit=10")

# Verificar si hay mensajes de voz
echo "$UPDATES" | python3 -c "
import json
import sys

data = json.load(sys.stdin)
if not data.get('ok') or not data.get('result'):
    sys.exit(0)

for update in data['result']:
    message = update.get('message', {})
    voice = message.get('voice')
    
    if voice:
        file_id = voice['file_id']
        chat_id = message['chat']['id']
        message_id = message['message_id']
        duration = voice.get('duration', 0)
        
        print(f'🎙️  Mensaje de voz detectado:')
        print(f'   Chat: {chat_id}')
        print(f'   Duración: {duration}s')
        print(f'   File ID: {file_id[:20]}...')
        print(f'')
        print(f'   Para transcribir, ejecuta:')
        print(f'   python3 ~/clawd/tools/telegram_voice_handler.py')
        print(f'   O espera a que Clawdbot lo procese automáticamente.')
        print()
    
    # Guardar último update_id
    print(f\"OFFSET={update['update_id'] + 1}\", file=sys.stderr)
" 2>&1

# Actualizar offset
NEW_OFFSET=$(echo "$UPDATES" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if data.get('result'):
    print(data['result'][-1]['update_id'] + 1)
else:
    print(0)
")

if [ "$NEW_OFFSET" -gt "$OFFSET" ]; then
    echo "$NEW_OFFSET" > "$OFFSET_FILE"
    echo "✅ Offset actualizado: $NEW_OFFSET"
fi

echo ""
echo "💡 Para procesar audios automáticamente, asegúrate de que"
echo "   Clawdbot esté configurado con el handler de voz."
