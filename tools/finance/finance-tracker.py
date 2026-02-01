#!/usr/bin/env python3
"""
finance-tracker.py - Sistema de seguimiento de finanzas personales
Procesa emails, categoriza gastos/ingresos, exporta a Google Sheets
"""

import json
import os
import re
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

class PersonalFinanceTracker:
    """Tracker de finanzas personales"""
    
    def __init__(self):
        self.finance_dir = Path.home() / "clawd" / "finance"
        self.finance_dir.mkdir(parents=True, exist_ok=True)
        
        self.data_file = self.finance_dir / "transactions.json"
        self.categories_file = self.finance_dir / "categories.json"
        
        self.transactions = self.load_transactions()
        self.categories = self.load_categories()
        
    def load_transactions(self) -> List[Dict]:
        """Cargar transacciones históricas"""
        if self.data_file.exists():
            with open(self.data_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        return []
    
    def load_categories(self) -> Dict:
        """Cargar categorías de gastos"""
        default_categories = {
            "gastos_fijos": {
                "color": "🔴",
                "items": ["arriendo", "servicios", "internet", "telefonia", "seguros"]
            },
            "alimentacion": {
                "color": "🟡",
                "items": ["mercado", "restaurante", "domicilios", "cafe"]
            },
            "transporte": {
                "color": "🔵",
                "items": ["gasolina", "transporte_publico", "uber", "taxi", "parqueadero"]
            },
            "entretenimiento": {
                "color": "🟣",
                "items": ["streaming", "cine", "eventos", "hobbies", "libros"]
            },
            "viajes": {
                "color": "✈️",
                "items": ["vuelos", "hoteles", "transporte_viaje", "tours", "comidas_viaje", "seguro_viaje", "equipaje", "experiencias"]
            },
            "salud": {
                "color": "🟢",
                "items": ["medicamentos", "consultas", "gimnasio", "terapias"]
            },
            "educacion": {
                "color": "🟠",
                "items": ["cursos", "libros_edu", "certificaciones", "material"]
            },
            "tecnologia": {
                "color": "⚪",
                "items": ["software", "hardware", "suscripciones_tech", "dominios"]
            },
            "ingresos": {
                "color": "💰",
                "items": ["salario", "freelance", "inversiones", "regalos", "otros_ingresos"]
            },
            "ahorro": {
                "color": "🏦",
                "items": ["ahorro_emergencia", "fondos"]
            },
            "inversiones": {
                "color": "📈",
                "items": ["acciones", "cdt", "fic", "bonos", "cripto", "trading", "dividendos", "plusvalias"]
            },
            "sin_categoria": {
                "color": "⚫",
                "items": []
            }
        }
        
        if self.categories_file.exists():
            with open(self.categories_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        
        # Guardar categorías por defecto
        self.save_categories(default_categories)
        return default_categories
    
    def save_categories(self, categories: Dict):
        """Guardar categorías"""
        with open(self.categories_file, 'w', encoding='utf-8') as f:
            json.dump(categories, f, indent=2, ensure_ascii=False)
    
    def save_transactions(self):
        """Guardar transacciones"""
        with open(self.data_file, 'w', encoding='utf-8') as f:
            json.dump(self.transactions, f, indent=2, ensure_ascii=False, default=str)
    
    def parse_email_content(self, subject: str, body: str, sender: str) -> Optional[Dict]:
        """Extraer información de transacción desde email"""
        
        # Detectar fuente del email (banco específico)
        sender_lower = sender.lower()
        is_bancolombia = "bancolombia" in sender_lower or "alertas y notificaciones" in subject.lower()
        is_davivienda = "davibank" in sender_lower or "davivienda" in sender_lower
        
        # Patrones específicos por banco
        if is_bancolombia:
            # Bancolombia: "Compraste en [comercio] por $[monto]"
            amount_patterns = [
                r'por\s*\$?([\d,\.]+)',
                r'\$([\d,]+\.?\d*)',
                r'COP\s*([\d,\.]+)',
            ]
            merchant_patterns = [
                r'(?:Compraste|Transferiste)\s+en\s+([^\.,]+)',
                r'en\s+([A-Za-z\s]+?)(?:\s+por|\s*\.)',
            ]
        elif is_davivienda:
            # Davivienda - Tarjetas Visa/Amex
            amount_patterns = [
                r'\$([\d,]+\.?\d*)',
                r'por\s*\$?([\d,\.]+)',
                r'total.*?\$?([\d,\.]+)',
            ]
            merchant_patterns = [
                r'compra.*?en\s+([^\.,]+)',
                r'establecimiento[\s:]+([^\.,]+)',
                r'en\s+([A-Za-z\s]+?)(?:\s+por|\s*\.)',
            ]
        else:
            # Patrones genéricos
            amount_patterns = [
                r'\$([\d,]+\.?\d*)',
                r'COP\s*([\d,\.]+)',
                r'([\d,]+\.?\d*)\s*COP',
                r'por\s*\$?([\d,\.]+)',
                r'valor.*?\$?([\d,\.]+)',
                r'total.*?\$?([\d,\.]+)',
                r'amount.*?\$?([\d,\.]+)',
            ]
            merchant_patterns = [
                r'en\s+([A-Za-z\s]+?)(?:\.|,|$)',
                r'compra\s+en\s+([A-Za-z\s]+)',
                r'a\s+favor\s+de\s+([A-Za-z\s]+)',
                r'de\s+([A-Za-z\s]+?)(?:\s+por|$)',
            ]
        
        amount = None
        for pattern in amount_patterns:
            match = re.search(pattern, subject + " " + body, re.IGNORECASE)
            if match:
                amount_str = match.group(1).replace(',', '').replace('.', '')
                try:
                    amount = float(amount_str)
                    if amount > 1000000:  # Probablemente sin decimal
                        amount = amount / 100
                    break
                except:
                    continue
        
        # Detectar si es gasto o ingreso
        text_lower = (subject + " " + body).lower()
        
        if is_bancolombia:
            # Bancolombia específico
            is_income = any(word in text_lower for word in [
                "transferencia recibida", "abono", "consignación", "devolución"
            ])
            is_expense = any(word in text_lower for word in [
                "compraste", "transferiste", "retiro", "pago"
            ])
        elif is_davivienda:
            # Davivienda específico
            is_income = "abono" in text_lower or "pago recibido" in text_lower
            is_expense = "compra" in text_lower or "transacción" in text_lower
        else:
            # Genérico
            is_income = any(word in text_lower for word in [
                "recibido", "depositado", "ingreso", "pago recibido", "salario", "abono",
                "transferencia recibida", "devolución", "cashback", "reembolso"
            ])
            is_expense = any(word in text_lower for word in [
                "compra", "pago", "transacción", "retiro", "débito", "cargo",
                "factura", "recibo", "orden", "payment"
            ])
        
        transaction_type = "ingreso" if is_income else "gasto" if is_expense else "desconocido"
        
        # Extraer comercio/destinatario
        merchant = "Desconocido"
        for pattern in merchant_patterns:
            match = re.search(pattern, subject + " " + body, re.IGNORECASE)
            if match:
                merchant = match.group(1).strip()
                break
        
        # Agregar metadata de la fuente
        bank_source = "Bancolombia" if is_bancolombia else "Davivienda" if is_davivienda else "Otro"
        
        return {
            "date": datetime.now().isoformat(),
            "subject": subject,
            "sender": sender,
            "bank_source": bank_source,
            "amount": amount,
            "type": transaction_type,
            "merchant": merchant,
            "category": None,
            "notes": "",
            "confirmed": False
        }
    
    def suggest_category(self, transaction: Dict) -> str:
        """Sugerir categoría basada en comercio/descripción"""
        
        text = (transaction.get("subject", "") + " " + 
                transaction.get("merchant", "")).lower()
        
        # Keywords por categoría
        keywords = {
            "alimentacion": ["mercado", "super", "restaurante", "domicilio", "uber eats", "rappi", "ifood", "cafe", "panaderia", "d1", "exito", "carulla", "jumbo"],
            "transporte": ["uber", "taxi", "gasolina", "terpel", "texaco", "brilla", "transmilenio", "metro", "bus", "parqueadero", "peaje"],
            "entretenimiento": ["netflix", "spotify", "youtube", "prime", "disney", "hbo", "cine", "cinemark", "procinal", "evento", "concierto"],
            "viajes": ["vuelo", "avianca", "latam", "wingo", "despegar", "booking", "airbnb", "hotel", "hostal", "tour", "aguila", "bolivariano", "aventura", "paquete viaje"],
            "tecnologia": ["google", "apple", "microsoft", "github", "aws", "hosting", "dominio", "software", "app"],
            "inversiones": ["acciones", "cdt", "fic", "fondo inversion", "bolsa", "dividendo", "plusvalia", "intereses", "rendimiento", "nvda", "appl", "btc", "eth", "trading"],
            "salud": ["farmacia", "drogueria", "medicamento", "consulta", "doctor", "gimnasio", "smartfit", "bodytech"],
            "servicios": ["arriendo", "administracion", "acueducto", "gas", "luz", "energia", "internet", "claro", "movistar", "tigo"],
        }
        
        for category, words in keywords.items():
            if any(word in text for word in words):
                return category
        
        return "sin_categoria"
    
    def add_transaction(self, transaction: Dict) -> Dict:
        """Añadir nueva transacción"""
        
        # Sugerir categoría
        if not transaction.get("category"):
            transaction["suggested_category"] = self.suggest_category(transaction)
        
        self.transactions.append(transaction)
        self.save_transactions()
        
        return transaction
    
    def confirm_transaction(self, idx: int, category: str, notes: str = ""):
        """Confirmar y categorizar transacción"""
        
        if 0 <= idx < len(self.transactions):
            self.transactions[idx]["category"] = category
            self.transactions[idx]["notes"] = notes
            self.transactions[idx]["confirmed"] = True
            self.save_transactions()
            return True
        return False
    
    def get_pending_transactions(self) -> List[Dict]:
        """Obtener transacciones pendientes de confirmación"""
        return [t for t in self.transactions if not t.get("confirmed", False)]
    
    def get_monthly_summary(self, year: int, month: int) -> Dict:
        """Resumen mensual"""
        
        monthly = [t for t in self.transactions 
                   if datetime.fromisoformat(t["date"]).year == year 
                   and datetime.fromisoformat(t["date"]).month == month]
        
        summary = {
            "total_gastos": sum(t["amount"] for t in monthly if t["type"] == "gasto" and t.get("confirmed")),
            "total_ingresos": sum(t["amount"] for t in monthly if t["type"] == "ingreso" and t.get("confirmed")),
            "por_categoria": {},
            "por_categoria_count": {},
            "pendientes": len([t for t in monthly if not t.get("confirmed")])
        }
        
        for t in monthly:
            if t.get("confirmed"):
                cat = t.get("category", "sin_categoria")
                if cat not in summary["por_categoria"]:
                    summary["por_categoria"][cat] = 0
                    summary["por_categoria_count"][cat] = 0
                summary["por_categoria"][cat] += t["amount"]
                summary["por_categoria_count"][cat] += 1
        
        return summary
    
    def export_to_gsheet_format(self, output_file: Optional[str] = None):
        """Exportar formato compatible con Google Sheets"""
        
        output = output_file or self.finance_dir / "export_gsheet.json"
        
        # Organizar por meses
        by_month = {}
        for t in self.transactions:
            if not t.get("confirmed"):
                continue
            
            date = datetime.fromisoformat(t["date"])
            month_key = f"{date.year}-{date.month:02d}"
            
            if month_key not in by_month:
                by_month[month_key] = []
            
            by_month[month_key].append({
                "Fecha": date.strftime("%Y-%m-%d"),
                "Hora": date.strftime("%H:%M"),
                "Descripción": t.get("merchant", "Desconocido"),
                "Categoría": t.get("category", "Sin categoría"),
                "Tipo": "Ingreso" if t["type"] == "ingreso" else "Gasto",
                "Monto": t.get("amount", 0),
                "Notas": t.get("notes", ""),
                "Fuente": t.get("sender", "Email")
            })
        
        with open(output, 'w', encoding='utf-8') as f:
            json.dump(by_month, f, indent=2, ensure_ascii=False)
        
        return output
    
    def generate_report(self, month: Optional[int] = None, year: Optional[int] = None):
        """Generar reporte mensual"""
        
        now = datetime.now()
        year = year or now.year
        month = month or now.month
        
        summary = self.get_monthly_summary(year, month)
        
        report = []
        report.append(f"📊 RESUMEN FINANCIERO - {year}-{month:02d}")
        report.append("=" * 50)
        report.append(f"💰 Total Ingresos: ${summary['total_ingresos']:,.0f}")
        report.append(f"💸 Total Gastos: ${summary['total_gastos']:,.0f}")
        report.append(f"📈 Balance: ${summary['total_ingresos'] - summary['total_gastos']:,.0f}")
        report.append(f"⏳ Transacciones pendientes: {summary['pendientes']}")
        report.append("")
        report.append("📋 Por Categoría:")
        
        for cat, amount in sorted(summary["por_categoria"].items(), key=lambda x: x[1], reverse=True):
            count = summary["por_categoria_count"][cat]
            emoji = self.categories.get(cat, {}).get("color", "⚪")
            report.append(f"   {emoji} {cat}: ${amount:,.0f} ({count} trans.)")
        
        return "\n".join(report)

# Funciones de conveniencia para uso directo
def process_email(subject: str, body: str, sender: str) -> Dict:
    """Procesar un email y devolver transacción sugerida"""
    tracker = PersonalFinanceTracker()
    transaction = tracker.parse_email_content(subject, body, sender)
    
    if transaction and transaction["amount"]:
        transaction = tracker.add_transaction(transaction)
        
        print(f"📧 Email detectado: {subject[:50]}...")
        print(f"💰 Monto: ${transaction['amount']:,.0f}")
        print(f"🏪 Comercio: {transaction['merchant']}")
        print(f"📝 Tipo: {transaction['type']}")
        print(f"🏷️  Categoría sugerida: {transaction.get('suggested_category', 'sin_categoria')}")
        print("")
        print("¿Qué categoría es correcta?")
        print("1. alimentacion")
        print("2. transporte")
        print("3. entretenimiento")
        print("4. viajes")
        print("5. salud")
        print("6. educacion")
        print("7. tecnologia")
        print("8. gastos_fijos")
        print("9. ingresos")
        print("10. ahorro")
        print("11. inversiones")
        print("12. sin_categoria")
        
    return transaction

def confirm_last_transaction(category: str, notes: str = ""):
    """Confirmar última transacción"""
    tracker = PersonalFinanceTracker()
    pending = tracker.get_pending_transactions()
    
    if pending:
        last_idx = len(tracker.transactions) - 1
        tracker.confirm_transaction(last_idx, category, notes)
        print(f"✅ Transacción confirmada: {category}")
    else:
        print("No hay transacciones pendientes")

def show_monthly_report(month: int = None, year: int = None):
    """Mostrar reporte mensual"""
    tracker = PersonalFinanceTracker()
    print(tracker.generate_report(month, year))

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["report", "pending", "export"])
    parser.add_argument("--month", type=int)
    parser.add_argument("--year", type=int)
    
    args = parser.parse_args()
    
    tracker = PersonalFinanceTracker()
    
    if args.command == "report":
        print(tracker.generate_report(args.month, args.year))
    elif args.command == "pending":
        pending = tracker.get_pending_transactions()
        print(f"⏳ {len(pending)} transacciones pendientes")
        for i, t in enumerate(pending[-5:], 1):
            print(f"{i}. {t['merchant']}: ${t['amount']:,.0f} ({t.get('suggested_category', '?')})")
    elif args.command == "export":
        output = tracker.export_to_gsheet_format()
        print(f"✅ Exportado a: {output}")
