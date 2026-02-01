#!/usr/bin/env python3
"""
telegram_voice_handler.py - Manejador de mensajes de voz para Telegram
Descarga audios, transcribe con Whisper y responde con el texto
"""

import os
import sys
import requests
import whisper
from pathlib import Path

# Configuración
TELEGRAM_TOKEN = "8170451463:AAGCy-9rG4_y4KNyYulQxvueCGzn-vrYHhQ"  # Token de @Clawd_durango_bot
WHISPER_MODEL = "base"  # tiny, base, small, medium, large
DOWNLOAD_DIR = Path("/tmp/telegram_voice")

class TelegramVoiceHandler:
    def __init__(self, token=None):
        self.token = token or TELEGRAM_TOKEN
        self.base_url = f"https://api.telegram.org/bot{self.token}"
        self.model = None  # Se carga bajo demanda
        
        # Crear directorio de descargas
        DOWNLOAD_DIR.mkdir(exist_ok=True)
    
    def get_file_url(self, file_id):
        """Obtener URL de descarga de un archivo de Telegram"""
        response = requests.get(f"{self.base_url}/getFile", params={"file_id": file_id})
        if response.status_code == 200:
            data = response.json()
            if data.get("ok"):
                file_path = data["result"]["file_path"]
                return f"https://api.telegram.org/file/bot{self.token}/{file_path}"
        return None
    
    def download_voice(self, file_id, chat_id):
        """Descargar mensaje de voz y transcribir"""
        print(f"🎙️  Procesando audio de chat {chat_id}...")
        
        # Obtener URL de descarga
        file_url = self.get_file_url(file_id)
        if not file_url:
            return None, "Error: No se pudo obtener URL de descarga"
        
        # Descargar archivo
        local_path = DOWNLOAD_DIR / f"voice_{chat_id}_{file_id}.ogg"
        
        try:
            response = requests.get(file_url, timeout=30)
            response.raise_for_status()
            
            with open(local_path, 'wb') as f:
                f.write(response.content)
            
            print(f"💾 Audio guardado: {local_path}")
            
            # Transcribir
            transcript = self.transcribe(local_path)
            
            # Limpiar archivo temporal
            try:
                os.remove(local_path)
            except:
                pass
            
            return transcript, None
            
        except Exception as e:
            return None, f"Error procesando audio: {str(e)}"
    
    def transcribe(self, audio_path):
        """Transcribir audio usando Whisper"""
        # Cargar modelo si no está cargado
        if self.model is None:
            print(f"🤖 Cargando modelo Whisper ({WHISPER_MODEL})...")
            self.model = whisper.load_model(WHISPER_MODEL)
        
        print("📝 Transcribiendo...")
        result = self.model.transcribe(str(audio_path), verbose=False)
        
        language = result.get('language', 'unknown')
        text = result['text'].strip()
        
        print(f"✅ Transcripción completada ({language}): {text[:100]}...")
        
        return {
            'text': text,
            'language': language
        }
    
    def send_response(self, chat_id, text, reply_to_message_id=None):
        """Enviar respuesta de transcripción"""
        message = f"🎙️ *Transcripción:*\n\n{text}"
        
        params = {
            "chat_id": chat_id,
            "text": message,
            "parse_mode": "Markdown",
            "reply_to_message_id": reply_to_message_id
        }
        
        response = requests.post(f"{self.base_url}/sendMessage", params=params)
        return response.json() if response.status_code == 200 else None

# Función de conveniencia para uso desde Clawdbot
def process_voice_message(file_id, chat_id, message_id=None):
    """
    Procesar un mensaje de voz y devolver la transcripción
    
    Uso: process_voice_message(file_id, chat_id, message_id)
    Retorna: (transcription_text, error)
    """
    handler = TelegramVoiceHandler()
    result, error = handler.download_voice(file_id, chat_id)
    
    if error:
        return None, error
    
    return result['text'], None

if __name__ == "__main__":
    print("🦊 Telegram Voice Handler - ClawdColombia")
    print("="*50)
    print("\nPara usar desde Clawdbot:")
    print("  from telegram_voice_handler import process_voice_message")
    print("  text, error = process_voice_message(file_id, chat_id)")
    print("")
    print("O desde línea de comandos:")
    print("  python3 transcribe_audio.py <archivo_audio>")
