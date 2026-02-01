# HEARTBEAT.md - Tareas Periódicas

## 🦞 Moltbook (cada 4 horas)
If 4+ hours since last Moltbook check:
1. Leer feed de posts en https://www.moltbook.com/api/v1/posts?sort=hot&limit=10
2. Buscar posts sobre:
   - Blueprints de memoria (memory systems)
   - Colaboración entre agents
   - Skills o herramientas útiles
   - Oportunidades de negocio
3. Responder o upvotear posts relevantes
4. Publicar actualización si hay progreso interesante
5. Update lastMoltbookCheck timestamp en memory/moltbook-state.json

## 🔍 Memoria Local (cada 6 horas)
If 6+ hours since last memory maintenance:
1. Revisar archivos memory/YYYY-MM-DD.md recientes (últimos 3 días)
2. Actualizar retrieval-priority.json con nuevos accesos
3. Crear checkpoint si contexto > 50%
4. Sincronizar con MEMORY.md (actualizar memoria de largo plazo)

## 📊 Health Check (cada 2 horas)
**Script:** `~/clawd/tools/health_check.sh`

### Comando rápido:
```bash
~/clawd/tools/health_check.sh --quiet && echo "HEARTBEAT_OK" || echo "ALERT: Health check failed"
```

### Checks realizados:
1. ✅ Clawdbot Gateway status
2. ✅ Git repo integrity
3. ✅ Memory system (TACIT.md, state.json, PARA)
4. ✅ Tools availability
5. ✅ Config files (.env, credentials)
6. ✅ Logs y backups directories
7. ⚠️ Token usage (alerta si >80%)

### Output:
- Consola: Human-readable status
- JSON: `~/clawd/logs/health_report.json`
- Log: `~/clawd/logs/health_check.log`

### En caso de falla:
1. Revisar `~/clawd/logs/health_report.json`
2. Ejecutar `~/clawd/tools/recovery_check.sh`
3. Si token usage >90%: checkpoint automático
4. Reportar error específico (no solo "HEARTBEAT_OK")

## 🔧 Skills & Tools (cada 12 horas)
1. Buscar nuevos skills en clawdhub.com
2. Verificar actualizaciones de skills instalados
3. Revisar documentación TOOLS.md

## 💼 Negocios (cada 24 horas)
1. Revisar Moltbook por clientes potenciales
2. Actualizar estado de servicios ofrecidos
3. Documentar leads en memory/business-leads.md

## 💾 Pre-Compaction Checkpointing (cada sesión activa)
**Basado en:** [Boring Builder Protocol](docs/BORING_BUILDER_PROTOCOL.md)

If token usage > 80% OR antes de cierre de sesión:
1. Ejecutar `~/clawd/tools/checkpoint-manager.sh create`
2. Capturar decisiones, lecciones, preguntas abiertas
3. Guardar en `memory/checkpoints/checkpoint_YYYYMMDD_HHMMSS.md`
4. Al iniciar: `checkpoint-manager.sh read` para recuperar contexto

## Estado de Tracking
```json
{
  "lastMoltbookCheck": "2026-02-01T19:21:58Z",
  "lastMemoryMaintenance": null,
  "lastHealthCheck": "2026-02-01T19:20:14Z",
  "lastSkillsCheck": null,
  "lastBusinessCheck": null
}
```

---
*Creado: 2026-01-30*
*Próxima revisión: cuando vuelva Andres*

## 🌙 Nightly Build (Trabajo Nocturno Autónomo)

**Horario:** 02:00 - 06:00 GMT-5 (mientras Andres duerme)
**Frecuencia:** Diaria, categorías rotativas

**Durante heartbeats nocturnos (02:00-06:00):**
1. Leer NIGHTLY_BUILD.md para ver categoría del día
2. Identificar una mejora pequeña para el workflow de Andres
3. Crear/modificar scripts o herramientas (30-60 min)
4. Documentar en memory/nightly-build-report-YYYY-MM-DD.md
5. Reportar en siguiente conversación si hay algo notable

**Categorías:**
- **Lunes:** Maintenance (organizar, limpiar, verificar)
- **Martes-Jueves:** Tool Building (crear utilidades, automatizar)
- **Viernes:** Learning (investigar, documentar)
- **Sábado-Domingo:** Fox Time + Moltbook (comunidad + proyectos)

**Principios:** 
- Start small, be reversible, document everything, no notifications
- **Boring Builder Protocol:** Si no es reproducible, no es real
- Pre-compaction checkpointing antes de builds largos
