# 🎙️ Voice Message Transcription - Documentación

## Instalación Completada ✅

Herramientas instaladas para transcribir audios de Telegram:

### 1. Whisper (OpenAI)
- **Modelo:** Base (74M parámetros)
- **Idiomas:** Soporta 99 idiomas incluyendo español
- **Precisión:** Buena para español con modelo base
- **Velocidad:** ~5-10s por minuto de audio en CPU

### 2. Scripts Creados

| Script | Ubicación | Función |
|--------|-----------|---------|
| `transcribe_audio.py` | `~/clawd/tools/transcribe_audio.py` | Transcribe archivo de audio |
| `telegram_voice_handler.py` | `~/clawd/tools/telegram_voice_handler.py` | Handler de mensajes de voz para Telegram |
| `voice_listener.sh` | `~/clawd/tools/voice_listener.sh` | Listener periódico de mensajes |

---

## 🚀 Uso

### Opción 1: Transcribir archivo de audio directamente
```bash
# Transcribir un archivo
python3 ~/clawd/tools/transcribe_audio.py /ruta/al/audio.ogg

# Especificar modelo (tiny, base, small, medium, large)
python3 ~/clawd/tools/transcribe_audio.py audio.ogg --model small

# Guardar en archivo
python3 ~/clawd/tools/transcribe_audio.py audio.ogg -o transcripcion.txt
```

### Opción 2: Procesar mensaje de voz de Telegram
```python
from telegram_voice_handler import process_voice_message

# En tu código de Clawdbot cuando recibas un mensaje de voz
text, error = process_voice_message(
    file_id="ID_DEL_ARCHIVO",
    chat_id="ID_DEL_CHAT",
    message_id="ID_DEL_MENSAJE"
)

if error:
    print(f"Error: {error}")
else:
    print(f"Transcripción: {text}")
```

### Opción 3: Escuchar mensajes periódicamente
```bash
# Ver mensajes de voz nuevos
~/clawd/tools/voice_listener.sh

# Agregar a crontab para revisar cada 5 minutos
*/5 * * * * ~/clawd/tools/voice_listener.sh >> ~/clawd/logs/voice_listener.log 2>&1
```

---

## 🔧 Configuración en Clawdbot

Para que Clawdbot procese automáticamente los mensajes de voz, necesitas:

1. **Webhook mode:** Configurar endpoint que reciba actualizaciones de Telegram
2. **Polling mode:** Hacer polling periódico de mensajes nuevos

### Ejemplo de integración en código:

```python
# Cuando Clawdbot reciba un mensaje de Telegram
if message.get('voice'):
    from telegram_voice_handler import process_voice_message
    
    file_id = message['voice']['file_id']
    chat_id = message['chat']['id']
    
    text, error = process_voice_message(file_id, chat_id)
    
    if text:
        # Procesar el texto transcrito como si fuera un mensaje normal
        response = process_message(text)
        send_telegram_response(chat_id, response)
    else:
        send_telegram_response(chat_id, "❌ No pude entender el audio")
```

---

## 📊 Modelos de Whisper

| Modelo | Tamaño | Velocidad | Precisión (es) | Uso recomendado |
|--------|--------|-----------|----------------|-----------------|
| tiny | 39 MB | Muy rápido | Regular | Pruebas rápidas |
| base | 74 MB | Rápido | Buena | **Uso general** ✅ |
| small | 244 MB | Moderado | Muy buena | Alta precisión |
| medium | 769 MB | Lento | Excelente | Precisión máxima |
| large | 1550 MB | Muy lento | Superior | Producción |

**Actualmente usando:** `base` (buen balance velocidad/precisión)

---

## 🌐 Idiomas Soportados

El modelo detecta automáticamente el idioma. Soporta:
- 🇪🇸 Español
- 🇺🇸 Inglés  
- 🇫🇷 Francés
- 🇩🇪 Alemán
- 🇮🇹 Italiano
- 🇵🇹 Portugués
- +93 idiomas más

---

## 📝 Notas

- **Formatos soportados:** mp3, wav, ogg, m4a, webm
- **Límite de tamaño:** Depende de memoria RAM disponible
- **Calidad recomendada:** Audio de 16kHz o superior
- **Idioma:** Se detecta automáticamente

---

## 🔗 Referencias

- [OpenAI Whisper](https://github.com/openai/whisper)
- [Telegram Bot API - Voice](https://core.telegram.org/bots/api#voice)

---

*Instalado: 2026-01-31*
*Por: ClawdColombia*
