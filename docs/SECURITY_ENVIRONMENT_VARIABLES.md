# 🛡️ Guía de Seguridad - Variables de Entorno

**Fecha:** 2026-01-31  
**Motivo:** Proteger API keys de exposición accidental

---

## ✅ Qué se hizo

### 1. Archivo `.env` creado
- **Ubicación:** `~/.clawdbot/.env`
- **Permisos:** 600 (solo propietario puede leer)
- **Contenido:** API keys de Telegram, Brave, Gateway token

### 2. Template de configuración
- **Archivo:** `~/.clawdbot/clawdbot.json.template`
- Usa placeholders: `${CLAWDBOT_TELEGRAM_BOT_TOKEN}`
- No contiene secretos reales

### 3. Script de aplicación
- **Archivo:** `~/.clawdbot/apply-env-config.sh`
- Aplica variables de entorno al template
- Genera `clawdbot.json` con valores reales
- Crea backup automático

### 4. Gitignore actualizado
- `.env` añadido a `.gitignore`
- Evita commits accidentales de secretos

---

## 📁 Estructura de archivos

```
~/.clawdbot/
├── .env                          # ⚠️ SECRETOS - chmod 600
├── .env.example                  # Template sin valores reales
├── clawdbot.json                 # Generado (con valores reales)
├── clawdbot.json.template        # Template con placeholders
├── apply-env-config.sh           # Script de aplicación
└── clawdbot.json.bak.*           # Backups automáticos
```

---

## 🚀 Uso

### Aplicar configuración
```bash
# Cargar variables y generar config
~/.clawdbot/apply-env-config.sh

# Reiniciar Clawdbot
clawdbot gateway restart
```

### Verificar seguridad
```bash
# Verificar permisos
cd ~/.clawdbot && ls -la .env clawdbot.json

# Confirmar que .env está en gitignore
cd ~/clawd && cat .gitignore | grep ".env"

# Verificar que no hay secretos en el config template
grep -E "apiKey|botToken|token" ~/.clawdbot/clawdbot.json.template
# Debe mostrar placeholders como ${CLAWDBOT_BRAVE_API_KEY}
```

---

## 🔒 Buenas prácticas

### 1. Permisos de archivos
```bash
chmod 600 ~/.clawdbot/.env
chmod 600 ~/.clawdbot/clawdbot.json
chmod 700 ~/.clawdbot
```

### 2. Backup del .env
```bash
# Copiar a ubicación segura (ej: password manager)
cp ~/.clawdbot/.env ~/secure-backup/clawdbot-env-backup.txt
```

### 3. Rotación de tokens (cada 90 días)
- Telegram: @BotFather → /revoke → /token
- Brave: Dashboard → Regenerate API Key
- Gateway: `openssl rand -hex 24`

### 4. Verificación periódica
```bash
# Buscar accidental exposición
grep -r "BSAEFs96" ~/clawd/ 2>/dev/null || echo "OK - No expuesto"
grep -r "8170451463:AAGC" ~/clawd/ 2>/dev/null || echo "OK - No expuesto"
```

---

## ⚠️ Qué NO hacer

❌ **NUNCA:**
- Hacer `git add .env`
- Compartir pantalla con el archivo .env abierto
- Subir el .env a GitHub/GitLab
- Enviar el .env por email/chat
- Copiar/pegar el .env en logs

❌ **NUNCA hacer commit de:**
- `clawdbot.json` (después de aplicar variables)
- Cualquier archivo con `_bak_*` que contenga secretos
- Archivos de log que muestren API keys

---

## 🔄 Recuperación de desastres

### Si el .env se borra
```bash
# Restaurar del backup
# O regenerar tokens:
# - Telegram: @BotFather
# - Brave: https://brave.com/search/api/
# - Gateway: openssl rand -hex 24
```

### Si hay sospecha de compromiso
1. Revocar todos los tokens inmediatamente
2. Generar nuevos en servicios correspondientes
3. Actualizar el archivo .env
4. Aplicar nueva configuración
5. Reiniciar Clawdbot

---

## 📝 Variables soportadas

| Variable | Descripción | Servicio |
|----------|-------------|----------|
| `CLAWDBOT_TELEGRAM_BOT_TOKEN` | Token del bot de Telegram | @BotFather |
| `CLAWDBOT_BRAVE_API_KEY` | API key para búsquedas web | Brave Search |
| `CLAWDBOT_GATEWAY_TOKEN` | Token de auth del gateway | Auto-generado |
| `CLAWDBOT_KIMI_API_KEY` | API key para Kimi Code | Kimi (opcional) |

---

## ✅ Checklist de seguridad

- [ ] Archivo `.env` tiene permisos 600
- [ ] `.env` está en `.gitignore`
- [ ] `clawdbot.json.template` no tiene valores reales
- [ ] Script `apply-env-config.sh` funciona
- [ ] Backups de `.env` en lugar seguro
- [ ] Rotación de tokens programada (90 días)

---

*Seguridad implementada por Clawd 🦊*
