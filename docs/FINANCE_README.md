# 💰 Sistema de Finanzas - Configuración Completa

## ✅ Estado: Listo para usar

### 🏦 Fuentes Configuradas

| Fuente | Método | Estado |
|--------|--------|--------|
| **Bancolombia** (Cuenta Ahorros) | Gmail IMAP | ⚠️ Necesita configurar App Password |
| **Davivienda** (Visa/Amex) | Gmail IMAP | ⚠️ Necesita configurar App Password |
| **Nu** (Tarjeta) | Telegram Manual | ✅ Funciona ahora |
| **Otras** | Telegram Manual | ✅ Funciona ahora |

---

## 📧 Gmail: Necesita Configuración

### Problema
Google requiere "Contraseña de Aplicación" para acceso IMAP.

### Solución (5 minutos)
1. Ve a https://myaccount.google.com/security
2. Activa "Verificación en dos pasos" (si no está activa)
3. Busca "Contraseñas de aplicación"
4. Genera una nueva: "Clawdbot Finance"
5. **Copia la contraseña de 16 caracteres**
6. Edita `gmail_connector.py` y actualiza `GMAIL_PASS`

### Verificar
```bash
python3 ~/clawd/tools/finance/gmail_connector.py --hours 24
```

---

## 💬 Telegram: Funciona Ahora

### Formato para notificarme

**Opción 1: Simple**
```
Nu: $50,000 en Uber
```

**Opción 2: Detallado**
```
Bancolombia: Compra $150,000 en Éxito - mercado semanal
```

**Opción 3: Solo monto y comercio**
```
$45,000 en Restaurante Andres
```

### Yo responderé
```
✅ Transacción detectada:
   💰 Monto: $50,000
   🏪 Comercio: Uber
   🏦 Banco: Nu
   📝 Tipo: gasto
   🏷️  Sugerido: transporte

¿Qué categoría es correcta?
1. 🍽️ Alimentación
2. 🚗 Transporte ← Sugerido
3. ...
```

### Tú respondes
```
2 viaje al aeropuerto
```

Y yo guardo: Transporte - "viaje al aeropuerto"

---

## 📂 Estructura de Archivos

```
~/clawd/finance/
├── transactions.json           # Todas las transacciones
├── processed_emails.json       # IDs de emails procesados
├── export_gsheet.json          # Export para Google Sheets
├── finanzas_YYYY_MM.csv        # CSV mensual (auto)
└── resumen_anual.csv           # Resumen anual (auto)
```

---

## 📊 Categorías Disponibles

| # | Emoji | Categoría | Detecta automáticamente |
|---|-------|-----------|------------------------|
| 1 | 🍽️ | Alimentación | mercado, restaurante, Éxito, D1... |
| 2 | 🚗 | Transporte | Uber, gasolina, Transmilenio... |
| 3 | 🎬 | Entretenimiento | Netflix, cine, Spotify... |
| 4 | ✈️ | Viajes | Avianca, Booking, hoteles... |
| 5 | 💊 | Salud | farmacia, gimnasio, médico... |
| 6 | 📚 | Educación | cursos, libros, certificaciones... |
| 7 | 💻 | Tecnología | software, apps, dominios... |
| 8 | 🏠 | Gastos Fijos | arriendo, servicios, internet... |
| 9 | 💰 | Ingresos | salario, freelance, abonos... |
| 10 | 🏦 | Ahorro | fondos, emergencia... |
| 11 | 📈 | Inversiones | acciones, CDT, trading, cripto... |
| 12 | ⚪ | Sin categoría | Por clasificar |

---

## 📈 Reportes y Dashboard

### Ver reporte mensual
```bash
python3 ~/clawd/tools/finance/finance-tracker.py report
```

### Exportar a Google Sheets
```bash
python3 ~/clawd/tools/finance/gsheet_sync.py
```

Luego importar el CSV generado en Google Sheets.

---

## 🔧 Modo Automático (Cuando Gmail funcione)

### Revisar cada hora
```bash
# Agregar a crontab
crontab -e

# Añadir línea:
0 * * * * python3 ~/clawd/tools/finance/gmail_connector.py --hours 1
```

### Modo daemon (revisa cada 5 min)
```bash
python3 ~/clawd/tools/finance/gmail_connector.py --daemon
```

---

## 📋 Próximos Pasos

### Inmediato
1. [ ] Decidir: ¿Configurar Gmail o usar Telegram por ahora?
2. [ ] Si Gmail: Generar App Password y actualizar script
3. [ ] Si Telegram: Probar primera transacción

### Esta semana
4. [ ] Crear hoja de Google Sheets
5. [ ] Importar primer CSV
6. [ ] Configurar dashboard con gráficos

### Mensual
7. [ ] Revisar reporte de gastos por categoría
8. [ ] Ajustar presupuestos
9. [ ] Identificar áreas de ahorro

---

## 💡 Ejemplo de Flujo Completo

### 1. Llega compra (Nu)
Tú recibes notificación en app Nu

### 2. Me notificas por Telegram
```
Nu: $87,500 en Rappi
```

### 3. Yo proceso
```
✅ Detectado:
   💰 $87,500
   🏪 Rappi
   🏦 Nu
   🏷️  Sugerido: alimentacion

¿Categoría correcta?
```

### 4. Tú confirmas
```
1 domicilio cena
```

### 5. Guardado
```json
{
  "date": "2025-01-31T17:30:00",
  "amount": 87500,
  "merchant": "Rappi",
  "bank_source": "Nu",
  "category": "alimentacion",
  "notes": "domicilio cena",
  "type": "gasto"
}
```

### 6. Al mes
Exportas a Sheets y ves:
- Total gastado en alimentación: $X
- % del presupuesto usado
- Tendencias vs mes anterior

---

## 🎯 Resumen

**¿Qué funciona ahora?** ✅ Telegram manual
**¿Qué necesita configuración?** ⚠️ Gmail automático
**¿Cuánto tiempo lleva configurar Gmail?** ~5 minutos
**¿Vale la pena?** Sí, si recibes muchos emails de bancos

**Mi recomendación:** 
- Empezar con Telegram ahora
- Configurar Gmail cuando tengas 5 minutos
- Combinar ambos (Gmail para Bancolombia/Davivienda, Telegram para Nu)

¿Por dónde empezamos? 🦊
