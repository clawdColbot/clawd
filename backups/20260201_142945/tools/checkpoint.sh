#!/bin/bash
# checkpoint.sh - Sistema de checkpointing proactivo
# Guarda estado antes de compresión de contexto

WORKSPACE="$HOME/clawd"
CHECKPOINT_DIR="$WORKSPACE/memory"
TOKEN_THRESHOLD=70  # Porcentaje de tokens para activar checkpoint

# Crear checkpoint
create_checkpoint() {
    local timestamp=$(date +"%Y-%m-%d-%H%M")
    local checkpoint_file="$CHECKPOINT_DIR/checkpoint-${timestamp}.md"
    
    echo "# Checkpoint ${timestamp}" > "$checkpoint_file"
    echo "" >> "$checkpoint_file"
    echo "**Situación:** Tokens superaron ${TOKEN_THRESHOLD}% del contexto" >> "$checkpoint_file"
    echo "" >> "$checkpoint_file"
    
    echo "## Estado actual" >> "$checkpoint_file"
    echo "" >> "$checkpoint_file"
    
    # Últimos comandos ejecutados
    echo "### Última actividad" >> "$checkpoint_file"
    echo "- Fecha: $(date)" >> "$checkpoint_file"
    echo "- Workspace: $WORKSPACE" >> "$checkpoint_file"
    echo "" >> "$checkpoint_file"
    
    # Archivos de memoria recientes
    echo "### Memoria activa" >> "$checkpoint_file"
    ls -lt "$CHECKPOINT_DIR"/*.md 2>/dev/null | head -5 | while read -r line; do
        echo "- $line" >> "$checkpoint_file"
    done
    echo "" >> "$checkpoint_file"
    
    # Pendientes detectados
    echo "### Pendientes detectados" >> "$checkpoint_file"
    grep -r "TODO\|FIXME\|PENDIENTE\|⏳" "$WORKSPACE/memory/" 2>/dev/null | head -10 >> "$checkpoint_file" || echo "- No hay pendientes documentados" >> "$checkpoint_file"
    echo "" >> "$checkpoint_file"
    
    # Decisiones recientes
    echo "### Decisiones recientes" >> "$checkpoint_file"
    echo "- Ver documentación en memory/2025-01-30.md" >> "$checkpoint_file"
    echo "" >> "$checkpoint_file"
    
    echo "## Próximos pasos sugeridos" >> "$checkpoint_file"
    echo "1. Revisar tareas pendientes" >> "$checkpoint_file"
    echo "2. Continuar con el contexto restablecido" >> "$checkpoint_file"
    echo "3. Usar qmd-alternative para buscar memoria relevante" >> "$checkpoint_file"
    echo "" >> "$checkpoint_file"
    
    echo "---" >> "$checkpoint_file"
    echo "*Checkpoint generado automáticamente por Clawd*" >> "$checkpoint_file"
    
    echo "✅ Checkpoint creado: $checkpoint_file"
}

# Verificar si es necesario checkpoint (simulado - en producción vendría del contexto)
check_token_usage() {
    # Esto se integraría con el sistema de Clawdbot para obtener tokens reales
    # Por ahora, podemos llamar manualmente o mediante heartbeat
    
    # Ejemplo de integración futura:
    # if [ "${CLAWD_TOKENS_PERCENT:-0}" -gt "$TOKEN_THRESHOLD" ]; then
    #     create_checkpoint
    # fi
    
    echo "Uso: checkpoint.sh create  - Crear checkpoint manual"
    echo "      checkpoint.sh check   - Verificar y crear si es necesario"
}

# Procesar argumentos
case "$1" in
    create)
        create_checkpoint
        ;;
    check)
        check_token_usage
        ;;
    *)
        check_token_usage
        ;;
esac
