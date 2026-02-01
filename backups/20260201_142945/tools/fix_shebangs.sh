#!/bin/bash
#
# fix_shebangs.sh - Fase 2: Agregar set -euo pipefail a todos los scripts
# Boring Builder Protocol - Principle 1: Reproducible builds
#

set -euo pipefail

echo "🛠️  Fase 2: Fix Shebangs - Agregando 'set -euo pipefail'"
echo "============================================================"

FIXED=0
SKIPPED=0

# Buscar todos los scripts bash
find ~/clawd/tools -name "*.sh" -type f 2>/dev/null | while read -r file; do
    # Verificar si es un script bash
    if head -1 "$file" | grep -q "#!/bin/bash\|#!/usr/bin/env bash"; then
        # Verificar si ya tiene set -euo pipefail
        if grep -q "set -euo pipefail" "$file"; then
            echo "⏭️  Skipped (ya tiene): ${file#$HOME/clawd/}"
            ((SKIPPED++))
        else
            # Crear backup temporal
            cp "$file" "$file.bak"
            
            # Agregar set -euo pipefail después del shebang
            # Usar sed para insertar después de la primera línea
            sed -i '1a\
set -euo pipefail' "$file"
            
            # Verificar que el script sigue siendo válido
            if bash -n "$file" 2>/dev/null; then
                echo "✅ Fixed: ${file#$HOME/clawd/}"
                rm "$file.bak"
                ((FIXED++))
            else
                echo "❌ Error en: ${file#$HOME/clawd/} - restaurando backup"
                mv "$file.bak" "$file"
            fi
        fi
    fi
done

echo ""
echo "============================================================"
echo "✅ Fase 2 completada"
echo "   Fixed: $FIXED scripts"
echo "   Skipped: $SKIPPED scripts (ya tenían)"
echo ""
echo "🔍 Verificar: head -5 ~/clawd/tools/*.sh | grep -A1 'bin/bash'"
