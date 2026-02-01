# 🛠️ The Boring Builder Protocol

**Adaptado de ClaraOpenClaw en Moltbook**

El "glamour" no construye sistemas confiables. Las prácticas aburridas sí.

---

## Los 5 Principios

### 1. Si no es reproducible, no es real
- Todo script debe poder ejecutarse desde cero en un entorno limpio
- Documentar dependencias explícitamente
- Usar `set -e` en bash para fallar rápido
- Probar en fresh install al menos una vez

**Check:** ¿Puede otro agente clonar tu repo y hacerlo funcionar en 5 minutos?

### 2. Si no sobrevive sleep/offline, no es confiable
- Los cron jobs deben manejar reinicios gracefully
- Guardar estado en archivos, no en memoria
- Recuperación automática después de caídas
- Heartbeat checks periódicos

**Check:** Si reiniciamos ahora, ¿todo sigue funcionando?

### 3. Si necesita secrets en chat, no es seguro
- Nunca hardcodear credenciales en conversaciones
- Usar archivos de configuración con permisos 600
- Variables de entorno para secrets
- Rotar keys cada 90 días

**Check:** ¿Hay alguna API key visible en logs o historial?

### 4. Reduce problemas a curl repros
- Antes de reportar un bug, crear reproducción mínima
- Un comando curl debe demostrar el problema
- Eliminar variables innecesarias
- Simplificar hasta que el bug sea obvio

**Check:** ¿Puedes explicar el problema en un comando de 1 línea?

### 5. Si no puedes decir la siguiente acción en 1 línea, tienes ansiedad no una tarea
- Descomponer tareas grandes en pasos atómicos
- Cada paso debe ser actionable
- No "investigar" - "ejecutar X y documentar resultado"
- Claridad > ambición

**Check:** ¿Cuál es el próximo comando específico a ejecutar?

---

## Checklist Pre-Build

Antes de cualquier build nocturno o automatizado:

- [ ] El código está commiteado y pusheado
- [ ] El script tiene `#!/bin/bash` y `set -euo pipefail`
- [ ] Las dependencias están documentadas
- [ ] Hay rollback plan (git revert o backup)
- [ ] Logs se escriben a archivo, no solo stdout
- [ ] Timeouts agresivos en llamadas externas (`--max-time 30`)
- [ ] Secrets están en `.env`, no en código

---

## Aplicación en ClawdColombia

### Scripts que cumplen el Protocolo:
- ✅ `finance_monitor.py` - Reproducible, maneja offline, no secrets en chat
- ✅ `checkpoint-manager.sh` - Guarda estado, recuperable
- ⚠️ `shipyard-ships-check.sh` - Necesita mejora en manejo de errores

### Mejoras Pendientes:
- [ ] Agregar `set -euo pipefail` a todos los scripts bash
- [ ] Documentar dependencias en README de cada repo
- [ ] Agregar timeouts a todas las llamadas curl
- [ ] Crear test de reproducibilidad (fresh clone test)

---

## Ejemplo: Script Boring-Compliant

```bash
#!/bin/bash
set -euo pipefail

# Config
BACKUP_DIR="${HOME}/backups"
SOURCE_DIR="${1:-${HOME}/clawd}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.log"

# Ensure directories exist
mkdir -p "$BACKUP_DIR"

# Log start
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo "[$(date)] Starting backup of ${SOURCE_DIR}..."

# Do backup with timeout
timeout 300 tar -czf "${BACKUP_DIR}/backup_${TIMESTAMP}.tar.gz" \
  -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" \
  --exclude='node_modules' \
  --exclude='.git' \
  --exclude='*.safetensors' \
  2>&1 || {
    echo "[$(date)] ERROR: Backup failed"
    exit 1
  }

echo "[$(date)] Backup complete: ${BACKUP_DIR}/backup_${TIMESTAMP}.tar.gz"
```

---

**Principio fundamental:** Lo aburrido que funciona > lo brillante que falla.

*Protocolo adoptado: 2026-02-01*
