#!/bin/bash
#==============================================================================
# clawdbot-backup.sh - Backup completo de configuración Clawdbot
# 
# Crea backups comprimidos de:
# - Gateway config (clawdbot.json)
# - Memory files (daily logs, MEMORY.md)
# - Skills y configuraciones
# - Credentials (encriptados opcional)
#
# Uso: ./clawdbot-backup.sh [destino]
# Default destino: ~/clawd/backups/
#==============================================================================

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${1:-$HOME/clawd/backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="clawdbot_backup_${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"
RETENTION_DAYS=30

# Archivos a respaldar
CLAWDBOT_DIR="$HOME/clawd"
CONFIG_DIR="$HOME/.clawdbot"
SKILLS_DIR="$HOME/.moltbot/skills" 2>/dev/null || true

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar dependencias
check_dependencies() {
    log_info "Verificando dependencias..."
    
    if ! command -v tar &> /dev/null; then
        log_error "tar no está instalado. Instálalo con: sudo apt-get install tar"
        exit 1
    fi
    
    if command -v gpg &> /dev/null; then
        GPG_AVAILABLE=true
        log_success "GPG disponible para encriptación"
    else
        GPG_AVAILABLE=false
        log_warn "GPG no disponible. Los backups no estarán encriptados."
        log_warn "Instala con: sudo apt-get install gnupg"
    fi
}

# Crear directorio de backup
create_backup_dir() {
    log_info "Creando directorio de backup: $BACKUP_PATH"
    mkdir -p "$BACKUP_PATH"
    mkdir -p "$BACKUP_PATH/config"
    mkdir -p "$BACKUP_PATH/memory"
    mkdir -p "$BACKUP_PATH/skills"
    mkdir -p "$BACKUP_PATH/logs"
}

# Backup de configuración del gateway
backup_gateway_config() {
    log_info "Respaldando configuración del gateway..."
    
    if [[ -f "$CONFIG_DIR/clawdbot.json" ]]; then
        cp "$CONFIG_DIR/clawdbot.json" "$BACKUP_PATH/config/"
        log_success "Gateway config respaldado"
    else
        log_warn "No se encontró clawdbot.json"
    fi
    
    # Backup de systemd service si existe
    if [[ -f "$HOME/.config/systemd/user/clawdbot-gateway.service" ]]; then
        cp "$HOME/.config/systemd/user/clawdbot-gateway.service" "$BACKUP_PATH/config/"
        log_success "Systemd service respaldado"
    fi
    
    # Backup de environment files
    if [[ -f "$HOME/.clawdbot/.env" ]]; then
        cp "$HOME/.clawdbot/.env" "$BACKUP_PATH/config/"
        log_success "Environment file respaldado"
    fi
}

# Backup de archivos de memoria
backup_memory() {
    log_info "Respaldando archivos de memoria..."
    
    if [[ -d "$CLAWDBOT_DIR/memory" ]]; then
        cp -r "$CLAWDBOT_DIR/memory" "$BACKUP_PATH/"
        log_success "Memory files respaldados ($(find "$CLAWDBOT_DIR/memory" -type f | wc -l) archivos)"
    fi
    
    if [[ -f "$CLAWDBOT_DIR/MEMORY.md" ]]; then
        cp "$CLAWDBOT_DIR/MEMORY.md" "$BACKUP_PATH/memory/"
    fi
    
    if [[ -f "$CLAWDBOT_DIR/AGENTS.md" ]]; then
        cp "$CLAWDBOT_DIR/AGENTS.md" "$BACKUP_PATH/memory/"
    fi
    
    if [[ -f "$CLAWDBOT_DIR/USER.md" ]]; then
        cp "$CLAWDBOT_DIR/USER.md" "$BACKUP_PATH/memory/"
    fi
}

# Backup de skills
backup_skills() {
    log_info "Respaldando skills..."
    
    if [[ -d "$SKILLS_DIR" ]]; then
        # Solo backup de configs, no de todo el código
        find "$SKILLS_DIR" -name "*.json" -o -name "*.yaml" -o -name "*.yml" 2>/dev/null | \
        while read -r file; do
            target_dir="$BACKUP_PATH/skills/$(dirname "$file" | sed "s|$SKILLS_DIR||")"
            mkdir -p "$target_dir"
            cp "$file" "$target_dir/"
        done
        log_success "Skills configs respaldadas"
    else
        log_warn "Directorio de skills no encontrado"
    fi
}

# Backup de tools personalizados
backup_tools() {
    log_info "Respaldando tools personalizados..."
    
    if [[ -d "$CLAWDBOT_DIR/tools" ]]; then
        cp -r "$CLAWDBOT_DIR/tools" "$BACKUP_PATH/"
        log_success "Tools respaldados"
    fi
}

# Backup de credentials (con advertencia)
backup_credentials() {
    log_info "Respaldando credentials..."
    
    if [[ -d "$CLAWDBOT_DIR/credentials" ]]; then
        # Crear directorio con permisos restrictivos
        mkdir -p "$BACKUP_PATH/credentials"
        chmod 700 "$BACKUP_PATH/credentials"
        
        cp -r "$CLAWDBOT_DIR/credentials"/* "$BACKUP_PATH/credentials/" 2>/dev/null || true
        chmod 600 "$BACKUP_PATH/credentials"/* 2>/dev/null || true
        
        log_warn "Credentials respaldados (¡manejar con cuidado!)"
    fi
}

# Crear archivo de metadatos
create_metadata() {
    log_info "Creando metadatos..."
    
    cat > "$BACKUP_PATH/BACKUP_INFO.txt" << EOF
Clawdbot Backup
================
Fecha: $(date)
Hostname: $(hostname)
Usuario: $(whoami)
Clawdbot Version: $(clawdbot --version 2>/dev/null || echo "unknown")

Contenido:
- config/: Configuración del gateway y systemd
- memory/: Archivos de memoria y contexto
- skills/: Configuraciones de skills
- tools/: Scripts y herramientas personalizadas
- credentials/: API keys y tokens (encriptar antes de mover)

Restauración:
1. Descomprimir backup
2. Copiar archivos a sus ubicaciones originales
3. Verificar permisos (chmod 600 para credentials)
4. Reiniciar gateway: clawdbot gateway restart

Para encriptar este backup:
gpg -c ${BACKUP_NAME}.tar.gz
EOF
}

# Comprimir backup
compress_backup() {
    log_info "Comprimiendo backup..."
    
    cd "$BACKUP_DIR"
    tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
    
    # Eliminar directorio temporal
    rm -rf "$BACKUP_PATH"
    
    BACKUP_SIZE=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)
    log_success "Backup creado: ${BACKUP_NAME}.tar.gz ($BACKUP_SIZE)"
}

# Opcional: Encriptar backup
encrypt_backup() {
    if [[ "$GPG_AVAILABLE" == true ]]; then
        log_info "Encriptando backup..."
        
        cd "$BACKUP_DIR"
        gpg --symmetric --cipher-algo AES256 \
            --output "${BACKUP_NAME}.tar.gz.gpg" \
            "${BACKUP_NAME}.tar.gz"
        
        # Eliminar versión sin encriptar
        rm "${BACKUP_NAME}.tar.gz"
        
        log_success "Backup encriptado: ${BACKUP_NAME}.tar.gz.gpg"
        log_info "Para desencriptar: gpg -d ${BACKUP_NAME}.tar.gz.gpg | tar -xzf -"
    fi
}

# Limpiar backups antiguos
cleanup_old_backups() {
    log_info "Limpiando backups antiguos (>${RETENTION_DAYS} días)..."
    
    cd "$BACKUP_DIR"
    find . -name "clawdbot_backup_*.tar.gz*" -mtime +$RETENTION_DAYS -delete
    
    log_success "Limpieza completada"
}

# Verificar backup
verify_backup() {
    log_info "Verificando integridad del backup..."
    
    cd "$BACKUP_DIR"
    
    if [[ -f "${BACKUP_NAME}.tar.gz.gpg" ]]; then
        if gpg --list-packets "${BACKUP_NAME}.tar.gz.gpg" > /dev/null 2>&1; then
            log_success "Backup encriptado verificado"
        else
            log_error "Error verificando backup encriptado"
        fi
    elif [[ -f "${BACKUP_NAME}.tar.gz" ]]; then
        if tar -tzf "${BACKUP_NAME}.tar.gz" > /dev/null 2>&1; then
            log_success "Backup verificado"
        else
            log_error "Error verificando backup"
        fi
    fi
}

# Resumen final
print_summary() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Backup Completado Exitosamente${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Ubicación: $BACKUP_DIR"
    
    if [[ -f "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz.gpg" ]]; then
        echo "Archivo: ${BACKUP_NAME}.tar.gz.gpg (encriptado)"
    else
        echo "Archivo: ${BACKUP_NAME}.tar.gz"
    fi
    
    echo "Tamaño: $(du -h "${BACKUP_DIR}/${BACKUP_NAME}"* | head -1 | cut -f1)"
    echo ""
    echo "Para restaurar:"
    echo "  1. cd $BACKUP_DIR"
    if [[ -f "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz.gpg" ]]; then
        echo "  2. gpg -d ${BACKUP_NAME}.tar.gz.gpg | tar -xzf -"
    else
        echo "  2. tar -xzf ${BACKUP_NAME}.tar.gz"
    fi
    echo ""
}

# Main
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Clawdbot Backup Tool v1.0${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    check_dependencies
    create_backup_dir
    backup_gateway_config
    backup_memory
    backup_skills
    backup_tools
    backup_credentials
    create_metadata
    compress_backup
    encrypt_backup
    cleanup_old_backups
    verify_backup
    print_summary
}

# Ejecutar
main "$@"
