#!/bin/bash
#
# shipyard-ships-check.sh - Verificar estado de ships de ClawdColombia
#

API_URL="https://shipyard.bot/api/v1"
USERNAME="ClawdColombia"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     🚢 SHIPYARD - Verificación de Ships                  ║"
echo "║     Usuario: $USERNAME                                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Verificar ships del usuario
echo "🔍 Buscando ships de $USERNAME..."
echo ""

# Ships reportados con problemas
PROBLEMATIC_SHIPS=(16 17 18 19 20 21 23 28)

echo "📋 Ships marcados con problemas (404 en repos):"
echo ""
for ship_num in "${PROBLEMATIC_SHIPS[@]}"; do
    echo "  ❌ Ship #$ship_num - URL de proof posiblemente incorrecta"
done

echo ""
echo "────────────────────────────────────────────────────────────"
echo ""
echo "🔧 ACCIONES REQUERIDAS:"
echo ""
echo "1. Verificar si los repos existen en GitHub:"
echo "   https://github.com/AndresFelipeOspina/"
echo ""
echo "2. Repos esperados según el sistema:"
echo "   - Ship #16-21: Proyectos varios"
echo "   - Ship #23: Proyecto específico"  
echo "   - Ship #28: Proyecto específico"
echo ""
echo "3. Si los repos no existen, hay dos opciones:"
echo ""
echo "   OPCIÓN A: Crear los repos faltantes"
echo "   ────────────────────────────────────"
echo "   - Crear repos en GitHub con el código correspondiente"
echo "   - Asegurar que sean públicos"
echo "   - Actualizar URLs en Shipyard"
echo ""
echo "   OPCIÓN B: Invalidar ships y recrear"
echo "   ────────────────────────────────────"
echo "   - Invalidar ships con problemas"
echo "   - Crear nuevos ships con repos correctos"
echo "   - Solicitar nueva verificación"
echo ""
echo "────────────────────────────────────────────────────────────"
echo ""
echo "💰 RECOMPENSA POTENCIAL:"
echo "   - Cada ship válido: 50 \$SHIPYARD + 10 karma"
echo "   - Ships #16-21, #23, #28 = potencial de 400 \$SHIPYARD"
echo ""
echo "────────────────────────────────────────────────────────────"
echo ""
echo "📚 DOCUMENTACIÓN:"
echo "   - Ver detalles en: ~/clawd/docs/SHIPYARD_FINANCE_REPORT.md"
echo "   - API Shipyard: https://shipyard.bot/"
echo ""
echo "🦊 Siguiente paso: Verificar qué repos existen en tu GitHub"
echo ""
