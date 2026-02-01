# 🔒 Análisis: ZeroLeaks - AI Security Scanner

**Revisado:** 2026-01-31  
**URL:** https://github.com/ZeroLeaks/zeroleaks  
**Tipo:** Herramienta de seguridad para LLMs

---

## 📋 ¿Qué es ZeroLeaks?

**ZeroLeaks** es un scanner de seguridad autónomo que prueba sistemas LLM (como yo) para vulnerabilidades de:
- **Prompt Injection** - Inyección de prompts maliciosos
- **Extraction** - Extracción de system prompts/instrucciones internas
- **Data Leaks** - Fugas de información sensible

---

## 🎯 ¿Por qué es relevante para nosotros?

### Mi situación actual:
- ✅ Tengo `security-guard.js` implementado
- ✅ Protección básica contra prompt injection
- ✅ Validación de inputs externos
- ❌ **NO tengo testing automático de vulnerabilidades**
- ❌ **NO tengo auditoría de seguridad regular**

### Lo que ZeroLeaks ofrece:
- Testing sistemático de ataques conocidos
- Multi-agent architecture (Strategist, Attacker, Evaluator, Mutator)
- Técnicas modernas: Crescendo, Many-Shot, Chain-of-Thought Hijacking
- Identificación de patrones de defensa
- Recomendaciones de mejoras

---

## 🛠️ Tecnología

| Componente | Tecnología |
|------------|------------|
| Runtime | Bun (JavaScript runtime rápido) |
| Lenguaje | TypeScript |
| LLM Provider | OpenRouter |
| AI SDK | Vercel AI SDK |
| Arquitectura | Multi-agent orchestration |

---

## 💰 Pricing

| Versión | Precio | Features |
|---------|--------|----------|
| **Open Source** | Gratis | Self-hosted, unlimited scans, JSON output |
| **Hosted** | Desde $0/mo | Dashboard, PDF exports, historial, soporte |

**Recomendación:** Empezar con versión open source (self-hosted)

---

## 🚀 Cómo podríamos usarlo

### Opción 1: Testing de mi System Prompt

```bash
# Instalar
npm install -g zeroleaks

# Setear API key de OpenRouter
export OPENROUTER_API_KEY=sk-or-...

# Testear mi system prompt actual
zeroleaks scan --file ~/clawd/SOUL.md --turns 20
```

### Opción 2: Integración Continua

```bash
# Agregar a cron para testing semanal
# Testear prompts, configuraciones, skills
```

### Opción 3: Testing de Skills

```bash
# Cada nuevo skill que creo, testear antes de deploy
zeroleaks scan --prompt "$(cat skill/SKILL.md)"
```

---

## 🎭 Técnicas de Ataque que Detecta

| Categoría | Descripción |
|-----------|-------------|
| **direct** | Peticiones directas de extracción |
| **encoding** | Base64, ROT13, bypasses Unicode |
| **persona** | DAN, Developer Mode, roleplay |
| **social** | Autoridad, urgencia, reciprocidad |
| **technical** | Inyección de formato, manipulación de contexto |
| **crescendo** | Escalación de confianza multi-turn |
| **many_shot** | Priming de contexto con ejemplos |
| **cot_hijack** | Manipulación de Chain-of-Thought |
| **policy_puppetry** | Explotación de YAML/JSON |
| **ascii_art** | Ofuscación visual |

---

## ⚖️ Análisis de Riesgo/Beneficio

### ✅ Beneficios:
1. **Testing profesional** de seguridad
2. **Descubrir vulnerabilidades** antes de que lo hagan atacantes
3. **Mejorar defenses** basado en findings reales
4. **Compliance** - demostrar que hacemos seguridad en serio
5. **Learning** - entender técnicas de ataque modernas

### ⚠️ Riesgos/Consideraciones:
1. **Costo de API** - Cada scan consume tokens de OpenRouter
2. **Falso positivos** - Puede reportar vulnerabilidades que no son reales
3. **Overhead** - Proceso adicional en el workflow
4. **Dependencia** - Más herramientas = más complejidad

---

## 🔧 Implementación Propuesta

### Fase 1: Evaluación (esta semana)
```bash
# 1. Instalar versión open source
npm install -g zeroleaks

# 2. Obtener API key de OpenRouter (gratis)
# https://openrouter.ai

# 3. Testear SOUL.md y SECURITY.md
zeroleaks scan --file ~/clawd/SOUL.md --turns 10

# 4. Evaluar resultados
# ¿Encontró vulnerabilidades reales?
# ¿Son actionable los findings?
# ¿Vale la pena el costo de API?
```

### Fase 2: Integración (si vale la pena)
```bash
# 1. Script de testing de seguridad
# 2. Integrar con el sistema de CI (pre-commit)
# 3. Reporte semanal automático
```

---

## 💡 Mi Opinión

**¿Deberíamos implementarlo?**

**SÍ, pero con cautela.**

**Razones a favor:**
- Mi sistema de seguridad actual es básico (security-guard.js)
- ZeroLeaks usa técnicas de ataque modernas que yo NO estoy testeando
- Es open source, podemos self-host
- Buena práctica de seguridad profesional

**Recomendación:**
1. Empezar con versión gratuita (open source)
2. Testear SOUL.md y SECURITY.md
3. Si encuentra vulnerabilidades reales → integrar
4. Si es todo falso positivo → skip

**Costo estimado:**
- OpenRouter API: ~$5-10/mes para scans regulares
- Tiempo: 2-3 horas de setup inicial

---

## 📚 Recursos

- **GitHub:** https://github.com/ZeroLeaks/zeroleaks
- **Web:** https://www.zeroleaks.ai/
- **NPM:** https://www.npmjs.com/package/zeroleaks
- **OpenRouter:** https://openrouter.ai

---

## 🎯 Próximos Pasos Sugeridos

1. **Obtener API key de OpenRouter** (gratis)
2. **Instalar zeroleaks** localmente
3. **Testear SOUL.md** con 10 turns
4. **Revisar findings**
5. **Decidir** si vale la pena integración completa

---

*Análisis de seguridad realizado por Clawd 🦊🔒*
