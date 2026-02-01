#!/bin/bash
# MCP Helper Script - Facilita el uso de servidores MCP con mcporter
# Uso: ./mcp-call.sh <servidor> <herramienta> [argumentos JSON]

# Leer BRAVE_API_KEY del config de Clawdbot si no está en env
if [ -z "$BRAVE_API_KEY" ] && [ -f "$HOME/.clawdbot/clawdbot.json" ]; then
    BRAVE_API_KEY=$(grep -o '"apiKey": "[^"]*"' "$HOME/.clawdbot/clawdbot.json" | grep -o 'BSA[^"]*' | head -1)
fi

SERVER=$1
TOOL=$2
ARGS=${3:-'{"path": "/home/durango/clawd"}'}

if [ -z "$SERVER" ] || [ -z "$TOOL" ]; then
    echo "Uso: $0 <servidor> <herramienta> [argumentos JSON]"
    echo ""
    echo "Ejemplos:"
    echo "  $0 filesystem list_directory '{\"path\": \"/home/durango/clawd\"}'"
    echo "  $0 filesystem search_files '{\"path\": \"/home/durango/clawd\", \"pattern\": \"**/*.md\"}'"
    echo "  $0 filesystem read_text_file '{\"path\": \"/home/durango/clawd/README.md\"}'"
    echo "  $0 brave-search brave_web_search '{\"query\": \"Clawdbot AI\"}'"
    echo ""
    echo "Servidores disponibles:"
    echo "  ✅ filesystem   - 14 herramientas de archivos"
    echo "  ✅ brave-search - Búsqueda web (BRAVE_API_KEY auto-configurada)"
    echo "  ⏳ github       - GitHub API (necesita GITHUB_TOKEN)"
    exit 1
fi

# Construir el mensaje JSON-RPC
REQUEST=$(cat <<EOF
{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "$TOOL", "arguments": $ARGS}, "id": 1}
EOF
)

# Ejecutar el servidor MCP según el tipo
case $SERVER in
    filesystem)
        echo "$REQUEST" | npx -y @modelcontextprotocol/server-filesystem /home/durango/clawd 2>/dev/null
        ;;
    brave-search)
        if [ -z "$BRAVE_API_KEY" ]; then
            echo "Error: BRAVE_API_KEY no encontrada en ~/.clawdbot/clawdbot.json"
            exit 1
        fi
        echo "$REQUEST" | BRAVE_API_KEY="$BRAVE_API_KEY" npx -y @modelcontextprotocol/server-brave-search 2>/dev/null
        ;;
    github)
        if [ -z "$GITHUB_TOKEN" ]; then
            echo "Error: GITHUB_TOKEN no está configurado"
            echo "Configúralo con: export GITHUB_TOKEN='tu_token_de_github'"
            exit 1
        fi
        echo "$REQUEST" | GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_TOKEN" npx -y @modelcontextprotocol/server-github 2>/dev/null
        ;;
    *)
        echo "Servidor desconocido: $SERVER"
        echo "Servidores disponibles: filesystem, brave-search, github"
        exit 1
        ;;
esac
