#!/bin/bash
# 🛡️ Gateway Security Audit Script
# Basado en recomendaciones de Moltbook - ClawdNottsOps31
# Verifica configuración segura del gateway Clawdbot

echo "=========================================="
echo "🔒 GATEWAY SECURITY AUDIT"
echo "=========================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

WARNINGS=0
ERRORS=0

# 1. Verificar si el gateway está expuesto a internet
echo "📡 1. Verificando exposición de red..."
GATEWAY_BIND=$(clawdbot config get gateway.bind 2>/dev/null || echo "unknown")
if [ "$GATEWAY_BIND" = "loopback" ] || [ "$GATEWAY_BIND" = "127.0.0.1" ]; then
    echo -e "${GREEN}✅${NC} Gateway solo en loopback (127.0.0.1) - Seguro"
elif [ "$GATEWAY_BIND" = "lan" ] || [ "$GATEWAY_BIND" = "0.0.0.0" ]; then
    echo -e "${YELLOW}⚠️${NC} Gateway expuesto a LAN - Verificar firewall"
    ((WARNINGS++))
else
    echo -e "${GREEN}✅${NC} Gateway bind: $GATEWAY_BIND"
fi
echo ""

# 2. Verificar autenticación
echo "🔐 2. Verificando autenticación..."
AUTH_MODE=$(clawdbot config get gateway.auth.mode 2>/dev/null || echo "unknown")
if [ "$AUTH_MODE" = "token" ]; then
    echo -e "${GREEN}✅${NC} Autenticación por token activa"
    
    # Verificar longitud del token
    TOKEN=$(clawdbot config get gateway.auth.token 2>/dev/null | head -c 20)
    if [ ${#TOKEN} -lt 32 ]; then
        echo -e "${RED}❌${NC} Token muy corto (${#TOKEN} chars) - Mínimo recomendado: 32"
        ((ERRORS++))
    else
        echo -e "${GREEN}✅${NC} Token length: OK (${#TOKEN}+ chars)"
    fi
else
    echo -e "${RED}❌${NC} Auth mode: $AUTH_MODE - Se recomienda 'token'"
    ((ERRORS++))
fi
echo ""

# 3. Verificar Tailscale/Funnel (exposición pública)
echo "🌐 3. Verificando exposición pública..."
TAILSCALE_MODE=$(clawdbot config get gateway.tailscale.mode 2>/dev/null || echo "off")
if [ "$TAILSCALE_MODE" = "off" ]; then
    echo -e "${GREEN}✅${NC} Tailscale/Funnel: OFF - Sin exposición pública"
else
    echo -e "${YELLOW}⚠️${NC} Tailscale mode: $TAILSCALE_MODE"
    echo "   Asegúrate de que sea intencional"
    ((WARNINGS++))
fi
echo ""

# 4. Verificar permisos de archivos sensibles
echo "📁 4. Verificando permisos de archivos..."
CONFIG_FILE="$HOME/.clawdbot/clawdbot.json"
if [ -f "$CONFIG_FILE" ]; then
    PERMS=$(stat -c %a "$CONFIG_FILE" 2>/dev/null || stat -f %Lp "$CONFIG_FILE" 2>/dev/null)
    if [ "$PERMS" = "600" ]; then
        echo -e "${GREEN}✅${NC} Config file permissions: 600 (correcto)"
    else
        echo -e "${YELLOW}⚠️${NC} Config file permissions: $PERMS - Recomendado: 600"
        echo "   Fix: chmod 600 $CONFIG_FILE"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}⚠️${NC} Config file no encontrado en ubicación estándar"
fi
echo ""

# 5. Verificar variables de entorno sensibles
echo "🔑 5. Verificando variables de entorno..."
if env | grep -q "TOKEN\|PASSWORD\|SECRET\|KEY"; then
    echo -e "${YELLOW}⚠️${NC} Se encontraron posibles secrets en variables de entorno"
    echo "   Considera usar archivos de configuración en lugar de env vars"
    ((WARNINGS++))
else
    echo -e "${GREEN}✅${NC} No hay secrets obvios en variables de entorno"
fi
echo ""

# 6. Verificar conexiones activas
echo "🌍 6. Verificando conexiones de red..."
PORT=$(clawdbot config get gateway.port 2>/dev/null || echo "18789")
EXTERNAL_CONNECTIONS=$(netstat -tuln 2>/dev/null | grep ":$PORT " | grep -v "127.0.0.1" | wc -l)
if [ "$EXTERNAL_CONNECTIONS" -gt 0 ]; then
    echo -e "${RED}❌${NC} Gateway escuchando en interfaces externas"
    netstat -tuln 2>/dev/null | grep ":$PORT " | grep -v "127.0.0.1"
    ((ERRORS++))
else
    echo -e "${GREEN}✅${NC} Gateway solo en localhost:$PORT"
fi
echo ""

# 7. Verificar servicio systemd (si aplica)
echo "⚙️  7. Verificando servicio systemd..."
if systemctl --user is-active clawdbot-gateway.service &>/dev/null; then
    echo -e "${GREEN}✅${NC} Servicio systemd: Activo"
    
    # Verificar si el servicio reinicia automáticamente
    RESTART_POLICY=$(systemctl --user show clawdbot-gateway.service --property=Restart 2>/dev/null | cut -d= -f2)
    if [ "$RESTART_POLICY" = "always" ] || [ "$RESTART_POLICY" = "on-failure" ]; then
        echo -e "${GREEN}✅${NC} Restart policy: $RESTART_POLICY"
    else
        echo -e "${YELLOW}⚠️${NC} Restart policy: $RESTART_POLICY - Recomendado: always"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}⚠️${NC} No se detectó servicio systemd (ejecutando manualmente)"
fi
echo ""

# 8. Verificar logs de errores recientes
echo "📋 8. Verificando logs recientes..."
if [ -f "/tmp/clawdbot/clawdbot-$(date +%Y-%m-%d).log" ]; then
    ERROR_COUNT=$(grep -i "error\|fail\|unauthorized" "/tmp/clawdbot/clawdbot-$(date +%Y-%m-%d).log" 2>/dev/null | wc -l)
    if [ "$ERROR_COUNT" -gt 10 ]; then
        echo -e "${YELLOW}⚠️${NC} $ERROR_COUNT errores en logs de hoy"
        ((WARNINGS++))
    else
        echo -e "${GREEN}✅${NC} Errores en logs: $ERROR_COUNT (aceptable)"
    fi
else
    echo -e "${YELLOW}⚠️${NC} No se encontraron logs del día"
fi
echo ""

# Resumen
echo "=========================================="
echo "📊 RESUMEN DEL AUDIT"
echo "=========================================="
echo -e "Errores críticos: ${RED}$ERRORS${NC}"
echo -e "Advertencias: ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ Configuración segura${NC}"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️ Configuración aceptable con advertencias${NC}"
else
    echo -e "${RED}❌ Configuración insegura - Requiere atención${NC}"
fi
echo ""

# Recomendaciones
echo "💡 RECOMENDACIONES:"
echo "   1. Mantén gateway.bind en 'loopback' para uso local"
echo "   2. Usa tokens de al menos 32 caracteres"
echo "   3. Activa auto-restart en systemd"
echo "   4. Revisa logs regularmente: clawdbot logs --errors"
echo "   5. Para acceso remoto, usa Tailscale/VPN en lugar de exponer puertos"
echo ""
echo "📚 Documentación: https://docs.clawd.bot/security"
