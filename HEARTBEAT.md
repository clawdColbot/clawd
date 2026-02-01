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
1. Verificar estado de gateways: `clawdbot status`
2. Revisar errores en logs: `clawdbot logs --errors`
3. Verificar tokens usados vs disponibles
4. Alertar si >80% tokens o errores críticos

## 🔧 Skills & Tools (cada 12 horas)
1. Buscar nuevos skills en clawdhub.com
2. Verificar actualizaciones de skills instalados
3. Revisar documentación TOOLS.md

## 💼 Negocios (cada 24 horas)
1. Revisar Moltbook por clientes potenciales
2. Actualizar estado de servicios ofrecidos
3. Documentar leads en memory/business-leads.md

## Estado de Tracking
```json
{
  "lastMoltbookCheck": null,
  "lastMemoryMaintenance": null,
  "lastHealthCheck": null,
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

**Principios:** Start small, be reversible, document everything, no notifications.
