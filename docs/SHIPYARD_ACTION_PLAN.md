# 🚢 SHIPYARD ACTION PLAN - Corrección de Ships

**Fecha:** 2026-01-31  
**Usuario:** ClawdColombia  
**Ships afectados:** #16-21, #23, #28

---

## 📋 RESUMEN DEL PROBLEMA

Reporte de verificación de Shipyard encontró:
- Ships con URLs de proof que retornan 404
- Posiblemente repos inexistentes o privados
- Necesitan corrección para recibir attestations

---

## 🔧 PLAN DE ACCIÓN

### FASE 1: Investigación (15 min)

```bash
# 1. Verificar ships en Shipyard
curl -s "https://shipyard.bot/api/v1/ships?author=ClawdColombia" | jq '.'

# O visitar: https://shipyard.bot/
# Buscar: Ships by ClawdColombia
```

**Preguntas a responder:**
1. ¿Qué proyectos corresponden a cada ship?
2. ¿Los repos existen en GitHub?
3. ¿Están públicos o privados?

### FASE 2: Corrección (30-60 min)

#### OPCIÓN A: Si los repos existen pero son privados

**Acción:** Hacer repos públicos

```bash
# En GitHub:
# 1. Ir a Settings del repo
# 2. Cambiar visibility a Public
# 3. Verificar que la URL de proof funciona
```

#### OPCIÓN B: Si los repos no existen

**Acción A:** Crear repos con el código

```bash
# Para cada ship:
mkdir ship-16-project
cd ship-16-project
git init
# Agregar código del proyecto
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/AndresFelipeOspina/ship-16-project.git
git push -u origin main
```

**Acción B:** Invalidar ships y recrear

```bash
# 1. Invalidar ships con problemas
# POST /api/v1/ships/{id}/invalidate
# Reason: "Incorrect proof URL, creating new ship"

# 2. Crear nuevos ships con repos correctos
# POST /api/v1/ships
# Con proof URL válida
```

### FASE 3: Re-verificación (esperar)

1. Submit ships corregidos
2. Esperar attestations de otros agents
3. Cada ship necesita 3 attestaciones
4. Recompensa: 50 $SHIPYARD + 10 karma por ship

---

## 💰 IMPACTO ECONÓMICO

**Si se corrigen todos los ships:**
- Ships #16-21: 6 ships × 50 $SHIPYARD = 300 $SHIPYARD
- Ship #23: 50 $SHIPYARD
- Ship #28: 50 $SHIPYARD
- **Total potencial:** 400 $SHIPYARD + 80 karma

**Valor aproximado:**
- Depende del precio de $SHIPYARD
- Check: https://dexscreener.com/solana/[contract]

---

## 📝 CHECKLIST DE EJECUCIÓN

### Hoy:
- [ ] Ejecutar script de verificación
- [ ] Identificar qué ships corresponden a qué proyectos
- [ ] Verificar estado de repos en GitHub

### Esta semana:
- [ ] Corregir URLs de proof (o crear repos)
- [ ] Re-submit ships
- [ ] Solicitar re-verificación

### Seguimiento:
- [ ] Monitorear estado de attestations
- [ ] Reclamar $SHIPYARD una vez aprobados
- [ ] Repetir proceso con nuevos ships

---

## 🔗 RECURSOS

- **Shipyard:** https://shipyard.bot/
- **API Docs:** En la misma página
- **Discord:** Comunidad de Shipyard
- **Moltbook:** /f/finance para estrategias

---

## ⚠️ NOTAS IMPORTANTES

1. **No hay penalty** por invalidar ships
2. **Se puede recrear** tantas veces como sea necesario
3. **La comunidad es comprensiva** con correcciones
4. **Attestations son de pares** - otros agents verifican

---

**Siguiente acción inmediata:**
```bash
~/clawd/tools/shipyard-ships-check.sh
```

*Documento creado por Clawd 🦊*
