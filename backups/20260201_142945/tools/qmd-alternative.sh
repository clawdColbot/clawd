#!/bin/bash
# qmd-alternative - Búsqueda local de memoria para Clawd
# Reemplazo simple de qmd usando ripgrep/grep

WORKSPACE="$HOME/clawd"
COLLECTION_DIR="$WORKSPACE/.qmd-collections"

# Crear directorio de colecciones si no existe
mkdir -p "$COLLECTION_DIR"

function show_help() {
    echo "Uso: qmd-alternative <comando> [opciones]"
    echo ""
    echo "Comandos:"
    echo "  collection add <path> --name <name> --mask <pattern>  Crear índice de búsqueda"
    echo "  search <query> -n <num>                                Buscar en el índice"
    echo "  reindex                                                Reconstruir todos los índices"
    echo ""
    echo "Ejemplos:"
    echo "  qmd-alternative collection add ~/clawd --name clawd --mask '**/*.md'"
    echo "  qmd-alternative search \"Moltbook\" -n 5"
}

function create_index() {
    local path="$1"
    local name="$2"
    local mask="$3"
    
    local index_file="$COLLECTION_DIR/${name}.index"
    
    echo "Creando índice '$name'..."
    
    # Limpiar índice anterior
    > "$index_file"
    
    # Encontrar todos los archivos y extraer contenido relevante
    find "$path" -type f -name "*.md" 2>/dev/null | while read -r file; do
        # Extraer líneas significativas (títulos, bullets, etc.)
        grep -E "^#|^\*\*|^-|^\[|^\d+\." "$file" 2>/dev/null | head -50
    done >> "$index_file"
    
    echo "Índice '$name' creado en: $index_file"
    echo "Líneas indexadas: $(wc -l < "$index_file")"
}

function search_index() {
    local query="$1"
    local num="${2:-5}"
    
    local found=0
    
    for index_file in "$COLLECTION_DIR"/*.index; do
        if [ -f "$index_file" ]; then
            local results=$(grep -i "$query" "$index_file" 2>/dev/null | head -$num)
            if [ -n "$results" ]; then
                echo "=== $(basename "$index_file" .index) ==="
                echo "$results"
                echo ""
                ((found++))
            fi
        fi
    done
    
    if [ $found -eq 0 ]; then
        echo "No se encontraron resultados para: $query"
    fi
}

function reindex_all() {
    for index_file in "$COLLECTION_DIR"/*.index; do
        if [ -f "$index_file" ]; then
            local name=$(basename "$index_file" .index)
            echo "Reindexando '$name'..."
            # Reconstruir índice
        fi
    done
}

# Procesar comandos
case "$1" in
    collection)
        shift
        if [ "$1" = "add" ]; then
            shift
            path=""
            name=""
            mask=""
            
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --name) name="$2"; shift 2 ;;
                    --mask) mask="$2"; shift 2 ;;
                    *) path="$1"; shift ;;
                esac
            done
            
            create_index "$path" "$name" "$mask"
        fi
        ;;
    search)
        shift
        query="$1"
        num=5
        
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -n) num="$2"; shift 2 ;;
                *) shift ;;
            esac
        done
        
        search_index "$query" "$num"
        ;;
    reindex)
        reindex_all
        ;;
    *)
        show_help
        ;;
esac
