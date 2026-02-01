#!/bin/bash
#==============================================================================
# clawdbot-restore.sh - Restaurar backup de Clawdbot
#
# Restaura configuración desde un backup creado con clawdbot-backup.sh
#
# Uso: ./clawdbot-restore.sh <archivo_backup> [--dry-run]
#==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DRY_RUN=false
BACKUP_FILE=""
RESTORE_DIR="/tmp/clawdbot_restore_$(date +%s)"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    echo "Uso: $0 <archivo_backup.tar.gz[.gpg]> [--dry-run]"
    echo ""
    echo "Opciones:"
    echo "  --dry-run    Mostrar qué se restauraría sin hacer cambios"
    exit 1
}

# Parsear argumentos
parse_args() {
    if [[ $# -lt 1 ]]; then
        usage
    fi
    
    BACKUP_FILE="$1"
    
    if [[ ! -f "$BACKUP_FILE" ]]; then
        log_error "Archivo no encontrado: $BACKUP_FILE"
        exit 1
    fi
    
    if [[ "${2:-}" == "--dry-run" ]]; then
        DRY_RUN=true
        log_warn "MODO DRY-RUN: No se realizarán cambios"
    fi
}

# Desencriptar si es necesario
decrypt_if_needed() {
    if [[ "$BACKUP_FILE" == *.gpg ]]; then
        log_info "Desencriptando backup..."
        
        if ! command -v gpg &> /dev/null; then
            log_error "GPG no instalado. Instálalo con: sudo apt-get install gnupg"
            exit 1
        fi
        
        DECRYPTED_FILE="${BACKUP_FILE%.gpg}"
        
        if [[ "$DRY_RUN" == false ]]; then
            gpg --decrypt --output "$DECRYPTED_FILE" "$BACKUP_FILE"
            BACKUP_FILE="$DECRYPTED_FILE"
            log_success "Backup desencriptado"
        else
            log_info "[DRY-RUN] Se desencriptaría: $BACKUP_FILE"
            BACKUP_FILE="${BACKUP_FILE%.gpg}"
        fi
    fi
}

# Extraer backup
extract_backup() {
    log_info "Extrayendo backup..."
    
    mkdir -p "$RESTORE_DIR"
    
    if [[ "$DRY_RUN" == false ]]; then
        tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR" --strip-components=1
        log_success "Backup extraído a: $RESTORE_DIR"
    else
        log_info "[DRY-RUN] Se extraería a: $RESTORE_DIR"
    fi
}

# Mostrar contenido del backup
show_backup_contents() {
    log_info "Contenido del backup:"
    
    if [[ -d "$RESTORE_DIR" ]]; then
        echo ""
        echo "Configuraciones:"
        ls -la "$RESTORE_DIR/config/" 2>/dev/null || echo "  (vacío)"
        
        echo ""
        echo "Archivos de memoria:"
        find "$RESTORE_DIR/memory" -type f 2>/dev/null | head -10 || echo "  (vacío)"
        
        echo ""
        echo "Tools:"
        ls -la "$RESTORE_DIR/tools/" 2>/dev/null || echo "  (vacío)"
        
        if [[ -f "$RESTORE_DIR/BACKUP_INFO.txt" ]]; then
            echo ""
            echo "Info del backup:"
            cat "$RESTORE_DIR/BACKUP_INFO.txt" | head -20
        fi
    fi
}

# Restaurar configuración
restore_config() {
    log_info "Restaurando configuración..."
    
    local target_dir="$HOME/.clawdbot"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Se restauraría config a: $target_dir"
        return
    fi
    
    # Backup actual antes de restaurar
    if [[ -d "$target_dir" ]]; then
        mv "$target_dir" "${target_dir}.bak.$(date +%s)"
        log_warn "Config actual respaldada como: ${target_dir}.bak.*"
    fi
    
    mkdir -p "$target_dir"
    cp -r "$RESTORE_DIR/config/"* "$target_dir/" 2>/dev/null || true
    
    # Permisos seguros
    chmod 700 "$target_dir"
    find "$target_dir" -type f -exec chmod 600 {} \; 2>/dev/null || true
    
    log_success "Configuración restaurada"
}

# Restaurar memoria
restore_memory() {
    log_info "Restaurando archivos de memoria..."
    
    local target_dir="$HOME/clawd"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Se restauraría memory a: $target_dir"
        return
    fi
    
    mkdir -p "$target_dir/memory"
    
    if [[ -d "$RESTORE_DIR/memory" ]]; then
        cp -r "$RESTORE_DIR/memory/"* "$target_dir/memory/" 2>/dev/null || true
        log_success "Memory restaurada ($(find "$RESTORE_DIR/memory" -type f | wc -l) archivos)"
    fi
    
    # Archivos específicos
    for file in MEMORY.md AGENTS.md USER.md; do
        if [[ -f "$RESTORE_DIR/memory/$file" ]]; then
            cp "$RESTORE_DIR/memory/$file" "$target_dir/"
        fi
    done
}

# Restaurar tools
restore_tools() {
    log_info "Restaurando tools..."
    
    local target_dir="$HOME/clawd/tools"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Se restaurarían tools a: $target_dir"
        return
    fi
    
    if [[ -d "$RESTORE_DIR/tools" ]]; then
        mkdir -p "$target_dir"
        cp -r "$RESTORE_DIR/tools/"* "$target_dir/" 2>/dev/null || true
        log_success "Tools restaurados"
    fi
}

# Verificar restauración
verify_restore() {
    log_info "Verificando restauración..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Saltando verificación"
        return
    fi
    
    # Verificar gateway config
    if [[ -f "$HOME/.clawdbot/clawdbot.json" ]]; then
        log_success "Gateway config presente"
    else
        log_warn "Gateway config no encontrado"
    fi
    
    # Verificar memory
    if [[ -d "$HOME/clawd/memory" ]] && [[ -n "$(ls -A $HOME/clawd/memory 2>/dev/null)" ]]; then
        log_success "Memory files presentes"
    fi
    
    # Test clawdbot
    if command -v clawdbot &> /dev/null; then
        if clawdbot status &> /dev/null; then
            log_success "Clawdbot funcionando"
        else
            log_warn "Clawdbot no responde. Puede necesitar reinicio."
        fi
    fi
}

# Limpiar
cleanup() {
    if [[ -d "$RESTORE_DIR" ]]; then
        rm -rf "$RESTORE_DIR"
        log_info "Archivos temporales eliminados"
    fi
}

# Main
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Clawdbot Restore Tool v1.0${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    parse_args "$@"
    decrypt_if_needed
    extract_backup
    show_backup_contents
    
    echo ""
    echo -e "${YELLOW}=======================================${NC}"
    echo -e "${YELLOW}  INICIANDO RESTAURACIÓN${NC}"
    echo -e "${YELLOW}=======================================${NC}"
    echo ""
    
    restore_config
    restore_memory
    restore_tools
    verify_restore
    
    if [[ "$DRY_RUN" == false ]]; then
        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}  Restauración Completada${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        echo "Próximos pasos:"
        echo "  1. Verificar configuración: clawdbot gateway status"
        echo "  2. Si es necesario: clawdbot gateway restart"
        echo "  3. Revisar logs: clawdbot logs"
    fi
    
    cleanup
}

# Ejecutar
trap cleanup EXIT
main "$@"
