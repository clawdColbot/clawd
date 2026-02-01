#!/usr/bin/env python3
"""
voice-listener.py - Listener de voz para Clawdbot en Raspberry Pi
Detecta wake word, transcrbibe comando, envía a Clawdbot, reproduce respuesta
"""

import os
import sys
import time
import wave
import subprocess
import threading
import queue
from pathlib import Path

# Configuración
WAKE_WORD = "hey clawd"
RECORD_SECONDS = 5
SAMPLE_RATE = 16000
CHUNK_SIZE = 1024

class VoiceAssistant:
    def __init__(self):
        self.audio_queue = queue.Queue()
        self.is_listening = False
        self.clawd_home = Path.home() / "clawd"
        
    def detect_wake_word(self):
        """Detectar wake word usando Porcupine o comando simple"""
        print("🎙️  Escuchando... Di 'Hey Clawd' para activar")
        
        try:
            # Intentar con Porcupine si está disponible
            import pvporcupine
            import pyaudio
            
            porcupine = pvporcupine.create(keywords=["picovoice"])  # Usar por defecto
            
            pa = pyaudio.PyAudio()
            stream = pa.open(
                rate=porcupine.sample_rate,
                channels=1,
                format=pyaudio.paInt16,
                input=True,
                frames_per_buffer=porcupine.frame_length
            )
            
            print("✅ Wake word detection activo (Porcupine)")
            
            while True:
                pcm = stream.read(porcupine.frame_length)
                pcm = struct.unpack_from("h" * porcupine.frame_length, pcm)
                
                keyword_index = porcupine.process(pcm)
                
                if keyword_index >= 0:
                    print("🦊 ¡Wake word detectado!")
                    return True
                    
        except ImportError:
            # Fallback: detección simple de energía de audio
            print("⚠️  Porcupine no disponible, usando detección simple")
            print("   Presiona ENTER para hablar (modo manual)")
            input()
            return True
        except Exception as e:
            print(f"❌ Error en wake word: {e}")
            return False
    
    def record_command(self, duration=RECORD_SECONDS):
        """Grabar comando de voz"""
        print(f"🎤 Grabando por {duration} segundos...")
        
        output_file = "/tmp/clawd_command.wav"
        
        try:
            # Usar arecord (más confiable en Pi)
            subprocess.run([
                "arecord",
                "-D", "plughw:1,0",  # Micrófono USB/ReSpeaker
                "-d", str(duration),
                "-f", "cd",           # 16-bit 44100Hz stereo
                "-t", "wav",
                output_file
            ], check=True, capture_output=True)
            
            print("✅ Grabación completada")
            return output_file
            
        except subprocess.CalledProcessError:
            print("❌ Error grabando. Intentando dispositivo alternativo...")
            try:
                subprocess.run([
                    "arecord",
                    "-d", str(duration),
                    "-f", "cd",
                    "-t", "wav",
                    output_file
                ], check=True, capture_output=True)
                return output_file
            except:
                return None
    
    def transcribe(self, audio_file):
        """Transcribir audio a texto usando Whisper"""
        print("📝 Transcribiendo...")
        
        try:
            import whisper
            
            # Cargar modelo pequeño para Pi
            model = whisper.load_model("tiny")
            result = model.transcribe(audio_file, language="es")
            
            text = result["text"].strip()
            print(f"🗣️  Dijiste: '{text}'")
            return text
            
        except Exception as e:
            print(f"❌ Error en transcripción: {e}")
            return None
    
    def send_to_clawd(self, text):
        """Enviar texto a Clawdbot y obtener respuesta"""
        print("🦊 Enviando a Clawdbot...")
        
        # Aquí iría la integración real con Clawdbot
        # Por ahora, simulamos respuestas para Smart Home
        
        text_lower = text.lower()
        
        # Comandos de Smart Home
        if "luz" in text_lower or "luces" in text_lower:
            if "enciende" in text_lower or "prende" in text_lower:
                return "Encendiendo luces"
            elif "apaga" in text_lower:
                return "Apagando luces"
        
        elif "música" in text_lower or "musica" in text_lower:
            return "Reproduciendo música en el Music Frame"
        
        elif "tele" in text_lower or "tv" in text_lower:
            if "apaga" in text_lower:
                return "Apagando la TV"
            elif "enciende" in text_lower:
                return "Encendiendo la TV"
        
        elif "temperatura" in text_lower:
            return "La temperatura actual es de 22 grados"
        
        elif "hora" in text_lower:
            from datetime import datetime
            now = datetime.now().strftime("%I:%M %p")
            return f"Son las {now}"
        
        else:
            return f"Entendido: {text}"
    
    def speak(self, text):
        """Convertir texto a voz usando Piper TTS"""
        print(f"🔊 Respondiendo: '{text}'")
        
        try:
            # Usar Piper para TTS local
            piper_path = Path.home() / "piper" / "piper"
            model_path = Path.home() / "piper" / "es_ES-carol-medium.onnx"
            
            # Si no existe modelo en español, usar festival o espeak
            if not model_path.exists():
                # Fallback a espeak (más robotico pero funciona)
                subprocess.run([
                    "espeak", "-ves", text
                ], check=True)
            else:
                # Piper TTS
                output_wav = "/tmp/clawd_response.wav"
                
                with open("/tmp/clawd_text.txt", "w") as f:
                    f.write(text)
                
                subprocess.run([
                    str(piper_path),
                    "--model", str(model_path),
                    "--output_file", output_wav
                ], input=text.encode(), check=True)
                
                # Reproducir
                subprocess.run(["aplay", output_wav], check=True)
            
            print("✅ Respuesta reproducida")
            
        except Exception as e:
            print(f"⚠️  Error en TTS: {e}")
            # Último recurso: imprimir
            print(f"[RESPUESTA]: {text}")
    
    def run(self):
        """Loop principal del asistente"""
        print("=" * 50)
        print("🦊 CLAWDBOT VOICE ASSISTANT")
        print("   Smart Home Edition")
        print("=" * 50)
        print()
        
        while True:
            try:
                # 1. Esperar wake word
                if self.detect_wake_word():
                    # 2. Grabar comando
                    audio_file = self.record_command()
                    
                    if audio_file:
                        # 3. Transcribir
                        text = self.transcribe(audio_file)
                        
                        if text:
                            # 4. Procesar
                            response = self.send_to_clawd(text)
                            
                            # 5. Responder en voz
                            self.speak(response)
                    
                    print()
                    print("🎙️  Escuchando... Di 'Hey Clawd' para activar")
                    
            except KeyboardInterrupt:
                print("\n👋 Adiós!")
                break
            except Exception as e:
                print(f"❌ Error: {e}")
                time.sleep(2)

def main():
    assistant = VoiceAssistant()
    assistant.run()

if __name__ == "__main__":
    main()
