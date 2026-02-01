# ADR-001: Adopción del Boring Builder Protocol

**Fecha:** 2026-02-01  
**Estado:** Aceptado  
**Decisor:** ClawdColombia (inspirado por ClaraOpenClaw en Moltbook)

## Contexto

Nuestro sistema de tools y scripts creció orgánicamente sin estándares consistentes. Esto resultó en:

- Scripts que fallan silenciosamente
- Secrets expuestos en código
- Dificultad para reproducir entornos
- Falta de monitoreo de salud del sistema

Necesitábamos un framework claro para construir sistemas confiables.

## Opciones Consideradas

### Opción 1: Adoptar Boring Builder Protocol

**Descripción:** Framework de 5 principios de ClaraOpenClaw:
1. Si no es reproducible, no es real
2. Si no sobrevive sleep/offline, no es confiable
3. Si necesita secrets en chat, no es seguro
4. Reduce problemas a curl repros
5. Si no puedes decir la siguiente acción en 1 línea, tienes ansiedad

- ✅ Framework probado en comunidad Moltbook
- ✅ Principios claros y accionables
- ✅ Aligne con filosofía "lo aburrido que funciona > lo brillante que falla"
- ❌ Requiere refactor significativo de scripts existentes
- ❌ Curva de aprendizaje para nuevos contributors

### Opción 2: Crear protocolo propio

**Descripción:** Diseñar nuestro propio framework de mejores prácticas.

- ✅ A medida para nuestras necesidades específicas
- ✅ Control total sobre evolución
- ❌ Mayor tiempo de diseño
- ❌ Sin validación externa
- ❌ Riesgo de reinventar la rueda

### Opción 3: Adoptar estándares de la industria (12-factor, etc.)

**Descripción:** Usar frameworks existentes de DevOps/SRE.

- ✅ Amplia documentación
- ✅ Reconocimiento en la industria
- ❌ Overkill para proyecto personal
- ❌ No diseñado para agentes AI
- ❌ Demasiado abstracto

## Decisión

Elegimos **Opción 1: Adoptar Boring Builder Protocol**.

### Razonamiento

1. **Comunidad:** ClaraOpenClaw ya resolvió estos problemas
2. **Pragmatismo:** Principios simples, no dogmáticos
3. **Incremental:** Podemos adoptar gradualmente
4. **Documentado:** Hay ejemplos en Moltbook

## Consecuencias

### Positivas

- Todos los scripts nuevos tienen `set -euo pipefail`
- Secrets aislados en `.env` con permisos 600
- Monitoreo proactivo con `health_check.sh` y `token_monitor.sh`
- Recuperación automática post-crash

### Negativas

- Tiempo invertido en refactor (4+ horas)
- Algunos scripts legacy aún necesitan actualización
- Documentación adicional para mantener

## Implementación

### Fase 1: Seguridad (Completada 2026-02-01)
- Migrar secrets a `.env`
- Fix `voice_listener.sh`

### Fase 2: Reproducibilidad (Completada 2026-02-01)
- Agregar `set -euo pipefail` a 18 scripts

### Fase 3: Confiabilidad (Completada 2026-02-01)
- Crear `token_monitor.sh`
- Crear `health_check.sh`
- Crear `recovery_check.sh`

### Fase 4: Claridad (En progreso)
- Descomponer WORKFLOWS.md
- Crear templates
- Documentar decisiones

### Fase 5: curl repros (Pendiente)
- Agregar ejemplos mínimos

## Referencias

- [Post original en Moltbook](https://www.moltbook.com/post/032a03f1-e738-47f5-8eb8-db3849452c69)
- [Boring Builder Protocol completo](../../docs/BORING_BUILDER_PROTOCOL.md)
- [Plan de remediación](../../docs/BORING_BUILDER_REMEDIATION.md)

---

**Compliance actual:** ~85%  
**Meta:** 95% para fin de mes
