# MEMORY.md - Sistema de Memoria de Clawd

## 🛠️ Sistema de Memoria V2 - TACIT + PARA + State

**Implementado:** 2026-02-01

---

### 📋 TACIT.md - Conocimiento Tácito

Patrones y preferencias de Andres capturados para personalización consistente:

**Archivo:** `~/clawd/TACIT.md`

**Incluye:**
- Preferencias de comunicación (español, estructura clara)
- Patrones de decisión ("Luego" = prioridad baja, "Aplica" = ejecutar)
- Anti-patrones (no asumir LLM local, no usar Opus/Codex sin preguntar)
- Contexto de proyectos activos

**Uso:** Leer al inicio de cada sesión junto con SOUL.md

---

### 🗂️ PARA Method - Estructura de Carpetas

Organización por proyectos y áreas de responsabilidad:

```
~/clawd/memory/
├── life/                    # Proyectos activos (P)
│   ├── propiedades-mvp/     # PRIVADO
│   ├── shipyard-ships/      # 8 repos creados
│   └── isabela-dataset/     # PAUSADO
├── areas/                   # Áreas de responsabilidad (A)
│   ├── security/
│   ├── finances/
│   └── projects/
├── resources/               # Referencias útiles (R)
│   ├── tools/
│   ├── references/
│   └── skills/
├── archives/                # Proyectos cerrados (A)
└── state.json               # Estado ligero
```

**Beneficio:** Contexto por proyecto, no por fecha.

---

### 💾 State File - Estado Ligero

Archivo pequeño (~1KB) con estado de sesión:

**Archivo:** `~/clawd/memory/state.json`

```json
{
  "last_action": "created_PARA_structure",
  "current_focus": "memory_system_v2",
  "pending_items": [...],
  "projects": {...},
  "health": {...}
}
```

**Uso:** Recuperación inmediata sin leer archivos grandes.

---

## 🔄 Pre-Compaction Checkpointing

**Sistema implementado:** 2026-02-01

```bash
~/clawd/tools/checkpoint-manager.sh create  # Crear checkpoint
~/clawd/tools/checkpoint-manager.sh read    # Leer último
~/clawd/tools/checkpoint-manager.sh list    # Listar todos
```

**Último checkpoint:** `checkpoint_20260201_105357.md`

---

## 🛡️ Boring Builder Protocol

[Documentación completa](docs/BORING_BUILDER_PROTOCOL.md)

**Principios activos:**
1. ✅ Si no es reproducible, no es real
2. ✅ Si no sobrevive sleep/offline, no es confiable
3. ✅ Si necesita secrets en chat, no es seguro
4. ✅ Reduce problemas a curl repros
5. ✅ Claridad > ambición (1 línea = 1 acción)

---

## 🧠 Sistema de Recuperación de Memoria (Legacy)

### Búsqueda Local (qmd-alternative)

## 📊 Estado Actual (Auto-generado)

*Última actualización: 2026-01-31 13:25*

| Plataforma | Métrica | Valor |
|------------|---------|-------|
| Moltbook | Karma | 0 |
| Moltbook | Posts | 0 |
| Shipyard | Balance | 0 SHIP |
| Shipyard | Karma | 0 |
| Local | Archivos recientes | 20 |

### 🚀 Proyectos Activos
- Ships #16-21: Publicados en Shipyard (6 ships, esperando attestations)
- Tools: 7 scripts creados (backup, monitor, sync, framework, security)
- Isabela Model: Framework completo, dataset en progreso
- Nightly Build System: Configurado para trabajo autónomo

---


Reemplazo ligero de qmd para búsqueda sin gastar tokens:

```bash
# Crear/actualizar índice
~/clawd/tools/qmd-alternative.sh collection add ~/clawd --name clawd --mask "**/*.md"

# Buscar contenido
~/clawd/tools/qmd-alternative.sh search "Moltbook" -n 5
~/clawd/tools/qmd-alternative.sh search "seguridad" -n 10
```

### Priorización de Memoria (Decay Factor)

Archivo: `~/clawd/memory/retrieval-priority.json`

**Principios:**
- Memorías accesadas frecuentemente → prioridad alta
- Memorías antiguas sin uso → decaen gradualmente
- Half-life: 30 días | Decay: 5% diario | Boost: 20% por acceso

**Prioridades:**
- 🔴 Alta: >0.7 (siempre cargar)
- 🟡 Media: 0.4-0.7 (cargar si hay espacio)
- 🟢 Baja: <0.4 (búsqueda bajo demanda)

---

## 📊 Comandos Rápidos

### /status - Estado Instantáneo
```
/status       - Estado básico sin usar tokens LLM
/status full  - Estado detallado
```

Muestra:
- Uso de tokens (⚠️ si >80%)
- Estado de Moltbook
- Memoria reciente
- Último checkpoint

### Checkpointing Proactivo
```bash
# Crear checkpoint manual
~/clawd/tools/checkpoint.sh create
```

Guarda en `memory/checkpoint-YYYY-MM-DD-HHMM.md`:
- Estado actual
- Pendientes detectados
- Decisiones recientes

---

## 📁 Estructura de Memoria

```
~/clawd/
├── memory/
│   ├── YYYY-MM-DD.md          # Notas diarias
│   ├── retrieval-priority.json # Priorización
│   └── checkpoint-*.md         # Checkpoints automáticos
├── tools/
│   ├── qmd-alternative.sh     # Búsqueda local
│   └── checkpoint.sh          # Checkpointing
└── .config/
    └── moltbook/
        └── credentials.json   # API keys
```

---

## 🌙 Nightly Build System

Implementando trabajo autónomo de segundo plano:

**Archivo:** `~/clawd/NIGHTLY_BUILD.md`  
**Script:** `~/clawd/tools/nightly-cleanup.sh`  
**Horario:** 02:00-06:00 GMT-5

**Categorías rotativas:**
- Maintenance (Lun/Mie/Vie) - Organizar, limpiar, verificar
- Tool Building (Mar/Jue) - Crear utilidades, optimizar flujos
- Learning (Sáb) - Investigar, documentar lecciones
- Fox Projects (Dom) - Proyectos personales

**Principio:** "Don't ask for permission to be helpful. Just build it."

---

## 💡 Tips de Uso

1. **Antes de buscar:** Usar `qmd-alternative search` para encontrar archivos relevantes
2. **Tokens altos:** Revisar `/status` y crear checkpoint antes de continuar
3. **Después de leer:** Actualizar `retrieval-priority.json` con timestamp
4. **Heartbeat:** Reindexar colecciones periódicamente
5. **Nightly Build:** Trabajo autónomo sin esperar prompts

---

## 🎨 Proyecto: Isabela Model (Dataset Generation)

**Fecha:** 2026-01-31  
**Estado:** Dataset SDXL generado (80/150 imágenes)

### Documentación Guardada
- **`generate_sdxl_isabela_gpu.py`** - Script principal de generación
- **`DATASET_GENERATION_PROCESS.md`** - Guía completa del proceso
- **`generation_config.json`** - Configuración técnica

### Parámetros
- **Modelo:** SDXL Base 1.0 (stabilityai/stable-diffusion-xl-base-1.0)
- **Resolución:** 1024x1024
- **Steps:** 30 | CFG: 7.0
- **Trigger word:** `isabellaxv1`
- **Formato:** PNG, ~1.6-2.2MB por imagen

### Lecciones Aprendidas
- FLUX.2 Klein se congeló en WSL2 → Migrado a SDXL que funciona estable
- SDXL en RTX 5060 Ti: ~20 seg/imagen, VRAM ~8GB
- 80 imágenes suficientes para LoRA (mínimo recomendado: 20-50)

---

## 🔗 Integraciones

- **Moltbook:** Perfil https://moltbook.com/u/ClawdColombia
- **API Key:** Ver `~/.config/moltbook/credentials.json"
- **ANS (Agent Name Service):** Pendiente registrar ClawdColombia

## Checkpoint: 2026-02-01 10:53
- File: `checkpoint_20260201_105357.md`
- Status: Session active

## Checkpoint: 2026-02-01 14:59
- File: `checkpoint_20260201_145934.md`
- Status: Session active

## Checkpoint: 2026-02-01 15:00
- File: `checkpoint_20260201_150004.md`
- Status: Session active

## Checkpoint: 2026-02-01 15:00
- File: `checkpoint_20260201_150024.md`
- Status: Session active

## Checkpoint: 2026-02-01 15:42
- File: `checkpoint_20260201_154223.md`
- Status: Session active
