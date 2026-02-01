#!/usr/bin/env python3
"""
transcribe_audio.py - Script para transcribir audios/voz a texto usando Whisper
Uso: python3 transcribe_audio.py <archivo_audio> [--model base/small/medium]
"""

import whisper
import sys
import os
import argparse

def transcribe_audio(audio_path, model_size="base"):
    """
    Transcribe un archivo de audio a texto usando Whisper
    
    Args:
        audio_path: Ruta al archivo de audio
        model_size: Tamaño del modelo (tiny, base, small, medium, large)
    
    Returns:
        dict: {'text': str, 'language': str, 'segments': list}
    """
    if not os.path.exists(audio_path):
        return {'error': f'Archivo no encontrado: {audio_path}'}
    
    print(f"🎙️  Cargando modelo Whisper ({model_size})...")
    model = whisper.load_model(model_size)
    
    print(f"📝 Transcribiendo: {audio_path}")
    result = model.transcribe(audio_path, verbose=False)
    
    return {
        'text': result['text'].strip(),
        'language': result.get('language', 'unknown'),
        'segments': result.get('segments', [])
    }

def main():
    parser = argparse.ArgumentParser(description='Transcribe audio to text using Whisper')
    parser.add_argument('audio_file', help='Path to audio file')
    parser.add_argument('--model', default='base', 
                       choices=['tiny', 'base', 'small', 'medium', 'large'],
                       help='Whisper model size (default: base)')
    parser.add_argument('--output', '-o', help='Output file (optional)')
    
    args = parser.parse_args()
    
    # Verificar archivo
    if not os.path.exists(args.audio_file):
        print(f"❌ Error: Archivo no encontrado: {args.audio_file}")
        sys.exit(1)
    
    # Transcribir
    result = transcribe_audio(args.audio_file, args.model)
    
    if 'error' in result:
        print(f"❌ Error: {result['error']}")
        sys.exit(1)
    
    # Mostrar resultado
    print(f"\n🌍 Idioma detectado: {result['language']}")
    print(f"📝 Transcripción:\n{'='*60}")
    print(result['text'])
    print('='*60)
    
    # Guardar si se solicita
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(f"Language: {result['language']}\n\n")
            f.write(result['text'])
        print(f"\n💾 Guardado en: {args.output}")
    
    return result

if __name__ == "__main__":
    main()
