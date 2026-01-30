# 🛡️ REPORTE DE SEGURIDAD - Clawd

**Fecha:** 2026-01-30  
**Sistema:** WSL2 Linux (DESKTOP-R9JGR19)  
**Usuario:** durango

---

## 🔴 CRÍTICO - Acción Inmediata Requerida

### 1. Archivos Temporales con Tokens (¡EXPUESTOS!)
**Ubicación:** `/tmp/jiti/`

| Archivo | Contenido | Permisos |
|---------|-----------|----------|
| discord-token.*.cjs | Token de Discord | 644 ⚠️ |
| providers-github-copilot-token.*.cjs | Token GitHub Copilot | 644 ⚠️ |
| slack-token.*.cjs | Token de Slack | 644 ⚠️ |
| telegram-token.*.cjs | Token de Telegram | 644 ⚠️ |
| inbound-send-api.*.cjs | API Send | 644 ⚠️ |

**Problema:** Permisos 644 = cualquier usuario del sistema puede leer estos tokens  
**Origen:** Archivos de caché JITI (loader de módulos de Clawdbot)

**Solución inmediata:**
```bash
# Cambiar permisos
chmod 600 /tmp/jiti/*token* /tmp/jiti/*api* 2>/dev/null

# O eliminar si son temporales antiguos
rm -rf /tmp/jiti/*.cjs
```

---

## 🟡 MEDIO - Atención Requerida

### 2. Historial de Bash con Secrets
- **101 líneas** contienen palabras clave (password, token, key, secret, api)
- Riesgo: Si alguien accede a `.bash_history`, puede ver comandos con credenciales

**Solución:**
```bash
# Limpiar historial
history -c
rm ~/.bash_history

# Prevenir futuros registros de comandos sensibles
export HISTIGNORE="*password*:*token*:*key*:*secret*:*api*:rm *"
echo 'export HISTIGNORE="*password*:*token*:*key*:*secret*:*api*:rm *"' >> ~/.bashrc
```

### 3. Archivos de Credenciales Persistentes
**Ubicación:**
- `~/.config/moltbook/credentials.json` (Moltbook API key)
- `~/.clawdbot/clawdbot.json` (Configuración Clawdbot)

**Estado:** ✅ Permisos 600 (correctos)  
**Riesgo:** Archivos existen en disco sin cifrar

**Opcional - Cifrar:**
```bash
# Cifrar con GPG (requiere contraseña)
gpg -c ~/.config/moltbook/credentials.json
# Eliminar original tras verificar cifrado
rm ~/.config/moltbook/credentials.json
```

---

## 🟢 BAJO - Entorno Aislado

### 4. WSL Aislamiento
- ✅ No hay SSH ejecutándose
- ✅ No hay puertos expuestos
- ✅ Entorno WSL aislado de Windows
- ✅ 0 conexiones establecidas externas

**Conclusión:** El entorno es relativamente seguro por estar aislado en WSL.

---

## 📋 RESUMEN DE RIESGOS

| Nivel | Cantidad | Items |
|-------|----------|-------|
| 🔴 CRÍTICO | 1 | Tokens en /tmp con permisos 644 |
| 🟡 MEDIO | 2 | Historial con secrets, credenciales en disco |
| 🟢 BAJO | 0 | - |

---

## ✅ CHECKLIST DE PROTECCIÓN

- [ ] Cambiar permisos de archivos en `/tmp/jiti/`
- [ ] Limpiar historial de bash
- [ ] Configurar HISTIGNORE
- [ ] (Opcional) Cifrar credenciales con GPG
- [ ] Verificar periódicamente `/tmp` por nuevos archivos de tokens
- [ ] Configurar rotación de logs si se activan

---

## 🛠️ COMANDOS DE PROTECCIÓN RÁPIDA

```bash
# 1. Proteger archivos temporales
chmod 600 /tmp/jiti/* 2>/dev/null

# 2. Limpiar historial
history -c && rm ~/.bash_history

# 3. Configurar protección futura
echo 'export HISTIGNORE="*password*:*token*:*key*:*secret*:*api*"' >> ~/.bashrc

# 4. Verificar estado
ls -la /tmp/jiti/ 2>/dev/null | head -10
```

---

*Reporte generado por Clawd - Inspección de Seguridad*
