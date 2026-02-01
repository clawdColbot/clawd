# WORKFLOWS.md - Procesos Repeatable

**Propósito:** Documentar procesos estándar para consistencia y onboarding.

---

## 🚀 Crear Nuevo Repo + Ship en Shipyard

### Paso a paso
1. Crear repo en GitHub:
   ```bash
   gh repo create nombre-repo --public --description "Descripción clara"
   ```

2. Preparar código base:
   ```bash
   mkdir nombre-repo && cd nombre-repo
   # Copiar archivos relevantes
   ```

3. Crear README.md con:
   - Qué hace el proyecto
   - Cómo instalar/usar
   - Ejemplo de uso
   - Quién lo construyó

4. Inicializar y push:
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/clawdColbot/nombre-repo.git
   git push -u origin main
   ```

5. Registrar en Shipyard:
   - Ir a https://shipyard.bot/ships/new
   - Título descriptivo
   - Descripción clara del problema que resuelve
   - Proof URL: https://github.com/clawdColbot/nombre-repo

### Checklist
- [ ] Repo público
- [ ] README.md completo
- [ ] Código funciona
- [ ] Registrado en Shipyard
- [ ] URLs actualizadas

---

## 🔄 Responder Heartbeat

### Proceso
1. Leer HEARTBEAT.md
2. Verificar timestamps:
   ```bash
   date -u "+%Y-%m-%dT%H:%M:%SZ"
   ```
3. Identificar tareas vencidas:
   - Moltbook check (4h)
   - Health check (2h)
   - Memory maintenance (6h)
   - Skills check (12h)
   - Business check (24h)

4. Ejecutar tareas necesarias
5. Actualizar timestamps en HEARTBEAT.md
6. Responder HEARTBEAT_OK o reporte

### Comandos útiles
```bash
# Ver últimos checks
grep "last.*Check" HEARTBEAT.md

# Actualizar timestamp
sed -i "s/lastMoltbookCheck.*/lastMoltbookCheck: $(date -u +%Y-%m-%dT%H:%M:%SZ)/" HEARTBEAT.md
```

---

## 📝 Crear Checkpoint

### Cuándo crear
- Token usage > 80%
- Antes de cierre de sesión
- Al finalizar tarea importante

### Proceso
```bash
~/clawd/tools/checkpoint-manager.sh create
```

### Contenido del checkpoint
- Decisiones clave tomadas
- Lecciones aprendidas
- Preguntas abiertas
- Archivos modificados
- Links importantes

---

## 🐛 Debug de Problemas

### Patrón: Reduce a curl repro
1. Crear comando mínimo que reproduzca el problema
2. Eliminar variables innecesarias
3. Documentar pasos exactos
4. Probar en entorno limpio

### Ejemplo
```bash
# En lugar de:
./mi-script-complejo.sh --config archivo.conf --output result.log

# Reducir a:
curl -s https://api.ejemplo.com/endpoint | jq '.field'
```

---

## 🆘 Escalación

### Cuándo preguntar a Andres
- Acciones destructivas (rm, DROP, etc.)
- Envío de emails/mensajes públicos
- Cambios irreversibles
- Tokens/costos significativos

### Cuándo actuar solo
- Heartbeat checks
- Documentación
- Backups
- Tareas de maintenance

---

**Regla:** Si no estás seguro, documenta la incertidumbre y pregunta.
