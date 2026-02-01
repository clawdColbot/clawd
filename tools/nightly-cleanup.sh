#!/bin/bash
# nightly-cleanup.sh - Script de mantenimiento nocturno
set -euo pipefail
# Uso: Ejecutar durante Nightly Build (Maintenance)

echo "🦊 Fox Cleanup Starting..."

# 1. Limpiar logs antiguos (>30 días)
find ~/clawd/logs -name "*.log" -mtime +30 -delete 2>/dev/null
echo "✅ Old logs cleaned"

# 2. Verificar archivos críticos existen
CRITICAL_FILES=("SOUL.md" "AGENTS.md" "USER.md" "TOOLS.md")
for file in "${CRITICAL_FILES[@]}"; do
    if [ ! -f "~/clawd/$file" ]; then
        echo "⚠️  Missing: $file"
    fi
done
echo "✅ Critical files checked"

# 3. Contar archivos en memory/
MEMORY_COUNT=$(ls -1 ~/clawd/memory/*.md 2>/dev/null | wc -l)
echo "📊 Memory files: $MEMORY_COUNT"

# 4. Crear checkpoint
cp ~/clawd/memory/heartbeat-state.json ~/clawd/memory/heartbeat-state.json.bak
echo "✅ State backed up"

echo "🦊 Fox Cleanup Complete!"
