#!/bin/bash
#
# workspace-cleanup.sh - Limpieza inteligente del workspace
# Creado por Clawd durante sesión autónoma 🦊
#

WORKSPACE="${HOME}/clawd"
BACKUP_DIR="${WORKSPACE}/backups/cleanup-$(date +%Y%m%d-%H%M%S)"

echo "╔══════════════════════════════════════════╗"
echo "║      🧹 Workspace Cleanup Tool           ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Crear backup directory
mkdir -p "$BACKUP_DIR"

# 1. Archivos temporales
echo "🗑️  Buscando archivos temporales..."
TMP_COUNT=$(find "$WORKSPACE" -name "*.tmp" -o -name "*.temp" -o -name "*~" 2>/dev/null | wc -l)
echo "   Encontrados: $TMP_COUNT archivos"
if [ "$TMP_COUNT" -gt 0 ]; then
    find "$WORKSPACE" -name "*.tmp" -o -name "*.temp" -o -name "*~" 2>/dev/null | head -20
fi
echo ""

# 2. Archivos de log grandes (>10MB)
echo "📊 Archivos de log grandes (>10MB):"
find "$WORKSPACE" -name "*.log" -size +10M 2>/dev/null -exec ls -lh {} \; | awk '{print "   " $9 " -> " $5}'
echo ""

# 3. Archivos Python cache
PYCACHE_COUNT=$(find "$WORKSPACE" -type d -name "__pycache__" 2>/dev/null | wc -l)
echo "🐍 Directorios __pycache__: $PYCACHE_COUNT"
echo ""

# 4. Espacio usado por directorio
echo "💾 Espacio usado (top 10):"
du -sh "$WORKSPACE"/*/ 2>/dev/null | sort -hr | head -10 | while read size dir; do
    echo "   $size - $(basename $dir)"
done
echo ""

# 5. Archivos no trackeados por git
echo "📁 Archivos no trackeados por git:"
cd "$WORKSPACE" && git status --short 2>/dev/null | grep "^??" | wc -l | xargs echo "   Cantidad:"
echo ""

echo "═══════════════════════════════════════════"
echo "Para limpiar realmente, ejecuta:"
echo "  ~/clawd/tools/workspace-cleanup.sh --execute"
echo "═══════════════════════════════════════════"

# Si se pasa --execute, hacer la limpieza
if [ "$1" == "--execute" ]; then
    echo ""
    echo "⚠️  Ejecutando limpieza..."
    # Aquí irían los comandos reales de limpieza
    echo "   (Modo simulado - no se eliminó nada)"
fi
