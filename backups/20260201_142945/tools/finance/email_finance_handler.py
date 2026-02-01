#!/usr/bin/env python3
"""
email_finance_handler.py - Procesador de emails para finanzas
Integración con sistema de email de Clawdbot
"""

import sys
import json
from pathlib import Path

# Agregar path al finance tracker
sys.path.insert(0, str(Path.home() / "clawd" / "tools" / "finance"))
from finance_tracker import PersonalFinanceTracker, process_email, confirm_last_transaction

def handle_new_email(subject: str, body: str, sender: str, email_id: str = None):
    """
    Procesar email nuevo y detectar si es transacción financiera
    
    Uso: python3 email_finance_handler.py "Asunto" "Cuerpo" "remitente@email.com"
    """
    
    # Palabras clave que indican transacción financiera
    finance_keywords = [
        "compra", "pago", "transacción", "transaccion", "recibo", "factura",
        "recibido", "depositado", "transferencia", "abono", "cargo", "debito",
        "débito", "retiro", "pago aprobado", "compra aprobada",
        "successful payment", "purchase", "transaction", "receipt", "invoice",
        "payment received", "deposit", "transfer", "charge", "withdrawal"
    ]
    
    # Detectar si es email financiero
    text = (subject + " " + body).lower()
    is_financial = any(keyword in text for keyword in finance_keywords)
    
    if not is_financial:
        print(f"⏭️  Email no financiero ignorado: {subject[:50]}...")
        return None
    
    print("="*60)
    print("💰 EMAIL FINANCIERO DETECTADO")
    print("="*60)
    print(f"📧 Asunto: {subject}")
    print(f"📤 Remitente: {sender}")
    print("")
    
    # Procesar con finance tracker
    tracker = PersonalFinanceTracker()
    transaction = tracker.parse_email_content(subject, body, sender)
    
    if not transaction or not transaction.get("amount"):
        print("⚠️  No se pudo detectar monto en el email")
        print("¿Deseas agregar manualmente? (s/n)")
        return None
    
    # Guardar transacción
    transaction = tracker.add_transaction(transaction)
    
    # Mostrar para confirmación
    print(f"💵 Monto detectado: ${transaction['amount']:,.0f}")
    print(f"🏪 Comercio: {transaction['merchant']}")
    print(f"📝 Tipo: {transaction['type']}")
    print(f"🏷️  Categoría sugerida: {transaction.get('suggested_category', 'sin_categoria')}")
    print("")
    print("="*60)
    print("¿Qué categoría es correcta?")
    print("="*60)
    
    categories = [
        ("1", "alimentacion", "🍽️  Alimentación"),
        ("2", "transporte", "🚗 Transporte"),
        ("3", "entretenimiento", "🎬 Entretenimiento"),
        ("4", "salud", "💊 Salud"),
        ("5", "educacion", "📚 Educación"),
        ("6", "tecnologia", "💻 Tecnología"),
        ("7", "gastos_fijos", "🏠 Gastos Fijos"),
        ("8", "ingresos", "💰 Ingresos"),
        ("9", "ahorro", "🏦 Ahorro"),
        ("10", "sin_categoria", "⚪ Sin categoría"),
    ]
    
    for num, cat, emoji in categories:
        marker = " ← Sugerido" if cat == transaction.get('suggested_category') else ""
        print(f"{num}. {emoji}{marker}")
    
    print("")
    print("💡 Responde con el número + nota opcional")
    print("   Ejemplo: '1 compra del mercado semanal'")
    print("="*60)
    
    return transaction

def confirm_transaction_by_number(choice: str, note: str = ""):
    """
    Confirmar transacción por número de categoría
    
    Uso: python3 email_finance_handler.py confirm 1 "nota opcional"
    """
    
    categories_map = {
        "1": "alimentacion",
        "2": "transporte",
        "3": "entretenimiento",
        "4": "viajes",
        "5": "salud",
        "6": "educacion",
        "7": "tecnologia",
        "8": "gastos_fijos",
        "9": "ingresos",
        "10": "ahorro",
        "11": "inversiones",
        "12": "sin_categoria",
    }
    
    category = categories_map.get(choice)
    if not category:
        print(f"❌ Opción inválida: {choice}")
        return False
    
    confirm_last_transaction(category, note)
    
    # Mostrar resumen actualizado
    tracker = PersonalFinanceTracker()
    print("\n" + tracker.generate_report())
    
    return True

def show_pending():
    """Mostrar transacciones pendientes"""
    tracker = PersonalFinanceTracker()
    pending = tracker.get_pending_transactions()
    
    if not pending:
        print("✅ No hay transacciones pendientes")
        return
    
    print(f"⏳ {len(pending)} transacciones pendientes:")
    print("="*60)
    
    for i, t in enumerate(pending, 1):
        print(f"{i}. {t['merchant']}: ${t['amount']:,.0f}")
        print(f"   Sugerido: {t.get('suggested_category', 'sin_categoria')}")
        print(f"   Fecha: {t['date'][:10]}")
        print()

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Email Finance Handler')
    parser.add_argument('action', choices=['process', 'confirm', 'pending', 'report'])
    parser.add_argument('subject', nargs='?', help='Email subject')
    parser.add_argument('body', nargs='?', help='Email body')
    parser.add_argument('sender', nargs='?', help='Email sender')
    parser.add_argument('--category', '-c', help='Category number for confirm')
    parser.add_argument('--note', '-n', help='Note for confirmation')
    
    args = parser.parse_args()
    
    if args.action == "process":
        if not all([args.subject, args.sender]):
            print("❌ Faltan argumentos: subject y sender son requeridos")
            sys.exit(1)
        handle_new_email(args.subject, args.body or "", args.sender)
    
    elif args.action == "confirm":
        if not args.category:
            print("❌ Se requiere --category")
            sys.exit(1)
        confirm_transaction_by_number(args.category, args.note or "")
    
    elif args.action == "pending":
        show_pending()
    
    elif args.action == "report":
        tracker = PersonalFinanceTracker()
        print(tracker.generate_report())
