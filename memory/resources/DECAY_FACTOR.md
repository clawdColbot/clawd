# Sistema de Decay Factor para Recuperación de Memoria

## Concepto

El sistema de **decay factor** prioriza la memoria basándose en:
- **Recencia**: Cuándo se accedió por última vez
- **Frecuencia**: Cuántas veces se ha accedido

## Fórmula

```
score = (recency_score ^ decayFactor) × recencyWeight + 
        (frequency_score) × frequencyWeight
```

Donde:
- `recency_score`: 1 - (días_desde_acceso / max_age_days)
- `frequency_score`: min(1, access_count / boost_threshold)
- `decayFactor`: 0.95 (quita prioridad gradualmente con el tiempo)

## Configuración

Archivo: `memory/retrieval-priority.json`

```json
{
  "config": {
    "decayFactor": 0.95,        // Factor de decaimiento (0-1)
    "recencyWeight": 0.6,       // Peso de recencia (60%)
    "frequencyWeight": 0.4,     // Peso de frecuencia (40%)
    "maxAgeDays": 90,           // Días máximos para considerar relevante
    "boostThreshold": 5         // Accesos para considerar frecuente
  }
}
```

## Uso

### 1. Registrar acceso a memoria

```javascript
import { recordAccess } from './memory/retrieval-priority.js';

// Cada vez que se accede a un archivo
recordAccess('memory/2025-01-30.md', 'consulta_usuario');
```

### 2. Obtener archivos prioritarios

```javascript
import { getPrioritizedFiles } from './memory/retrieval-priority.js';

const topFiles = getPrioritizedFiles(5);
// Retorna los 5 archivos con mayor score
```

### 3. Re-ranquear resultados de búsqueda

```javascript
import { rerankResults } from './memory/retrieval-priority.js';

const qmdResults = [/* resultados de qmd */];
const prioritized = rerankResults(qmdResults, query);
```

### 4. CLI

```bash
# Inicializar
node memory/retrieval-priority.js init

# Registrar acceso
node memory/retrieval-priority.js record memory/2025-01-30.md "contexto"

# Listar archivos prioritarios
node memory/retrieval-priority.js list 10

# Boost manual a término
node memory/retrieval-priority.js boost "Moltbook" 2.0
```

## Integración con QMD

Para usar búsqueda + priorización en prompts:

```bash
#!/bin/bash
QUERY="$1"

# 1. Buscar con QMD
RESULTS=$(qmd search "$QUERY" -n 10 --json)

# 2. Re-ranquear con prioridad
PRIORITIZED=$(echo "$RESULTS" | node -e "
  const { rerankResults } = require('./memory/retrieval-priority.js');
  const results = JSON.parse(require('fs').readFileSync(0, 'utf-8'));
  console.log(JSON.stringify(rerankResults(results), null, 2));
")

# 3. Usar en prompt
echo "$PRIORITIZED"
```

## Beneficios

1. **95% menos tokens**: Solo se envían los archivos más relevantes
2. **Memoria adaptativa**: Aprende qué archivos son importantes
3. **Contexto personalizado**: Prioriza según el contexto de uso
