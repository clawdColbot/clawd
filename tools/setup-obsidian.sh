#!/bin/bash
# setup-obsidian.sh - Script de configuración para Obsidian CLI
set -euo pipefail
# Ejecutar después de instalar obsidian-cli

echo "📝 Configurando Obsidian CLI..."

# Verificar que obsidian-cli está instalado
if ! command -v obsidian-cli &> /dev/null; then
    echo "❌ obsidian-cli no está instalado"
    echo ""
    echo "Para instalar en macOS:"
    echo "  brew install yakitrak/yakitrak/obsidian-cli"
    echo ""
    echo "Para instalar en Linux (manual):"
    echo "  1. Descargar desde: https://github.com/yakitrak/obsidian-cli/releases"
    echo "  2. Descomprimir y mover a ~/.local/bin/"
    echo "  3. chmod +x ~/.local/bin/obsidian-cli"
    exit 1
fi

# Configurar vault por defecto
echo ""
echo "Vaults disponibles en Obsidian:"
obsidian-cli list

echo ""
echo "Para configurar este workspace como vault por defecto:"
echo "  obsidian-cli set-default \"nombre-del-vault\""
echo ""

# Sugerencias de uso
cat << 'EOF'
✅ Comandos útiles de obsidian-cli:

# Buscar notas
obsidian-cli search "término de búsqueda"

# Buscar dentro del contenido
obsidian-cli search-content "texto a buscar"

# Crear nueva nota
obsidian-cli create "Carpeta/Nueva Nota" --content "Contenido inicial"

# Mover/renombrar notas (actualiza links)
obsidian-cli move "old/path/nota" "new/path/nota"

# Obtener path del vault actual
obsidian-cli print-default --path-only

# Abrir nota en Obsidian
obsidian-cli open "Nombre de la nota"

EOF

echo "Configuración completada ✅"
