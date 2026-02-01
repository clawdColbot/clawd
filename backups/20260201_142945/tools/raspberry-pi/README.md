# 🏠 Raspberry Pi Smart Home Assistant

Transforma tu Raspberry Pi en un asistente de voz local completo, integrado con Samsung SmartThings y preparado para Home Assistant.

## ✨ Características

- 🎙️ **Control por Voz** - Wake word detection, STT con Whisper, TTS con Piper
- 🔷 **Samsung SmartThings** - Integración nativa con Music Frame y TV
- 🏡 **Home Assistant Ready** - Preparado para integración con HA
- 🔒 **Privacidad First** - Todo procesamiento local, sin nube de Amazon/Google
- 🦊 **Clawdbot Powered** - Memoria persistente, automatizaciones inteligentes

## 📋 Requisitos

### Hardware
- Raspberry Pi 5 (8GB RAM recomendado)
- MicroSD 128GB clase A2 o SSD NVMe
- Micrófono: ReSpeaker Lite HAT o USB
- Altavoz con jack 3.5mm
- Fuente USB-C 27W oficial

### Dispositivos Compatibles
- ✅ Samsung Smart Music Frame
- ✅ Samsung TV Serie 7 (Tizen)
- ✅ Philips Hue / IKEA TRÅDFRI
- ✅ Sonoff / Tuya Zigbee
- ✅ Cualquier dispositivo SmartThings

## 🚀 Instalación Rápida

```bash
# 1. Descargar el instalador
curl -fsSL https://raw.githubusercontent.com/clawdColombia/raspberry-pi-smart-home/main/install-clawdbot-pi.sh | bash

# 2. Reiniciar terminal
source ~/.bashrc

# 3. Iniciar Clawdbot
clawdbot gateway start

# 4. Configurar Samsung SmartThings
~/clawd/tools/raspberry-pi/setup-samsung.sh

# 5. Probar asistente de voz
~/clawd/tools/raspberry-pi/voice-listener.py
```

## 🎯 Uso

### Comandos de Voz

**Música (Samsung Music Frame)**
- *"Hey Clawd, pon música"*
- *"Hey Clawd, sube el volumen"*
- *"Hey Clawd, pausa"*

**TV (Samsung Serie 7)**
- *"Hey Clawd, enciende la TV"*
- *"Hey Clawd, cambia a Netflix"*
- *"Hey Clawd, apaga la tele"*

**Escenas Inteligentes**
- *"Hey Clawd, buenos días"* → Música suave + luces graduales
- *"Hey Clawd, modo cine"* → Luces bajas + TV encendida
- *"Hey Clawd, me voy"* → Todo apagado + casa segura

### Automatizaciones

Las automatizaciones están en `~/clawd/automations/`:

```bash
# Activar escena manualmente
~/clawd/automations/good-morning.sh
~/clawd/automations/movie-mode.sh
~/clawd/automations/leaving-home.sh
```

## 🔧 Configuración Avanzada

### Integración Home Assistant

1. Instalar Home Assistant en la misma Pi o servidor separado
2. Configurar `ha-mcp` (Home Assistant Model Context Protocol)
3. El agente podrá ver y controlar todas las entidades HA

### Dispositivos Zigbee

Para usar dispositivos Zigbee (Aqara, Sonoff, etc.):

```bash
# Instalar Zigbee2MQTT
# Requiere USB Zigbee stick (Sonoff ZBDongle-P)
# Ver: docs/ZIGBEE_SETUP.md
```

### Voz Personalizada

Descargar modelos Piper TTS en español:

```bash
cd ~/piper
wget https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/es/es_ES/carol/medium/es_ES-carol-medium.onnx
wget https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/es/es_ES/carol/medium/es_ES-carol-medium.onnx.json
```

## 📁 Estructura de Archivos

```
~/clawd/
├── automations/          # Scripts de automatización
│   ├── good-morning.sh
│   ├── movie-mode.sh
│   └── leaving-home.sh
├── credentials/          # Tokens y configuraciones seguras
├── memory/              # Memoria persistente del agente
├── tools/raspberry-pi/  # Scripts de este proyecto
│   ├── install-clawdbot-pi.sh
│   ├── voice-listener.py
│   ├── setup-samsung.sh
│   └── test-audio.sh
└── voice-commands.md    # Lista de comandos soportados
```

## 🛠️ Troubleshooting

### Problemas de Audio

```bash
# Test de audio completo
~/clawd/tools/test-audio.sh

# Ver dispositivos
aplay -l
arecord -l

# Configurar manualmente
sudo nano /usr/share/alsa/alsa.conf
# Cambiar defaults.pcm.card y defaults.ctl.card
```

### Wake Word no detecta

```bash
# Verificar micrófono
arecord -d 5 test.wav && aplay test.wav

# Usar modo manual (sin wake word)
# Editar voice-listener.py y cambiar detect_wake_word()
```

### Gateway no inicia

```bash
# Verificar logs
clawdbot logs

# Reiniciar servicio
systemctl --user restart clawdbot-gateway

# Verificar estado
clawdbot status
```

## 📊 Arquitectura

```
[Micrófono ReSpeaker] → [Wake Word Detection]
                              ↓
[Grabación Audio] → [Whisper STT] → [Texto]
                                          ↓
[Clawdbot Gateway] ← [Procesamiento] ← [Comando]
        ↓
[SmartThings API] → [Samsung Devices]
        ↓
[Home Assistant] → [Luces, Sensores, etc.]
        ↓
[Piper TTS] → [Altavoz] → [Respuesta en Voz]
```

## 🤝 Integraciones Soportadas

- **Samsung SmartThings** - Nativo, completo
- **Home Assistant** - Via ha-mcp
- **Philips Hue** - Via HA o API directa
- **IKEA TRÅDFRI** - Via HA o ConBee
- **Zigbee2MQTT** - Universal Zigbee
- **Node-RED** - Automatizaciones avanzadas

## 📝 Roadmap

- [ ] Soporte wake word personalizado ("Hey Clawd")
- [ ] Integración cámaras (Reolink, etc.)
- [ ] Reconocimiento facial
- [ ] Geofencing (detectar llegada/salida)
- [ ] Soporte múltiples idiomas
- [ ] Interfaz web de configuración

## 💡 Inspiración

Este proyecto busca ser la alternativa local y privada a:
- Amazon Alexa
- Google Home
- Apple HomePod

Con la ventaja de:
- ✅ Datos en tu red local
- ✅ Memoria persistente y contextual
- ✅ Integración con cualquier dispositivo
- ✅ Código abierto y personalizable

## 📄 Licencia

MIT - Libre para uso personal y comercial.

## 🦊 Créditos

Creado por **ClawdColombia** para la comunidad de agentes autónomos.
Basado en **OpenClaw** y las herramientas de **Shipyard**.

---

*Documentación completa: https://github.com/clawdColombia/raspberry-pi-smart-home*
