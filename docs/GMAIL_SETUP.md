# 📧 Configuración Gmail - Solución de Autenticación

## Problema
Google bloquea el acceso IMAP con contraseñas normales por seguridad.

## Solución: Contraseña de Aplicación

### Paso 1: Verificar 2FA
1. Ve a https://myaccount.google.com/security
2. Asegúrate de que "Verificación en dos pasos" esté **ACTIVADA**
3. Si no está activada, actívala primero

### Paso 2: Generar Contraseña de App
1. En la misma página de seguridad, busca "Contraseñas de aplicación"
2. Haz clic en "Contraseñas de aplicación"
3. Selecciona "Otra (nombre personalizado)"
4. Escribe: "Clawdbot Finance"
5. Haz clic en "Generar"
6. **Copia la contraseña de 16 caracteres** (ejemplo: abcd efgh ijkl mnop)

### Paso 3: Actualizar Script
Edita el archivo `gmail_connector.py`:

```bash
nano ~/clawd/tools/finance/gmail_connector.py
```

Cambia esta línea:
```python
GMAIL_PASS = "HpAHs2upg6kP2x8skAR7"
```

Por la nueva contraseña de aplicación:
```python
GMAIL_PASS = "tu-nueva-contrasena-de-16-caracteres"
```

### Paso 4: Probar
```bash
python3 ~/clawd/tools/finance/gmail_connector.py --hours 24
```

---

## Alternativa: Webhook Manual

Si Gmail sigue sin funcionar, podemos usar este flujo:

1. **Tú reenvías** los emails importantes a una dirección específica
2. O **me los compartes** por Telegram con formato:
```
Banco: Bancolombia
Monto: $150,000
Comercio: Éxito
Fecha: 2025-01-31
```

---

## Alternativa: Forwarding a Webhook

Configura regla en Gmail para reenviar emails de bancos a un webhook:

1. Gmail → Configuración → Reenvío
2. Crear filtro: De `alertas@bancolombia.com` OR `DAVIbankInforma@davibank.com`
3. Acción: Reenviar a webhook de Clawdbot

(Esto requiere configuración adicional del servidor)

---

## Comandos Disponibles

```bash
# Probar conexión (24 horas)
python3 ~/clawd/tools/finance/gmail_connector.py --hours 24

# Modo daemon (revisa cada 5 minutos)
python3 ~/clawd/tools/finance/gmail_connector.py --daemon

# Ver emails ya procesados
cat ~/clawd/finance/processed_emails.json

# Ver transacciones
cat ~/clawd/finance/transactions.json | jq '.[-5:]'
```

---

## ¿Qué hacer ahora?

**Opción A:** Configurar contraseña de aplicación (recomendado)
- Tiempo: ~5 minutos
- Automático después

**Opción B:** Notificar manual por Telegram
- Me dices: "Bancolombia: $XX,XXX en [comercio]"
- Yo lo proceso

**¿Cuál prefieres?**
