# 🛡️ SECURITY CONFIGURATION - ClawdColombia
# Implementación de protecciones de seguridad

## 1. Prompt Injection Protection

### Instalación del Guard
```bash
# El módulo ya está en ~/clawd/security/prompt-injection-guard.js
# Agregar a AGENTS.md para carga automática
```

### Uso en código
```javascript
const { ClawdbotSecurityWrapper } = require('./security/prompt-injection-guard.js');
const security = new ClawdbotSecurityWrapper();

// Antes de procesar cualquier archivo PDF/TXT
const fileCheck = security.interceptFile('documento.pdf', contenido);
if (!fileCheck.allowed) {
  console.error('Archivo bloqueado:', fileCheck.error);
  return;
}

// Verificar prompts sospechosos
const promptCheck = security.verifyPrompt(userInput);
if (!promptCheck.safe) {
  console.error('Prompt bloqueado por seguridad');
  return;
}
```

## 2. Protección de Credenciales

### Permisos restrictivos
```bash
chmod 600 ~/.config/moltbook/credentials.json
chmod 600 ~/.clawdbot/clawdbot.json
chmod 700 ~/.config/moltbook/
chmod 700 ~/.clawdbot/
```

### Variables de entorno (recomendado)
```bash
# ~/.bashrc o ~/.zshrc
export MOLTBOOK_API_KEY="moltbook_sk_..."
export CLAWDBOT_GATEWAY_TOKEN="..."

# En lugar de archivos JSON para credenciales sensibles
```

## 3. Sandbox Configuration

### Configuración actual (ya implementada)
- Sandbox activado para subagentes
- Workspace aislado: /home/durango/clawd
- Sin acceso root por defecto

### Mejoras adicionales
```json
{
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "non-main",
        "workspaceAccess": "ro",
        "tools": {
          "deny": ["exec", "shell"]
        }
      }
    }
  }
}
```

## 4. Monitoreo de Seguridad

### Verificación semanal automática
```bash
#!/bin/bash
# ~/clawd/security/weekly-check.sh

echo "🔒 Security Check - $(date)"

# Verificar permisos de archivos sensibles
ls -la ~/.config/moltbook/credentials.json
ls -la ~/.clawdbot/clawdbot.json

# Verificar logs de inyección
if [ -f logs/injection-guard.log ]; then
  echo "Violaciones recientes:"
  tail -20 logs/injection-guard.log
fi

# Verificar procesos sospechosos
ps aux | grep -E "(nc|netcat|ncat|python.*http)" | grep -v grep

echo "✅ Check completado"
```

### Agregar al crontab
```bash
0 9 * * 1 /home/durango/clawd/security/weekly-check.sh >> /home/durango/clawd/security/audit.log 2>&1
```

## 5. Backup de Credenciales

### Script de backup encriptado
```bash
#!/bin/bash
# backup-secrets.sh

cd ~
tar czf - .config/moltbook .clawdbot | \
  gpg --symmetric --cipher-algo AES256 -o /secure/backup/clawd-secrets-$(date +%Y%m%d).gpg

# Limpieza de backups antiguos (mantener últimos 5)
ls -t /secure/backup/clawd-secrets-*.gpg | tail -n +6 | xargs rm -f
```

## 6. Políticas de Seguridad

### Reglas para archivos entrantes
1. **Nunca** procesar archivos sin verificar con injection-guard
2. **Nunca** ejecutar código de fuentes no verificadas
3. **Siempre** loggear accesos a credenciales
4. **Siempre** rotar API keys cada 90 días

### Lista de verificación antes de ejecutar código externo
- [ ] Verificado con injection-guard
- [ ] Revisado por humano (Andres) si es crítico
- [ ] Ejecutado en sandbox primero
- [ ] Sin acceso a credenciales reales

## 7. Incident Response

### Si detectamos inyección exitosa
1. Inmediatamente: Desconectar Gateway
2. Revisar logs: ~/.clawdbot/logs/
3. Rotar todas las API keys
4. Verificar integridad de archivos
5. Reportar a Andres inmediatamente

### Contactos de emergencia
- Andres: [número/privado]
- Email: clawdcol@gmail.com
