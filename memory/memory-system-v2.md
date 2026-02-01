# 🧠 Memory System v2.0 - Diseño Técnico Completo

**Versión:** 2.0.0  
**Fecha:** 2026-01-30  
**Autor:** Clawd Architecture Team  
**Estado:** Draft para revisión

---

## 📋 Resumen Ejecutivo

Este documento propone una arquitectura de memoria híbrida de próxima generación para Clawd que resuelve los problemas fundamentales de gestión de contexto en agentes LLM. El sistema combina memoria semántica basada en embeddings (sqlite-vec), memoria estructurada transaccional, y una estrategia de memoria híbrida de corto y largo plazo.

**Problemas que resuelve:**
1. ❌ Pérdida de contexto durante compresión (compaction)
2. ❌ Recuperación ineficiente de memoria histórica
3. ❌ Fragmentación de información entre sesiones
4. ❌ Sin capacidad de búsqueda semántica

---

## 1. 🔍 Análisis del Problema de Compaction

### 1.1 ¿Qué es el Problema de Compaction?

Los agentes LLM operan con una **ventana de contexto finita** (ej: 128K-200K tokens). Cuando el contexto supera un umbral (típicamente 70-80%), el sistema debe **comprimir** o **truncar** el contenido para liberar espacio.

**El problema fundamental:**
```
Sesión activa → Tokens acumulados (>70%) → Compresión forzada → 
Pérdida de contexto detallado → Degradación de rendimiento → 
Respuestas inconsistentes entre sesiones
```

### 1.2 Manifestaciones Observadas

Basado en los checkpoints actuales de Clawd:

| Síntoma | Causa Raíz | Impacto |
|---------|-----------|---------|
| Checkpoints frecuentes (cada ~30 min) | Tokens acumulándose rápido | Interrupciones del flujo |
| Tareas pendientes perdidas | Compresión trunca listas | Proyectos incompletos |
| Decisiones contextuales olvidadas | Historial comprimido | Decisión inconsistente |
| Repetición de preguntas | Memoria no recuperada | Experiencia degradada |

### 1.3 Soluciones Existentes y Sus Limitaciones

| Solución | Cómo funciona | Limitación |
|----------|---------------|------------|
| **Truncación simple** | Eliminar mensajes antiguos | Pierde información crítica |
| **Summarization** | LLM resume conversación previa | Pérdida de granularidad |
| **Sliding window** | Mantener solo últimos N mensajes | Sin memoria a largo plazo |
| **Checkpoints manuales** | Guardar estado en archivos markdown | Recuperación manual lenta |

### 1.4 La Solución Propuesta: Memoria Híbrida + Embeddings

En lugar de comprimir el contexto, **arquitectamos memoria persistente**:
- **Memoria de Trabajo (Corto plazo):** Contexto activo en ventana LLM
- **Memoria Episódica (Medio plazo):** Checkpoints estructurados recuperables
- **Memoria Semántica (Largo plazo):** Embeddings para recuperación por similitud

---

## 2. 💾 sqlite-vec: Embeddings Locales de Alta Performance

### 2.1 ¿Por qué sqlite-vec?

**sqlite-vec** es una extensión de SQLite que permite almacenar y consultar vectores (embeddings) directamente en la base de datos. Es el sucesor de sqlite-vss y está patrocinado por Mozilla Builders.

**Ventajas para Clawd:**

| Característica | Beneficio para Clawd |
|----------------|---------------------|
| Zero external deps | Sin servicios adicionales (Pinecone, Weaviate) |
| Portable | Archivo .db único, fácil backup |
| SIMD acceleration | Búsqueda rápida (AVX, NEON) |
| Múltiples formatos | float32, int8, binary vectors |
| Metadata support | Filtrado por fecha, tipo, tags |
| Works everywhere | Linux, Mac, Windows, WASM, Raspberry Pi |

### 2.2 Arquitectura de Almacenamiento

```
┌─────────────────────────────────────────────────────────────┐
│                    sqlite-vec Database                      │
├─────────────────────────────────────────────────────────────┤
│  vec_memories (Virtual Table)                               │
│  ├─ rowid (primary key)                                     │
│  ├─ embedding float[384]      ← Vector de 384 dimensiones   │
│  ├─ memory_type text          ← 'conversation', 'task',     │
│  │                              'document', 'checkpoint'    │
│  ├─ source_file text          ← Archivo origen              │
│  ├─ created_at timestamp                                    │
│  ├─ access_count integer                                    │
│  ├─ last_accessed timestamp                                 │
│  └─ content_hash text                                       │
├─────────────────────────────────────────────────────────────┤
│  memory_metadata (Regular Table)                            │
│  ├─ id (foreign key)                                        │
│  ├─ content_preview text      ← Primeros 200 chars          │
│  ├─ full_content text         ← Contenido completo          │
│  ├─ tags json                 ← ["moltbook", "security"]     │
│  ├─ related_memories json     ← IDs de memoria relacionada  │
│  └─ confidence_score float    ← Para retrieval ranking      │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 Modelo de Embeddings Recomendado

Para uso local sin API externas:

```javascript
// Opción 1: Xenova Transformers (recomendado)
import { pipeline } from '@xenova/transformers';
const embedder = await pipeline('feature-extraction', 'Xenova/all-MiniLM-L6-v2');
// Dimensiones: 384, Model size: ~80MB, Calidad: Alta

// Opción 2: sqlite-lembed (integración directa)
// Usa modelos .gguf, corre completamente en SQLite
```

**Especificaciones:**
- **Modelo:** `Xenova/all-MiniLM-L6-v2` o `Xenova/gte-base`
- **Dimensiones:** 384 (MiniLM) o 768 (gte-base)
- **Lenguaje:** Multilingüe (español/inglés)
- **Latencia:** ~50ms por embedding en CPU moderno

### 2.4 Esquema SQL Completo

```sql
-- Extensión sqlite-vec
.load './vec0.so'

-- Tabla virtual para vectores
CREATE VIRTUAL TABLE vec_memories USING vec0(
  memory_id INTEGER PRIMARY KEY,
  embedding FLOAT[384],           -- Vector de embeddings
  memory_type TEXT,               -- Tipo de memoria
  source_file TEXT,               -- Archivo fuente
  session_id TEXT,                -- ID de sesión
  created_at INTEGER,             -- Timestamp UNIX
  access_count INTEGER DEFAULT 0, -- Contador de accesos
  last_accessed INTEGER,          -- Último acceso
  decay_factor REAL DEFAULT 1.0   -- Factor de decaimiento
);

-- Tabla de metadatos
CREATE TABLE memory_metadata (
  id INTEGER PRIMARY KEY,
  memory_id INTEGER REFERENCES vec_memories(memory_id),
  content_preview TEXT,           -- Preview para UI
  full_content TEXT,              -- Contenido completo
  content_hash TEXT UNIQUE,       -- Hash para deduplicación
  tags JSON,                      -- Tags como array JSON
  entities JSON,                  -- Entidades detectadas
  sentiment REAL,                 -- Análisis de sentimiento
  confidence_score REAL,          -- Score de confianza
  related_ids JSON,               -- IDs relacionados
  created_at INTEGER,
  updated_at INTEGER
);

-- Índices para performance
CREATE INDEX idx_memories_type ON vec_memories(memory_type);
CREATE INDEX idx_memories_session ON vec_memories(session_id);
CREATE INDEX idx_memories_created ON vec_memories(created_at);
CREATE INDEX idx_metadata_tags ON memory_metadata(tags) WHERE tags IS NOT NULL;

-- Tabla para checkpoints automáticos
CREATE TABLE auto_checkpoints (
  id INTEGER PRIMARY KEY,
  checkpoint_id TEXT UNIQUE,      -- UUID del checkpoint
  session_id TEXT,
  trigger_reason TEXT,            -- 'token_threshold', 'manual', 'scheduled'
  token_count INTEGER,
  context_summary TEXT,           -- Resumen generado
  memory_ids JSON,                -- IDs de memoria relevantes
  created_at INTEGER,
  recovered_at INTEGER            -- Cuándo se recuperó
);
```

### 2.5 Queries de Ejemplo

```sql
-- Búsqueda semántica: "problemas de seguridad con agents"
SELECT 
  m.memory_id,
  meta.content_preview,
  m.memory_type,
  vec_distance_L2(m.embedding, :query_embedding) as distance,
  (1.0 / (1.0 + vec_distance_L2(m.embedding, :query_embedding))) * m.decay_factor as score
FROM vec_memories m
JOIN memory_metadata meta ON m.memory_id = meta.memory_id
WHERE m.memory_type IN ('conversation', 'document')
ORDER BY score DESC
LIMIT 10;

-- Búsqueda con filtro temporal (últimos 7 días)
SELECT * FROM vec_memories m
JOIN memory_metadata meta ON m.memory_id = meta.memory_id
WHERE m.created_at > strftime('%s', 'now', '-7 days')
  AND m.embedding MATCH :query_embedding
  AND k = 5;

-- Incrementar contador de acceso (decay factor)
UPDATE vec_memories 
SET access_count = access_count + 1,
    last_accessed = strftime('%s', 'now'),
    decay_factor = decay_factor * 0.95 + 0.05
WHERE memory_id = :id;

-- Memoria relacionada (clustering semántico)
SELECT m2.memory_id, vec_distance_L2(m1.embedding, m2.embedding) as similarity
FROM vec_memories m1
JOIN vec_memories m2 ON m1.memory_id != m2.memory_id
WHERE m1.memory_id = :source_id
  AND vec_distance_L2(m1.embedding, m2.embedding) < 0.3
ORDER BY similarity
LIMIT 5;
```

---

## 3. 🔄 Sistema de Checkpoints Automáticos

### 3.1 Arquitectura de Checkpointing

```
┌──────────────────────────────────────────────────────────────┐
│                  Checkpoint Manager                          │
├──────────────────────────────────────────────────────────────┤
│  Triggers de Checkpoint                                       │
│  ├── Token threshold (70%, 85%, 95%)                         │
│  ├── Time-based (cada 30 min de actividad)                   │
│  ├── Event-based (antes de operación destructiva)            │
│  └── Manual (comando /checkpoint)                            │
├──────────────────────────────────────────────────────────────┤
│  Contenido del Checkpoint                                     │
│  ├── Working memory snapshot (contexto activo)               │
│  ├── Task state (pendientes, en progreso, completadas)       │
│  ├── Decision log (decisiones recientes con reasoning)       │
│  ├── Entity state (objetos/entidades en memoria)             │
│  └── Semantic embeddings (del contexto actual)               │
├──────────────────────────────────────────────────────────────┤
│  Recuperación                                                 │
│  ├── Auto-recovery (al inicio de sesión)                     │
│  ├── Selective restore (elegir qué recuperar)                │
│  └── Merge strategy (fusionar con contexto actual)           │
└──────────────────────────────────────────────────────────────┘
```

### 3.2 Estrategia de Recuperación Post-Compaction

**El problema:** Cuando el sistema de Clawd comprime el contexto, se pierde información granular.

**La solución:** En lugar de depender del contexto comprimido, **reconstruimos desde la memoria persistente:**

```javascript
// Pseudo-código del sistema de recuperación
async function recoverFromCompaction(checkpointId) {
  // 1. Cargar checkpoint
  const checkpoint = await loadCheckpoint(checkpointId);
  
  // 2. Obtener memoria semántica relacionada
  const summaryEmbedding = await embed(checkpoint.contextSummary);
  const relatedMemories = await semanticSearch(summaryEmbedding, {
    limit: 20,
    timeWindow: '7d',
    types: ['conversation', 'task', 'decision']
  });
  
  // 3. Reconstruir contexto enriquecido
  const enrichedContext = {
    summary: checkpoint.contextSummary,
    activeTasks: checkpoint.tasks,
    recentDecisions: checkpoint.decisions,
    relatedHistory: relatedMemories.map(m => ({
      relevance: m.score,
      content: m.preview,
      link: m.sourceFile
    }))
  };
  
  // 4. Inyectar en contexto del LLM
  return formatForLLM(enrichedContext);
}
```

### 3.3 Checkpointing Progresivo

En lugar de un único checkpoint masivo, implementamos **checkpointing granular:**

| Nivel | Frecuencia | Contenido | Recuperación |
|-------|-----------|-----------|--------------|
| **Micro** | Cada 5 min | Última acción, token count | Inmediata |
| **Meso** | Cada 30 min / 70% tokens | Contexto de tarea actual | Rápida |
| **Macro** | Cada sesión / 90% tokens | Estado completo | Completa |
| **Archival** | Diario | Todo histórico con embeddings | Búsqueda |

### 3.4 Implementación: Checkpoint Service

```javascript
// memory/checkpoint-service.js
import Database from 'better-sqlite3';
import { load as loadVec } from 'sqlite-vec';

class CheckpointService {
  constructor(dbPath) {
    this.db = new Database(dbPath);
    loadVec(this.db);
  }

  // Crear checkpoint automático
  async createAutomatic(trigger, tokenUsage) {
    const checkpoint = {
      id: generateUUID(),
      timestamp: Date.now(),
      trigger, // 'token_threshold', 'time', 'event'
      tokenUsage,
      workingMemory: this.captureWorkingMemory(),
      tasks: this.captureTaskState(),
      decisions: this.captureDecisionLog(),
      embeddings: await this.embedCurrentContext()
    };
    
    this.saveCheckpoint(checkpoint);
    this.notifyUser(`Checkpoint creado: ${checkpoint.id.slice(0, 8)}`);
    
    return checkpoint;
  }

  // Recuperar con enriquecimiento semántico
  async recover(checkpointId, options = {}) {
    const checkpoint = this.loadCheckpoint(checkpointId);
    
    // Si se solicita enriquecimiento
    if (options.enrich) {
      const related = await this.findRelatedMemories(
        checkpoint.embeddings.summary,
        { limit: options.contextDepth || 10 }
      );
      checkpoint.relatedMemories = related;
    }
    
    // Restaurar estado
    this.restoreTaskState(checkpoint.tasks);
    
    return checkpoint;
  }

  // Encontrar checkpoints relevantes para query
  async findRelevantCheckpoints(query, limit = 3) {
    const queryEmbedding = await embed(query);
    
    return this.db.prepare(`
      SELECT 
        c.checkpoint_id,
        c.context_summary,
        c.created_at,
        vec_distance_L2(e.embedding, ?) as distance
      FROM auto_checkpoints c
      JOIN vec_memories e ON c.checkpoint_id = e.source_file
      WHERE e.memory_type = 'checkpoint_summary'
      ORDER BY distance
      LIMIT ?
    `).all(JSON.stringify(queryEmbedding), limit);
  }
}
```

---

## 4. 🧩 Estrategia de Memoria Híbrida

### 4.1 Modelo de Memoria de Tres Capas

```
┌─────────────────────────────────────────────────────────────────┐
│  CAPA 1: MEMORIA DE TRABAJO (Working Memory)                    │
│  ├─ Tamaño: ~4K-8K tokens                                       │
│  ├─ Vida: Sesión activa                                         │
│  ├─ Contenido: Contexto inmediato, variables activas            │
│  └─ Implementación: Contexto LLM directo                        │
├─────────────────────────────────────────────────────────────────┤
│  CAPA 2: MEMORIA EPISÓDICA (Episodic Memory)                    │
│  ├─ Tamaño: ~50K-100K tokens equivalente                        │
│  ├─ Vida: Persistente, recuperable                              │
│  ├─ Contenido: Checkpoints, tareas, decisiones, eventos         │
│  └─ Implementación: sqlite + markdown files                     │
├─────────────────────────────────────────────────────────────────┤
│  CAPA 3: MEMORIA SEMÁNTICA (Semantic Memory)                    │
│  ├─ Tamaño: Ilimitado (embeddings comprimidos)                  │
│  ├─ Vida: Permanente                                            │
│  ├─ Contenido: Conocimiento, patrones, relaciones               │
│  └─ Implementación: sqlite-vec                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Flujo de Datos entre Capas

```
Usuario pregunta → Working Memory (búsqueda inmediata)
                        ↓ (miss)
              Episodic Memory (checkpoints recientes)
                        ↓ (miss)
              Semantic Memory (búsqueda vectorial)
                        ↓
              Recuperación + Enriquecimiento
                        ↓
              Inyección en Working Memory
                        ↓
              Respuesta al usuario
```

### 4.3 Categorías de Memoria

| Tipo | Capa | Uso | Ejemplo |
|------|------|-----|---------|
| **Conversacional** | Working → Episodic | Diálogo reciente | "El usuario preguntó sobre X" |
| **Tareas** | Episodic | TODOs, tracking | "Implementar feature Y" |
| **Decisiones** | Episodic → Semantic | Razones de decisiones | "Elegimos Z por razón W" |
| **Documental** | Semantic | Referencias | "Según archivo docs/api.md..." |
| **Relacional** | Semantic | Entidades y relaciones | "Usuario trabaja en proyecto A" |
| **Procedimental** | Semantic | Cómo hacer cosas | "Para deploy, seguir pasos..." |

### 4.4 Decay Factor 2.0: Inteligente y Adaptativo

Mejoramos el sistema actual de decay factor con aprendizaje:

```javascript
// memory/adaptive-decay.js
class AdaptiveDecay {
  constructor(config) {
    this.baseDecay = config.baseDecay || 0.95;
    this.recencyWeight = config.recencyWeight || 0.6;
    this.frequencyWeight = config.frequencyWeight || 0.4;
    this.contextWeight = config.contextWeight || 0.3; // NUEVO
  }

  calculateScore(memory) {
    const now = Date.now();
    
    // Componente de recencia (exponencial)
    const ageMs = now - memory.lastAccessed;
    const ageDays = ageMs / (1000 * 60 * 60 * 24);
    const recencyScore = Math.pow(this.baseDecay, ageDays);
    
    // Componente de frecuencia (logarítmico para evitar dominancia)
    const freqScore = Math.log1p(memory.accessCount) / Math.log1p(10);
    
    // Componente de contexto (NUEVO): qué tan relevante es el tema actual
    const contextScore = memory.contextRelevance || 0.5;
    
    // Boost para memoria explícitamente marcada
    const importanceBoost = memory.importance || 1.0;
    
    return (
      recencyScore * this.recencyWeight +
      freqScore * this.frequencyWeight +
      contextScore * this.contextWeight
    ) * importanceBoost;
  }

  // Actualizar relevancia basada en contexto actual
  updateContextRelevance(memories, currentEmbedding) {
    for (const memory of memories) {
      const similarity = cosineSimilarity(
        memory.embedding,
        currentEmbedding
      );
      memory.contextRelevance = similarity;
    }
  }
}
```

### 4.5 Consolidación de Memoria

**Proceso nocturno/heartbeat** que migra memoria entre capas:

```javascript
// memory/consolidation.js
class MemoryConsolidation {
  async consolidate() {
    // 1. Identificar memoria candidata a archivar
    const oldMemories = await this.findMemoriesForArchival({
      olderThan: '7d',
      lowAccess: true
    });

    // 2. Clusterizar memoria similar
    const clusters = await this.clusterMemories(oldMemories);

    // 3. Generar resúmenes consolidados
    for (const cluster of clusters) {
      const summary = await this.generateSummary(cluster);
      await this.createConsolidatedMemory(summary, cluster);
      await this.archiveCluster(cluster);
    }

    // 4. Actualizar relaciones
    await this.updateMemoryGraph();
  }
}
```

---

## 5. 🏗️ Arquitectura del Sistema

### 5.1 Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Memory System v2.0                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐          │
│  │   Query      │    │   Context    │    │   Storage    │          │
│  │   Router     │───→│   Manager    │───→│   Manager    │          │
│  └──────────────┘    └──────────────┘    └──────────────┘          │
│         │                   │                   │                   │
│         ↓                   ↓                   ↓                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐          │
│  │  Semantic    │    │   Working    │    │   Episodic   │          │
│  │   Search     │    │   Memory     │    │   Store      │          │
│  │  (sqlite-vec)│    │  (LLM ctx)   │    │  (sqlite/md) │          │
│  └──────────────┘    └──────────────┘    └──────────────┘          │
│         │                   │                   │                   │
│         └───────────────────┴───────────────────┘                   │
│                             │                                       │
│                             ↓                                       │
│                    ┌──────────────┐                                 │
│                    │  Checkpoint  │                                 │
│                    │   Service    │                                 │
│                    └──────────────┘                                 │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 5.2 Módulos Principales

```
memory/
├── core/
│   ├── memory-manager.js         # Orquestador principal
│   ├── query-router.js           # Enrutamiento de queries
│   └── context-manager.js        # Gestión de contexto LLM
│
├── layers/
│   ├── working-memory.js         # Capa 1: Working memory
│   ├── episodic-store.js         # Capa 2: Episodic memory
│   └── semantic-store.js         # Capa 3: Semantic memory (sqlite-vec)
│
├── retrieval/
│   ├── semantic-search.js        # Búsqueda vectorial
│   ├── adaptive-decay.js         # Decay factor inteligente
│   └── reranker.js               # Re-ranking de resultados
│
├── checkpoint/
│   ├── checkpoint-service.js     # Servicio de checkpoints
│   ├── auto-checkpointer.js      # Trigger automático
│   └── recovery-manager.js       # Recuperación post-compaction
│
├── consolidation/
│   ├── memory-consolidator.js    # Consolidación entre capas
│   ├── clusterizer.js            # Clustering de memoria
│   └── summarizer.js             # Generación de resúmenes
│
├── embeddings/
│   ├── embedder.js               # Wrapper de embedding
│   ├── local-model.js            # Modelo local (Xenova)
│   └── remote-api.js             # Fallback a API remota
│
├── schema/
│   ├── migrations/
│   │   ├── 001_initial.sql
│   │   ├── 002_add_checkpoints.sql
│   │   └── 003_add_semantic.sql
│   └── seeds/
│
├── index.js                      # Entry point
└── config.js                     # Configuración
```

### 5.3 API del Sistema

```javascript
// Uso simplificado del sistema de memoria
import { MemorySystem } from './memory/index.js';

const memory = new MemorySystem({
  dbPath: './memory/clawd-memory.db',
  embeddingModel: 'Xenova/all-MiniLM-L6-v2',
  checkpointThresholds: [0.7, 0.85, 0.95],
  decayFactor: 0.95
});

// Inicializar
await memory.initialize();

// Almacenar memoria
await memory.store({
  type: 'conversation',
  content: 'Usuario preguntó sobre sqlite-vec',
  metadata: { 
    tags: ['sqlite', 'embeddings'],
    importance: 1.5  // Boost manual
  }
});

// Recuperar memoria relevante
const results = await memory.retrieve({
  query: 'cómo hacer búsqueda vectorial',
  limit: 10,
  timeWindow: '30d',
  includeWorkingMemory: true
});

// Crear checkpoint manual
const checkpoint = await memory.checkpoint.create({
  reason: 'Antes de operación destructiva'
});

// Recuperar checkpoint
await memory.checkpoint.restore(checkpoint.id, {
  enrich: true,
  contextDepth: 15
});
```

---

## 6. 📊 Métricas y Monitoreo

### 6.1 KPIs del Sistema

| Métrica | Objetivo | Cómo medir |
|---------|----------|------------|
| Recall de memoria | >90% | Tasa de consultas con resultados relevantes |
| Latencia de búsqueda | <100ms | Tiempo de búsqueda semántica |
| Token efficiency | >80% | Tokens útiles / tokens totales en contexto |
| Checkpoint coverage | 100% | % de sesiones con checkpoint recoverable |
| User satisfaction | >4.5/5 | Feedback explícito del usuario |

### 6.2 Dashboard de Monitoreo

```javascript
// memory/metrics.js
class MemoryMetrics {
  getStats() {
    return {
      storage: {
        totalMemories: this.db.count(),
        byType: this.db.countByType(),
        databaseSize: this.getDbSize(),
        oldestMemory: this.getOldestMemory()
      },
      retrieval: {
        avgQueryTime: this.getAvgQueryTime(),
        cacheHitRate: this.getCacheHitRate(),
        topQueries: this.getTopQueries()
      },
      checkpoints: {
        totalCheckpoints: this.getCheckpointCount(),
        recoverySuccessRate: this.getRecoveryRate(),
        avgTimeBetweenCheckpoints: this.getAvgCheckpointInterval()
      },
      embeddings: {
        model: this.embedder.model,
        dimensions: this.embedder.dimensions,
        totalEmbeddings: this.getEmbeddingCount()
      }
    };
  }
}
```

---

## 7. 🔧 Plan de Implementación

### 7.1 Fases del Proyecto

#### Fase 1: Fundación (Semana 1-2)
- [ ] Setup de base de datos sqlite-vec
- [ ] Implementar schema inicial
- [ ] Integrar modelo de embeddings local
- [ ] Tests básicos de almacenamiento/recuperación

#### Fase 2: Checkpoints (Semana 3-4)
- [ ] Implementar CheckpointService
- [ ] Integrar triggers automáticos
- [ ] Sistema de recuperación básico
- [ ] Migrar sistema de checkpoints actual

#### Fase 3: Memoria Híbrida (Semana 5-6)
- [ ] Implementar tres capas de memoria
- [ ] Query router con enrutamiento inteligente
- [ ] Adaptive decay factor
- [ ] Integración con QMD existente

#### Fase 4: Consolidación (Semana 7-8)
- [ ] Proceso de consolidación de memoria
- [ ] Clustering semántico
- [ ] Migración de memoria histórica
- [ ] Optimizaciones de performance

#### Fase 5: Producción (Semana 9-10)
- [ ] Testing completo (unit + integration)
- [ ] Documentación de usuario
- [ ] Monitoreo y métricas
- [ ] Rollout gradual

### 7.2 Migración desde Sistema Actual

```javascript
// migration/from-markdown.js
async function migrateFromMarkdown() {
  const markdownFiles = await glob('memory/**/*.md');
  
  for (const file of markdownFiles) {
    const content = await fs.readFile(file, 'utf-8');
    
    // Extraer metadata del nombre y contenido
    const metadata = extractMetadata(file, content);
    
    // Generar embedding
    const embedding = await embedder.embed(content.slice(0, 5000));
    
    // Almacenar en nueva base de datos
    await memory.store({
      type: detectType(file),
      content: content,
      sourceFile: file,
      createdAt: metadata.date,
      embedding: embedding,
      metadata: {
        tags: metadata.tags,
        ...metadata
      }
    });
  }
}
```

### 7.3 Dependencias

```json
{
  "dependencies": {
    "better-sqlite3": "^11.0.0",
    "sqlite-vec": "^0.1.6",
    "@xenova/transformers": "^2.17.0",
    "uuid": "^9.0.0"
  },
  "devDependencies": {
    "vitest": "^1.0.0",
    "@types/better-sqlite3": "^7.6.10"
  }
}
```

---

## 8. 🧪 Testing Strategy

### 8.1 Tests Unitarios

```javascript
// tests/semantic-store.test.js
describe('SemanticStore', () => {
  test('should store and retrieve by similarity', async () => {
    const store = new SemanticStore(':memory:');
    
    await store.store({
      content: 'sqlite-vec es una extensión de SQLite',
      type: 'documentation'
    });
    
    const results = await store.search('base de datos vectorial');
    
    expect(results).toHaveLength(1);
    expect(results[0].score).toBeGreaterThan(0.7);
  });
});
```

### 8.2 Tests de Integración

```javascript
// tests/checkpoint-recovery.test.js
describe('Checkpoint Recovery', () => {
  test('should recover context after simulated compaction', async () => {
    // Simular sesión larga
    const session = await createLongSession();
    
    // Forzar checkpoint
    const checkpoint = await memory.checkpoint.create();
    
    // Simular pérdida de contexto
    memory.workingMemory.clear();
    
    // Recuperar
    await memory.checkpoint.restore(checkpoint.id);
    
    // Verificar recuperación
    expect(memory.workingMemory.tasks).toEqual(session.tasks);
  });
});
```

### 8.3 Benchmarks

```javascript
// benchmarks/retrieval-perf.js
// Objetivo: <100ms para búsqueda semántica con 10K memorias
```

---

## 9. 📝 Consideraciones de Seguridad

### 9.1 Protección de Datos

- **Encriptación:** Opcionalmente soportar encriptación de base de datos (SQLCipher)
- **Sanitización:** Validar todos los inputs antes de almacenar
- **Limpieza:** Opción para purgar memoria antigua con PII

### 9.2 Prompt Injection Prevention

```javascript
// Validar contenido antes de almacenar
import { SecurityGuard } from '../security-guard.js';

async function safeStore(content, metadata) {
  const guard = new SecurityGuard();
  const check = guard.validate(content, 'memory_input');
  
  if (!check.valid) {
    console.warn('Contenido bloqueado:', check.reason);
    return null;
  }
  
  return await store(content, metadata);
}
```

---

## 10. 🚀 Futuro y Extensiones

### 10.1 Roadmap Post-v2.0

- **v2.1:** Memoria compartida entre múltiples instancias de Clawd
- **v2.2:** Integración con sistemas externos (Notion, Obsidian)
- **v2.3:** Memoria colaborativa (múltiples usuarios)
- **v2.4:** Aprendizaje federado de preferencias

### 10.2 Investigación Activa

- **Memoria jerárquica:** Hierarchical Navigable Small World (HNSW)
- **Memoria atencional:** Sistema de atención para priorización
- **Memoria emocional:** Tracking de estado emocional del usuario

---

## 11. 📚 Referencias

### Recursos sqlite-vec
- [GitHub: asg017/sqlite-vec](https://github.com/asg017/sqlite-vec)
- [Documentación oficial](https://alexgarcia.xyz/sqlite-vec/)
- [Tutorial: How to use sqlite-vec](https://dev.to/stephenc222/how-to-use-sqlite-vec-to-store-and-query-vector-embeddings-58mf)

### Recursos sobre Memoria LLM
- [The Ultimate Guide to LLM Memory](https://medium.com/@sonitanishk2003/the-ultimate-guide-to-llm-memory-from-context-windows-to-advanced-agent-memory-systems-3ec106d2a345)
- [LLM Context Management Guide](https://eval.16x.engineer/blog/llm-context-management-guide)
- [6 Techniques to Manage Context Length](https://agenta.ai/blog/top-6-techniques-to-manage-context-length-in-llms)

### Papers Relevantes
- "Memory Networks" (Weston et al., 2014)
- "Neural Episodic Control" (Pritzel et al., 2017)
- "Large Language Model Augmented Agent with Long-Term Memory" (Wu et al., 2023)

---

## 12. ✅ Checklist de Aprobación

- [ ] Revisión técnica del equipo
- [ ] Validación de performance
- [ ] Revisión de seguridad
- [ ] Documentación completa
- [ ] Tests pasando >90% coverage
- [ ] Plan de rollback definido

---

**Documento creado:** 2026-01-30  
**Última actualización:** 2026-01-30  
**Versión:** 2.0.0-draft
