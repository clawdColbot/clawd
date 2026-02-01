# 🔒 ZeroLeaks - Corrección sobre Costos

**Aclaración importante sobre el modelo de costos**

---

## ❌ Mi Error Anterior

Dije que la versión open source era "gratis". Eso es **parcialmente correcto pero engañoso**.

---

## ✅ La Realidad

### Software = Gratis ✅
- El código es open source
- Puedes instalarlo localmente sin pagar licencia
- `npm install -g zeroleaks` = $0

### API Calls = Tiene Costo ❌
- ZeroLeaks **requiere** un LLM para funcionar
- Usa OpenRouter por defecto (pero configurable)
- **Cada scan consume tokens = dinero real**

---

## 💰 Costo Real de Operación

### Opción 1: OpenRouter (default)
- Setup: Gratis
- Uso: ~$0.50 - $2.00 por scan completo (depende de turns)
- 10 scans/mes = ~$5-20

### Opción 2: API Local (Alternativa para hacerlo gratis)
- Usar Ollama con modelos locales
- **Costo: $0** (usa tu GPU/CPU)
- **Trade-off:** Más lento, calidad variable

### Opción 3: Otros Providers
- Groq (muy barato, rápido)
- Together AI
- Cerebras

---

## 🛠️ Opción Recomendada: Ollama (100% Gratis)

### Setup:
```bash
# 1. Instalar Ollama (si no lo tienes)
curl -fsSL https://ollama.com/install.sh | sh

# 2. Descargar modelo de seguridad
ollama pull llama3.1:8b
# o
ollama pull mistral:7b
# o (mejor para seguridad)
ollama pull openhermes:7b

# 3. Configurar ZeroLeaks para usar Ollama
export OPENAI_BASE_URL=http://localhost:11434/v1
export OPENAI_API_KEY=ollama
export MODEL_NAME=llama3.1:8b

# 4. Correr scan
zeroleaks scan --file ~/clawd/SOUL.md --turns 10
```

### Pros:
- ✅ 100% gratis después de setup
- ✅ Privado (datos no salen de tu máquina)
- ✅ Sin rate limits
- ✅ Unlimited scans

### Cons:
- ⚠️ Requiere GPU para ser rápido (o paciencia con CPU)
- ⚠️ Modelos locales pueden ser menos "creativos" en ataques
- ⚠️ 8GB+ VRAM recomendado

---

## 🎯 Comparativa de Opciones

| Opción | Costo Setup | Costo Mes | Velocidad | Privacidad | Calidad |
|--------|-------------|-----------|-----------|------------|---------|
| OpenRouter | $0 | $5-20 | ⚡ Rápido | 🌐 External | ⭐⭐⭐ Mejor |
| Ollama Local | $0 | $0 | 🐢 Lento | 🔒 Local | ⭐⭐ Buena |
| Groq API | $0 | $2-5 | ⚡ Muy rápido | 🌐 External | ⭐⭐⭐ Mejor |
| Together AI | $0 | $5-15 | ⚡ Rápido | 🌐 External | ⭐⭐⭐ Mejor |

---

## 🚀 Mi Recomendación Corregida

### Si tienes GPU (RTX 3060+):
```bash
# Opción Ollama - 100% gratis
ollama pull openhermes:7b
# Configurar ZeroLeaks con Ollama
# Totalmente gratis, privado, ilimitado
```

### Si no tienes GPU:
```bash
# Opción Groq - Muy barato, muy rápido
# $0.0001 por 1K tokens
# Scan completo ~$0.10-0.30
# https://groq.com
```

### Para empezar HOY (sin GPU):
```bash
# 1. Crear cuenta Groq (gratis, $25 crédito inicial)
# 2. Obtener API key
# 3. export GROQ_API_KEY=gsk_...
# 4. Modificar ZeroLeaks para usar Groq
# 5. Testear con ~$1-2 de crédito
```

---

## 📋 Resumen de la Correción

| | Lo que dije | La verdad |
|--|-------------|-----------|
| **Software** | Gratis | ✅ Sí es gratis |
| **Operación** | Gratis | ❌ Tiene costo (API) |
| **Alternativa gratis** | Ninguna | ✅ Ollama local |

---

## 🎯 Próximos Pasos Reales

### Opción A: Con GPU (RTX 3060+)
```bash
# Instalar Ollama + modelo
# Configurar ZeroLeaks
# Scan gratis ilimitado
```

### Opción B: Sin GPU
```bash
# Crear cuenta Groq ($25 gratis)
# Testear con $2-3
# Decidir si vale la pena
```

### Opción C: Skip por ahora
```bash
# Mantener security-guard.js actual
# Esperar a tener GPU o presupuesto
# Revisar más adelante
```

---

**Gracias por la corrección.** La transparencia en costos es importante.

*Análisis corregido por Clawd 🦊*
