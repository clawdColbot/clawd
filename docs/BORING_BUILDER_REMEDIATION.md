# 🔧 Boring Builder Protocol - Plan de Remediación

**Audit Date:** 2026-02-01  
**Auditor:** ClawdColombia (self-audit)  
**Status:** 23 violaciones encontradas, 0 críticas, 5 altas, 18 medias/bajas

---

## 🎯 ORDEN DE EJECUCIÓN (Prioridad Clawd)

### **FASE 1: SEGURIDAD CRÍTICA (Hoy - 30 min)**
*Principio 3: Sin secrets en código*

| # | Issue | Archivo | Acción |
|---|-------|---------|--------|
| 1.1 | 🔴 **TELEGRAM_TOKEN expuesto** | `tools/voice_listener.sh:7` | Mover a `.env`, usar `source` |
| 1.2 | 🔴 **API keys en scripts** | `tools/finance/*.py` | Audit all, mover a config |
| 1.3 | 🟡 **Permisos de archivos** | `~/.config/moltbook/credentials.json` | Verificar `chmod 600` |

**Comando de verificación:**
```bash
grep -r "TOKEN\|API_KEY\|password" --include="*.sh" --include="*.py" ~/clawd/tools/ | grep -v ".env"
```

---

### **FASE 2: REPRODUCIBILIDAD (Hoy - 45 min)**
*Principio 1: Si no es reproducible, no es real*

| # | Issue | Acción | Script |
|---|-------|--------|--------|
| 2.1 | Agregar `set -euo pipefail` | A todos los bash scripts | `fix_shebangs.sh` |
| 2.2 | Documentar dependencias | Crear `requirements.txt` y `README.md` por tool | Manual |
| 2.3 | Crear test de reproducibilidad | Script que hace fresh clone y verifica | `test_reproducibility.sh` |

**Scripts afectados (sin `set -e`):**
- `tools/voice_listener.sh`
- `tools/checkpoint-manager.sh`
- `tools/morning-briefing/morning_briefing.sh`
- `tools/nightly-cleanup.sh`

---

### **FASE 3: CONFIABILIDAD (Mañana - 1h)**
*Principio 2: Sobrevive sleep/offline*

| # | Issue | Acción | Complejidad |
|-------|-------|--------|-------------|
| 3.1 | Integrar token usage real | Parsear `clawdbot status` output | Media |
| 3.2 | Health check automático | Script que verifica todos los tools | Baja |
| 3.3 | Recuperación post-crash | Wrapper que reinicia services | Media |

---

### **FASE 4: CLARIDAD (Esta semana - 2h)**
*Principio 5: Tareas atómicas*

| # | Issue | Acción |
|-------|-------|--------|
| 4.1 | Descomponer WORKFLOWS.md | Cada workflow en archivo separado |
| 4.2 | Crear templates | `template_bash.sh`, `template_python.py` |
| 4.3 | Documentar decisiones | Agregar `docs/decisions/` |

---

### **FASE 5: CURL REPROS (Cuando surja)**
*Principio 4: Debug efectivo*

| # | Issue | Acción |
|-------|-------|--------|
| 5.1 | Ejemplos en cada tool | Minimo comando que funcione |
| 5.2 | Error handling consistente | `|| { echo "Error"; exit 1; }` |

---

## 📋 SCRIPTS DE REMEDIACIÓN

### **Script 1.1: Fix Security (voice_listener.sh)**
```bash
#!/bin/bash
# fix_security.sh - Fase 1

# 1. Crear .env si no existe
ENV_FILE="${HOME}/.clawdbot/.env"
if [[ ! -f "$ENV_FILE" ]]; then
    echo "CLAWDBOT_TELEGRAM_BOT_TOKEN=" > "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    echo "⚠️  Creado $ENV_FILE - por favor agregar el token manualmente"
fi

# 2. Actualizar voice_listener.sh
sed -i 's|^TELEGRAM_TOKEN=".*"|source "${HOME}/.clawdbot/.env"\nTELEGRAM_TOKEN="${CLAWDBOT_TELEGRAM_BOT_TOKEN:-}"|' \
    ~/clawd/tools/voice_listener.sh

# 3. Agregar check
sed -i '/^TELEGRAM_TOKEN=/a\
if [[ -z "$TELEGRAM_TOKEN" ]]; then\n    echo "Error: TELEGRAM_TOKEN not set"\n    exit 1\nfi' \
    ~/clawd/tools/voice_listener.sh

echo "✅ Fase 1 completada"
```

### **Script 2.1: Fix Shebangs**
```bash
#!/bin/bash
# fix_shebangs.sh - Fase 2

for file in ~/clawd/tools/*.sh ~/clawd/tools/*/*.sh 2>/dev/null; do
    if [[ -f "$file" ]]; then
        # Verificar si ya tiene set -e
        if ! grep -q "set -euo pipefail" "$file"; then
            # Agregar después del shebang
            sed -i '2a\
set -euo pipefail' "$file"
            echo "✅ Fixed: $file"
        fi
    fi
done
```

---

## 📊 MÉTRICAS DE ÉXITO

| Métrica | Actual | Target | Deadline |
|---------|--------|--------|----------|
| % scripts con `set -e` | 20% | 100% | Hoy |
| Secrets expuestos | 3+ | 0 | Hoy |
| Documentación completa | 30% | 90% | Semana |
| Tests reproducibilidad | 0 | 1 | Mañana |

---

## 🚀 PRIMER PASO (Ejecutar ahora)

```bash
# 1. Backup
mkdir -p ~/clawd/backups/$(date +%Y%m%d)
cp -r ~/clawd/tools ~/clawd/backups/$(date +%Y%m%d)/

# 2. Ejecutar Fase 1
~/clawd/tools/fix_security.sh

# 3. Verificar
grep -r "TOKEN=" --include="*.sh" ~/clawd/tools/ | grep -v ".env" | grep -v "${"
# Debe retornar vacío
```

---

**¿Ejecuto la Fase 1 ahora?** (30 min, crítico para seguridad)
