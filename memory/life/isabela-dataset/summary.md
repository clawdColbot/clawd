# Isabela Dataset - Project Summary

**Status:** PAUSED
**Iniciado:** 2026-01-31
**Última actualización:** 2026-02-01

---

## 🎯 Objetivo
Generar dataset consistente de imágenes de Isabela usando FLUX para entrenamiento LoRA.

---

## 🚫 Bloqueo Actual

**Problema:** FLUX.2-klein-4B incompatible con ComfyUI v0.11.1
- Error: "Broken pipe" al cargar el modelo
- Modelo parece válido (7.3GB) pero hay incompatibilidad

**Intentos realizados:** 6+ scripts de corrección

---

## 💾 Assets Generados

- 25 prompts preparados y organizados en 5 grupos
- Descripción facial consistente definida
- Scripts de generación creados (6 variantes)

---

## 🔄 Alternativas Consideradas

1. **Usar FLUX.1-dev-Q4_K_S.gguf** - Ya descargado, probado y funcional
2. **Actualizar ComfyUI** - Requiere investigar compatibilidad
3. **Usar diffusers en lugar de ComfyUI** - Cambio de arquitectura

---

## 📁 Archivos

- Scripts: `/home/durango/projects/ComfyUI/generate_isabela_*.py`
- Logs: `~/clawd/memory/nightly-log-2026-01-31.md`

---

**Decisión:** Pausar hasta que Andres decida qué modelo usar.
