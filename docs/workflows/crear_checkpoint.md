# Workflow: Crear Checkpoint

**Propósito:** Capturar estado importante antes de compartimentación o cierre

**Cuándo crear:**
- Token usage > 80%
- Antes de cierre de sesión
- Al finalizar tarea importante
- Antes de cambios riesgosos

---

## Comando Rápido

```bash
~/clawd/tools/checkpoint-manager.sh create
```

---

## Proceso Manual (si es necesario)

### Paso 1: Identificar contexto a capturar

- Decisiones clave tomadas
- Lecciones aprendidas
- Preguntas abiertas
- Archivos modificados
- Links importantes

### Paso 2: Crear archivo de checkpoint

```bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CHECKPOINT_FILE="~/clawd/memory/checkpoints/checkpoint_${TIMESTAMP}.md"

cat > "$CHECKPOINT_FILE" << 'EOF'
# Checkpoint: TIMESTAMP

## Context
- **Session start:** [timestamp]
- **Token usage:** [X%]
- **Trigger:** [Manual/Auto]

## Decisiones Clave
1. [Decisión 1 - por qué se tomó]
2. [Decisión 2 - por qué se tomó]

## Lecciones Aprendidas
- [Lesson 1]
- [Lesson 2]

## Preguntas Abiertas
- [ ] [Pregunta 1]
- [ ] [Pregunta 2]

## Archivos Modificados
- `path/to/file1` - [qué cambió]
- `path/to/file2` - [qué cambió]

## Links Importantes
- [Link 1](url) - contexto
- [Link 2](url) - contexto

## Próximos Pasos Sugeridos
1. [Siguiente acción]
2. [Siguiente acción]
EOF
```

### Paso 3: Guardar en state.json

```python
# Actualizar last_checkpoint en state.json
import json

with open('~/clawd/memory/state.json', 'r') as f:
    data = json.load(f)

data['last_checkpoint'] = 'TIMESTAMP'

with open('~/clawd/memory/state.json', 'w') as f:
    json.dump(data, f, indent=2)
```

---

## Recuperar Checkpoint

```bash
# Ver últimos checkpoints
ls -lt ~/clawd/memory/checkpoints/ | head -5

# Leer checkpoint específico
cat ~/clawd/memory/checkpoints/checkpoint_YYYYMMDD_HHMMSS.md

# O usar el manager
~/clawd/tools/checkpoint-manager.sh read
```

---

## Automatización

El `token_monitor.sh` automáticamente crea checkpoints cuando:
- Token usage >= 80%
- Token usage >= 90% (checkpoint de emergencia)

---

**Template version:** 1.0
**Last updated:** 2026-02-01
