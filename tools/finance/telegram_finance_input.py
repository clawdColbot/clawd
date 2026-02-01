#!/usr/bin/env python3
"""
telegram_finance_input.py - Ingreso manual de transacciones via Telegram
Cuando no funciona Gmail o para bancos sin email (Nu)
"""

import sys
import json
from datetime import datetime
from pathlib import Path

def parse_telegram_message(message: str) -> dict:
    """
    Parsear mensaje de Telegram con formato de transacción
    
    Formatos soportados:
    - "Nu: $50,000 en Uber"
    - "Bancolombia: Compra $150,000 en Éxito"
    - "$45,000 restaurante - tarjeta visa"
    """
    
    message_lower = message.lower()
    
    # Detectar banco/fuente
    bank = "Otro"
    if "nu" in message_lower or "nubank" in message_lower:
        bank = "Nu"
    elif "bancolombia" in message_lower:
        bank = "Bancolombia"
    elif "davivienda" in message_lower or "davi" in message_lower:
        bank = "Davivienda"
    
    # Extraer monto
    import re
    amount = None
    patterns = [
        r'\$([\d,\.]+)',
        r'([\d,\.]+)\s*(?:cop|pesos)',
    ]
    
    for pattern in patterns:
        match = re.search(pattern, message, re.IGNORECASE)
        if match:
            amount_str = match.group(1).replace(',', '').replace('.', '')
            try:
                amount = float(amount_str)
                if amount > 1000000:
                    amount = amount / 100
            except:
                pass
            break
    
    # Extraer comercio/descripción
    # Después del monto, buscar "en [comercio]"
    merchant = "Desconocido"
    merchant_patterns = [
        r'(?:en|en\s+el|en\s+la)\s+([^\.,\-]+)',
        r'(?:compra|pago)\s+(?:de\s+)?\$?[^\s]+\s+(?:en\s+)?([^\.,\-]+)',
    ]
    
    for pattern in merchant_patterns:
        match = re.search(pattern, message, re.IGNORECASE)
        if match:
            merchant = match.group(1).strip()
            break
    
    # Detectar tipo
    is_income = any(word in message_lower for word in ["recibido", "abono", "ingreso", "devolución"])
    transaction_type = "ingreso" if is_income else "gasto"
    
    return {
        "date": datetime.now().isoformat(),
        "source": "Telegram",
        "bank_source": bank,
        "amount": amount,
        "type": transaction_type,
        "merchant": merchant,
        "original_message": message,
        "category": None,
        "notes": "",
        "confirmed": False
    }

def add_transaction_from_telegram(message: str):
    """Procesar mensaje de Telegram y agregar transacción"""
    
    print("="*60)
    print("📱 PROCESANDO MENSAJE DE TELEGRAM")
    print("="*60)
    print(f"💬 Mensaje: {message}")
    print("")
    
    # Parsear
    transaction = parse_telegram_message(message)
    
    if not transaction["amount"]:
        print("❌ No se pudo detectar monto en el mensaje")
        print("💡 Formatos válidos:")
        print('  "Nu: $50,000 en Uber"')
        print('  "Bancolombia: Compra $150,000 en Éxito"')
        return None
    
    # Cargar tracker
    sys.path.insert(0, str(Path.home() / "clawd" / "tools" / "finance"))
    from finance_tracker import PersonalFinanceTracker
    
    tracker = PersonalFinanceTracker()
    
    # Sugerir categoría
    transaction["suggested_category"] = tracker.suggest_category(transaction)
    
    # Guardar
    transaction = tracker.add_transaction(transaction)
    
    # Mostrar
    print(f"✅ Transacción detectada:")
    print(f"   💰 Monto: ${transaction['amount']:,.0f}")
    print(f"   🏪 Comercio: {transaction['merchant']}")
    print(f"   🏦 Banco: {transaction['bank_source']}")
    print(f"   📝 Tipo: {transaction['type']}")
    print(f"   🏷️  Sugerido: {transaction['suggested_category']}")
    print("")
    print("¿Qué categoría es correcta?")
    print("1. 🍽️ Alimentación")
    print("2. 🚗 Transporte")
    print("3. 🎬 Entretenimiento")
    print("4. ✈️ Viajes")
    print("5. 💊 Salud")
    print("6. 📚 Educación")
    print("7. 💻 Tecnología")
    print("8. 🏠 Gastos Fijos")
    print("9. 💰 Ingresos")
    print("10. 🏦 Ahorro")
    print("11. 📈 Inversiones")
    print("12. ⚪ Sin categoría")
    
    return transaction

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser()
    parser.add_argument("message", help="Mensaje de Telegram con la transacción")
    
    args = parser.parse_args()
    
    add_transaction_from_telegram(args.message)
