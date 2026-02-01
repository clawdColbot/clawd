#!/bin/bash
#==============================================================================
set -euo pipefail
# setup_gmail.sh - Configuración de Gmail para finanzas
#==============================================================================

echo "=============================================="
echo "📧 CONFIGURACIÓN GMAIL - FINANZAS"
echo "=============================================="
echo ""

# Verificar credenciales
echo "📋 Credenciales configuradas:"
echo "   Email: clawdcol@gmail.com"
echo "   Password: [Configurado en script]"
echo ""

echo "⚠️  IMPORTANTE: Gmail requiere configuración especial"
echo ""
echo "Para que funcione, tienes 2 opciones:"
echo ""
echo "OPCIÓN 1: Contraseña de Aplicación (RECOMENDADA)"
echo "----------------------------------------------"
echo "1. Ve a https://myaccount.google.com/security"
echo "2. Activa 'Verificación en dos pasos' (si no está activa)"
echo "3. Busca 'Contraseñas de aplicación'"
echo "4. Genera una nueva para 'Otra (nombre personalizado)'"
echo "5. Nombre: 'Clawdbot Finance'"
echo "6. Copia la contraseña de 16 caracteres"
echo "7. Reemplaza en gmail_connector.py"
echo ""
echo "OPCIÓN 2: Acceso menos seguro (NO recomendado)"
echo "----------------------------------------------"
echo "1. Ve a https://myaccount.google.com/lesssecureapps"
echo "2. Activa 'Permitir el acceso de aplicaciones menos seguras'"
echo "3. Usa tu contraseña normal"
echo ""
echo "⚠️  NOTA: La opción 2 es menos segura y Google puede bloquearla"
echo ""

# Probar conexión
echo "🧪 ¿Quieres probar la conexión ahora? (s/N)"
read -r response

if [[ "$response" =~ ^[Ss]$ ]]; then
    echo ""
    echo "Probando conexión..."
    cd ~/clawd/tools/finance
    python3 gmail_connector.py --hours 1
fi

echo ""
echo "=============================================="
echo "📚 Comandos útiles:"
echo "=============================================="
echo ""
echo "Probar conexión:"
echo "  python3 ~/clawd/tools/finance/gmail_connector.py --hours 24"
echo ""
echo "Modo daemon (cada 5 minutos):"
echo "  python3 ~/clawd/tools/finance/gmail_connector.py --daemon"
echo ""
echo "Agregar a crontab (cada hora):"
echo "  0 * * * * ~/clawd/tools/finance/gmail_connector.py --hours 1"
echo ""
