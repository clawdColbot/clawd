# 💰 Sistema de Finanzas Personales

Sistema completo para seguimiento de gastos e ingresos mediante procesamiento de emails, con exportación a Google Sheets.

---

## 📁 Estructura

```
~/clawd/finance/
├── transactions.json          # Base de datos de transacciones
├── categories.json            # Configuración de categorías
├── export_gsheet.json         # Export para Google Sheets
├── finanzas_YYYY_MM.csv       # CSV mensual (auto-generado)
├── resumen_anual.csv          # Resumen anual
└── GSHEET_TEMPLATE.txt        # Plantilla Google Sheets

~/clawd/tools/finance/
├── finance_tracker.py         # Core del sistema
├── email_finance_handler.py   # Procesador de emails
└── gsheet_sync.py            # Sincronización con Sheets
```

---

## 🚀 Configuración Inicial

### 1. Configurar Email (Paso pendiente)

```bash
# Configurar cuenta de email para que Clawdbot pueda leer
# Opciones:
# - Gmail con OAuth
# - IMAP genérico
# - Forwarding a webhook

# Ejemplo con Gmail:
clawdbot config set email.provider=gmail
clawdbot config set email.sync_interval=5m
```

### 2. Probar Sistema

```bash
# Procesar un email de ejemplo
cd ~/clawd/tools/finance
python3 email_finance_handler.py process \
  "Compra aprobada en Éxito por $150,000" \
  "Su compra con tarjeta terminada en 1234 ha sido aprobada." \
  "notificaciones@banco.com"
```

### 3. Confirmar Transacción

```bash
# Confirmar con categoría
python3 email_finance_handler.py confirm -c 1 -n "Mercado semanal"
```

---

## 📊 Categorías Disponibles

| # | Categoría | Emoji | Uso típico |
|---|-----------|-------|------------|
| 1 | alimentacion | 🍽️ | Mercado, restaurantes, domicilios |
| 2 | transporte | 🚗 | Gasolina, Uber, transporte público |
| 3 | entretenimiento | 🎬 | Netflix, cine, eventos, hobbies |
| 4 | viajes | ✈️ | Vuelos, hoteles, tours, experiencias |
| 5 | salud | 💊 | Medicamentos, gimnasio, consultas |
| 6 | educacion | 📚 | Cursos, libros, certificaciones |
| 7 | tecnologia | 💻 | Software, hardware, suscripciones |
| 8 | gastos_fijos | 🏠 | Arriendo, servicios, internet |
| 9 | ingresos | 💰 | Salario, freelance, otros ingresos |
| 10 | ahorro | 🏦 | Ahorro de emergencia, fondos |
| 11 | inversiones | 📈 | Acciones, CDT, FIC, cripto, trading |
| 12 | sin_categoria | ⚪ | Por clasificar |

---

## 📧 Fuentes de Email Soportadas

### ✅ Bancos Configurados

| Banco | Remitente | Tipo | Cuenta/Tarjeta |
|-------|-----------|------|----------------|
| **Bancolombia** | alertas@bancolombia.com | Cuenta de Ahorros | Débito/Transferencias |
| **Davivienda** | DAVIbankInforma@davibank.com | Tarjetas de Crédito | Visa & Amex |
| **Nu** | (Manual por Telegram) | Tarjeta de Crédito | Nu |

### 🏦 Bancolombia
- **Asunto típico:** "Alertas y notificaciones"
- **Formato:** "Compraste en [comercio] por $[monto]" / "Transferiste en [comercio] por $[monto]"
- **Cuenta:** Cuenta de ahorros
- **Detección:** Automática por remitente y palabras clave

### 🏦 Davivienda
- **Remitente:** DAVIbankInforma@davibank.com
- **Formato:** Compras con tarjetas Visa y American Express
- **Detección:** Automática por remitente

### 💳 Nu (Manual)
- Como no llegan emails, informar por Telegram
- Formato: "Nu: $XX,XXX en [comercio] - [categoría]"

---

## 📧 Flujo de Trabajo

### Paso 1: Llega Email
```
Asunto: Alertas y notificaciones
Cuerpo: Compraste en Éxito por $150,000
Remitente: alertas@bancolombia.com
```

### Paso 2: Detección Automática
```bash
python3 email_finance_handler.py process \
  "Compra aprobada en Restaurante XYZ por $45,000" \
  "" \
  "notificaciones@banco.com"
```

**Output:**
```
💰 EMAIL FINANCIERO DETECTADO
📧 Asunto: Alertas y notificaciones
💵 Monto detectado: $150,000
🏪 Comercio: Éxito
📝 Tipo: gasto
🏷️  Categoría sugerida: alimentacion
📊 Fuente: Bancolombia

¿Qué categoría es correcta?
1. 🍽️  Alimentación ← Sugerido
2. 🚗 Transporte
3. 🎬 Entretenimiento
4. ✈️ Viajes
5. 💊 Salud
6. 📚 Educación
7. 💻 Tecnología
8. 🏠 Gastos Fijos
9. 💰 Ingresos
10. 🏦 Ahorro
11. 📈 Inversiones
12. ⚪ Sin categoría
```

### Paso 3: Confirmar
```bash
python3 email_finance_handler.py confirm -c 1 -n "Almuerzo de negocios"
```

### Paso 4: Exportar a Google Sheets
```bash
python3 gsheet_sync.py
```

---

## 📈 Dashboard en Google Sheets

### Hoja 1: Transacciones
Importar CSV generado (`finanzas_2025_01.csv`)

### Hoja 2: Dashboard
Fórmulas recomendadas:

```
Total Ingresos:
=SUMIF(Transacciones!E:E,"Ingreso",Transacciones!F:F)

Total Gastos:
=SUMIF(Transacciones!E:E,"Gasto",Transacciones!F:F)

Balance:
=Total_Ingresos - Total_Gastos

Por categoría:
=SUMIF(Transacciones!D:D,"alimentacion",Transacciones!F:F)
```

### Gráficos Sugeridos
1. **Gráfico circular**: Distribución de gastos por categoría
2. **Gráfico de barras**: Comparación mensual ingresos vs gastos
3. **Línea de tiempo**: Evolución del balance

---

## 🔄 Comandos Rápidos

```bash
# Ver reporte mensual
python3 finance_tracker.py report

# Ver transacciones pendientes
python3 email_finance_handler.py pending

# Exportar a CSV
python3 gsheet_sync.py

# Ver resumen
python3 finance_tracker.py report --month 1 --year 2025
```

---

## 🛠️ Integración Automática (Futuro)

### Opción 1: Webhook
```bash
# Configurar webhook para recibir emails
# Cada email llega a endpoint y ejecuta:
curl -X POST http://localhost:8080/finance \
  -d '{"subject":"...","body":"...","sender":"..."}'
```

### Opción 2: Polling cada 5 minutos
```bash
# Agregar a crontab
*/5 * * * * ~/clawd/tools/finance/poll_emails.sh
```

### Opción 3: IMAP Directo
```bash
# Conectar directamente a servidor IMAP
python3 email_imap_connector.py --check-new
```

---

## 📊 Reportes Disponibles

### Reporte Mensual
```
📊 RESUMEN FINANCIERO - 2025-01
==================================================
💰 Total Ingresos: $5,200,000
💸 Total Gastos: $3,800,000
📈 Balance: $1,400,000
⏳ Transacciones pendientes: 3

📋 Por Categoría:
   🍽️ alimentacion: $800,000 (12 trans.)
   🚗 transporte: $600,000 (8 trans.)
   🏠 gastos_fijos: $1,200,000 (4 trans.)
   ...
```

### Export CSV
```csv
Fecha,Hora,Descripción,Categoría,Tipo,Monto,Notas
2025-01-15,14:30,Restaurante XYZ,alimentacion,Gasto,45000,Almuerzo negocios
2025-01-15,09:00,Transferencia recibida,ingresos,Ingreso,2500000,Salario
...
```

---

## 🔒 Seguridad

- Datos almacenados localmente en `~/clawd/finance/`
- Sin envío a servicios externos (excepto export manual a Sheets)
- Permisos de archivo: 600 (solo usuario)

---

## 📅 Próximos Pasos

- [ ] Configurar cuenta de email
- [ ] Probar con primer email real
- [ ] Crear hoja de Google Sheets
- [ ] Importar datos iniciales
- [ ] Configurar recordatorios mensuales

---

*Sistema creado: 2026-01-31*
*Versión: 1.0*
