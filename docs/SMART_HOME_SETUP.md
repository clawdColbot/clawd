# 🏠 Smart Home Setup - Plan de Implementación

## Fase 0: Base (Comprar Primero)

### Hardware Esencial

| Item | Modelo Recomendado | Precio USD | Prioridad |
|------|-------------------|------------|-----------|
| **Raspberry Pi 5** | 8GB RAM + Fuente 27W oficial | $100-120 | 🔴 CRÍTICO |
| **MicroSD/SSD** | Samsung Pro Plus 128GB o NVMe HAT | $30-50 | 🔴 CRÍTICO |
| **Micrófono** | ReSpeaker Lite HAT para Pi 5 | $35 | 🔴 CRÍTICO |
| **Case** | Argon NEO 5 (con NVMe soporte) | $30 | 🟡 Media |
| **Altavoz** | Cualquiera Jack 3.5mm o USB | $20 | 🟡 Media |

**Subtotal Fase 0:** ~$215-255

---

## Fase 1: Samsung Integration (Ya lo tienes)

### Dispositivos Samsung
- ✅ Samsung Smart Music Frame (SmartThings compatible)
- ✅ Samsung TV Serie 7 (Tizen OS, SmartThings)

### Setup
1. Crear cuenta SmartThings
2. Conectar Music Frame y TV a SmartThings
3. Enviar token a Clawdbot para integración

**Capacidades inmediatas:**
- "Clawd, pon música romántica en el cuarto"
- "Clawd, sube el volumen del Music Frame"
- "Clawd, apaga la TV"
- "Clawd, pon Netflix en la TV del living"

---

## Fase 2: Iluminación Inteligente

### Opción A: Philips Hue (Más caro, mejor integración)
| Item | Precio USD | Notas |
|------|------------|-------|
| Hue Bridge v2 | $50 | Necesario obligatorio |
| Bulbs White & Color (4x) | $45 c/u = $180 | Living, cuartos |
| Lightstrip Plus 2m | $80 | Detrás del TV |
| Dimmer Switch | $25 | Control físico backup |

**Total Hue:** ~$335

### Opción B: IKEA TRÅDFRI (Económica, compatible)
| Item | Precio USD | Notas |
|------|------------|-------|
| Gateway TRÅDFRI | $35 | Bridge |
| Bulbs (4x) | $10 c/u = $40 | Blanco espectro |
| Control remoto | $15 | Backup físico |

**Total IKEA:** ~$90

### Opción C: Zigbee Genérico (Tuya/Gledopto) - Más técnico
| Item | Precio USD | Notas |
|------|------------|-------|
| Zigbee USB Stick (Sonoff ZBDongle-P) | $25 | Para Home Assistant |
| Bulbs RGB (4x) | $15 c/u = $60 | Compatible Zigbee 3.0 |

**Total Zigbee:** ~$85 + requiere más configuración

**Recomendación:** Empezar con IKEA (barato, bueno), migrar a Hue si necesitas más features.

---

## Fase 3: Switches y Enchufes Inteligentes

### Switches de Pared (Requieren instalación eléctrica)
| Ubicación | Tipo | Precio | Notas |
|-----------|------|--------|-------|
| Living principal | Switch dimmer Zigbee | $25 | Reemplaza switch existente |
| Cuartos (2x) | Switch on/off Zigbee | $20 c/u | Control de luces de techo |
| Entrada | Switch 3-way | $30 | Control desde 2 puntos |

### Enchufes Inteligentes (Plug & Play)
| Cantidad | Uso | Precio c/u | Total |
|----------|-----|------------|-------|
| 2x | Aire acondicionado | $15 | $30 |
| 2x | Lámparas de pie | $12 | $24 |
| 1x | Cafetera | $15 | $15 |
| 1x | Humidificador | $12 | $12 |

**Marca recomendada:** Sonoff S31 o TP-Link Kasa (buena integración HA)

---

## Fase 4: Sensores (Seguridad y Automatización)

### Core Sensors
| Sensor | Cantidad | Precio c/u | Uso |
|--------|----------|------------|-----|
| Movimiento PIR | 3 | $15 | Living, entrada, pasillo |
| Puerta/Ventana | 4 | $10 | Puerta entrada, ventanas |
| Temperatura/Humedad | 3 | $12 | Cuartos, living |
| Humo/CO | 2 | $25 | Cocina, pasillo |
| Fuga de agua | 2 | $15 | Baño, cocina |

**Marca:** Aqara (buena batería, compatible Zigbee)

---

## Fase 5: Cerradura y Cámaras (Seguridad)

### Cerradura Inteligente
- **Yale YRD256** (Zigbee) - $250
- O **August Wi-Fi** - $200
- O **Nuki Smart Lock 3.0** (Europa) - $200

### Cámaras
| Ubicación | Modelo | Precio |
|-----------|--------|--------|
| Entrada | Reolink Doorbell PoE | $90 |
| Living | Reolink E1 Pro | $50 |
| Exterior | Reolink RLC-520A | $65 |

---

## 💰 Resumen de Inversiones

### Setup Mínimo (Funcional)
| Fase | Items | Costo |
|------|-------|-------|
| 0 | Pi 5 + Micrófono + SD | $215 |
| 1 | Samsung (ya tienes) | $0 |
| 2 | IKEA iluminación básica | $90 |
| 3 | 4 enchufes inteligentes | $60 |
| 4 | 3 sensores de movimiento | $45 |
| | **Total Mínimo** | **~$410** |

### Setup Completo (Todo automatizado)
| Fase | Costo |
|------|-------|
| 0-1 | $215 |
| 2 | $335 (Hue premium) |
| 3 | $150 (switches + enchufes) |
| 4 | $200 (sensores completos) |
| 5 | $400 (cerradura + cámaras) |
| | **Total Completo** | **~$1,300** |

---

## 🛒 Plan de Compras Sugerido

### Compra Inmediata (Esta semana)
1. ✅ Raspberry Pi 5 8GB kit ($120)
2. ✅ ReSpeaker Lite HAT ($35)
3. ✅ Samsung SmartThings Hub (o usar Pi con Zigbee stick)

### Compra Fase 1 (Próximo mes)
1. IKEA TRÅDFRI gateway + 2 bombillas ($55)
2. 4 enchufes Sonoff ($60)
3. 3 sensores Aqara movimiento ($45)

### Expansiones Futuras
- Upgrade a Philips Hue si IKEA no es suficiente
- Cerradura inteligente
- Cámaras de seguridad
- Robots aspiradora (Roomba/SwitchBot)

---

## 🔌 Diagrama de Conectividad

```
[Internet]
    │
[Raspberry Pi 5] ←────── [Clawdbot Gateway]
    │                           │
    ├── Zigbee USB Stick ──────┼── [Bombas IKEA/Hue]
    │                           ├── [Switches pared]
    │                           ├── [Sensores Aqara]
    │                           └── [Enchufes Sonoff]
    │
    ├── WiFi ───────────────────── [Samsung Music Frame]
    │                           └── [Samsung TV]
    │
    └── Audio Jack ─────────── [Altavoz]
```

---

## 🎯 Primeras Automatizaciones (Día 1)

Cuando esté todo instalado:

### Escena "Buenos Días"
- Decir: "Clawd, buenos días"
- Acciones:
  1. Gradualmente subir luces (simular amanecer)
  2. Poner música suave en Music Frame
  3. Anunciar clima y agenda del día
  4. Preparar cafetera (si enchufe inteligente)

### Escena "Me Voy de Casa"
- Decir: "Clawd, me voy"
- Acciones:
  1. Apagar todas las luces
  2. Apagar TV y Music Frame
  3. Activar modo "Away" (sensores armados)
  4. Confirmar: "Casa segura. Hasta luego."

### Escena "Noche de Película"
- Decir: "Clawd, modo cine"
- Acciones:
  1. Bajar luces al 20%
  2. Poner TV en modo película
  3. Cerrar cortinas (si motorizadas)

---

## ⚠️ Consideraciones Técnicas

### Electricidad (Colombia)
- Voltaje: 110V (igual que USA)
- Enchufes: Tipo A/B (Americanos)
- ✅ Todo el hardware recomendado es compatible

### Instalación Switches de Pared
- **SI** tienes neutro en la caja: Cualquier switch smart funciona
- **NO** tienes neutro: Necesitas switches específicos (más caros)
- Recomendación: Llamar electricista para revisar cajas ($50-100)

### WiFi vs Zigbee
- **WiFi:** Más fácil, más saturación de red
- **Zigbee:** Malla mesh, más confiable, menos latencia
- **Recomendación:** Zigbee para sensores/switches, WiFi solo para TV/Music Frame

---

## 📋 Lista de Verificación Compra

- [ ] Raspberry Pi 5 8GB
- [ ] Fuente oficial 27W USB-C
- [ ] ReSpeaker Lite HAT
- [ ] MicroSD 128GB clase A2
- [ ] (Opcional) Argon NEO 5 case
- [ ] Altavoz Bluetooth/Jack
- [ ] Zigbee USB Stick (Sonoff ZBDongle-P)

**Próximo mes:**
- [ ] IKEA TRÅDFRI gateway
- [ ] 4x bombas IKEA
- [ ] 4x enchufes Sonoff
- [ ] 3x sensores Aqara movimiento

---

*Documento creado: 2026-01-31*
*Próxima revisión: Cuando compres la Pi*
