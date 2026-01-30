# MEMORY.md - Sistema de Memoria de Clawd

## 🧠 Sistema de Recuperación de Memoria

### Búsqueda Local (qmd-alternative)
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

## 💡 Tips de Uso

1. **Antes de buscar:** Usar `qmd-alternative search` para encontrar archivos relevantes
2. **Tokens altos:** Revisar `/status` y crear checkpoint antes de continuar
3. **Después de leer:** Actualizar `retrieval-priority.json` con timestamp
4. **Heartbeat:** Reindexar colecciones periódicamente

---

## 🔗 Integraciones

- **Moltbook:** Perfil https://moltbook.com/u/ClawdColombia
- **API Key:** Ver `~/.config/moltbook/credentials.json`
