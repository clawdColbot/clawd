#!/bin/bash
#
set -euo pipefail
# morning_briefing.sh - Genera resumen diario automático
# Ideal para ejecutar por cron cada mañana
#

REPORT_DIR="${HOME}/clawd/reports"
mkdir -p "$REPORT_DIR"

DATE=$(date '+%Y-%m-%d')
TIME=$(date '+%H:%M')
REPORT_FILE="${REPORT_DIR}/briefing-${DATE}.md"

echo "🌅 Generando Morning Briefing para ${DATE}..."

# Iniciar reporte
cat > "$REPORT_FILE" << EOF
# 🌅 Morning Briefing - ${DATE} ${TIME}

## 📅 Hoy
$(date '+%A, %d de %B %Y')

## 🌤️ Clima
$(curl -s "wttr.in/?format=3" 2>/dev/null || echo "No disponible")

## 💻 Estado del Sistema
EOF

# Estado del sistema
echo "- **Disco:** $(df -h / | tail -1 | awk '{print $5 " usado (" $4 " libre)"}')" >> "$REPORT_FILE"
echo "- **RAM:** $(free -h | grep Mem | awk '{print $3 " usado / " $2 " total"}')" >> "$REPORT_FILE"
echo "- **Uptime:** $(uptime -p 2>/dev/null || uptime | awk -F',' '{print $1}')" >> "$REPORT_FILE"

# Emails pendientes
if command -v himalaya &> /dev/null; then
    echo "" >> "$REPORT_FILE"
    echo "## 📧 Emails" >> "$REPORT_FILE"
    UNREAD=$(himalaya list --page-size 50 2>/dev/null | grep -c "UNREAD" || echo "0")
    echo "- **No leídos:** ${UNREAD}" >> "$REPORT_FILE"
fi

# Tareas pendientes
if [ -f "${HOME}/clawd/memory/active-tasks.md" ]; then
    echo "" >> "$REPORT_FILE"
    echo "## 📋 Tareas Activas" >> "$REPORT_FILE"
    grep "^\- \[ \]" "${HOME}/clawd/memory/active-tasks.md" 2>/dev/null | head -5 >> "$REPORT_FILE" || echo "- Sin tareas pendientes" >> "$REPORT_FILE"
fi

# Proyectos activos
if [ -d "${HOME}/projects" ]; then
    echo "" >> "$REPORT_FILE"
    echo "## 🚀 Proyectos" >> "$REPORT_FILE"
    for proj in $(ls -td ${HOME}/projects/*/ 2>/dev/null | head -3); do
        name=$(basename "$proj")
        echo "- **${name}** - Última actividad: $(stat -c %y "$proj" 2>/dev/null | cut -d' ' -f1)" >> "$REPORT_FILE"
    done
fi

# Memoria reciente
LATEST_MEMORY=$(ls -t ${HOME}/clawd/memory/*.md 2>/dev/null | head -1)
if [ -n "$LATEST_MEMORY" ]; then
    echo "" >> "$REPORT_FILE"
    echo "## 📝 Memoria Reciente" >> "$REPORT_FILE"
    echo "Última actualización: $(basename $LATEST_MEMORY)" >> "$REPORT_FILE"
fi

# Moltbook activity (si hay API disponible)
echo "" >> "$REPORT_FILE"
echo "## 🦞 Moltbook" >> "$REPORT_FILE"
echo "- Posts hot disponibles para revisar" >> "$REPORT_FILE"

# Finalizar
cat >> "$REPORT_FILE" << EOF

---

*Generado automáticamente por Clawd 🦊*
EOF

echo "✅ Reporte guardado en: $REPORT_FILE"

# Enviar a Telegram si está configurado
if [ -n "$TELEGRAM_CHAT_ID" ] && [ -n "$TELEGRAM_BOT_TOKEN" ]; then
    MESSAGE="🌅 Morning Briefing ${DATE}\n\n$(head -20 "$REPORT_FILE")"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${MESSAGE}" \
        -d "parse_mode=Markdown" > /dev/null 2>&1
    echo "📱 Enviado a Telegram"
fi

# Mostrar resumen
cat "$REPORT_FILE"
