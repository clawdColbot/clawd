#!/usr/bin/env python3
"""
gsheet_sync.py - Sincronización con Google Sheets
Exporta transacciones a Google Sheets para dashboard visual
"""

import json
import os
from datetime import datetime
from pathlib import Path

def export_to_csv_for_sheets():
    """Exportar a CSV que puede importarse fácilmente a Google Sheets"""
    
    finance_dir = Path.home() / "clawd" / "finance"
    data_file = finance_dir / "transactions.json"
    
    if not data_file.exists():
        print("No hay datos de transacciones")
        return
    
    with open(data_file, 'r', encoding='utf-8') as f:
        transactions = json.load(f)
    
    # Organizar por meses
    by_month = {}
    for t in transactions:
        if not t.get("confirmed"):
            continue
        
        date = datetime.fromisoformat(t["date"])
        month_key = f"{date.year}_{date.month:02d}"
        
        if month_key not in by_month:
            by_month[month_key] = []
        
        by_month[month_key].append(t)
    
    # Generar CSV para cada mes
    for month_key, trans in by_month.items():
        csv_file = finance_dir / f"finanzas_{month_key}.csv"
        
        with open(csv_file, 'w', encoding='utf-8') as f:
            # Header
            f.write("Fecha,Hora,Descripción,Categoría,Tipo,Monto,Notas\n")
            
            # Datos
            for t in sorted(trans, key=lambda x: x["date"]):
                date = datetime.fromisoformat(t["date"])
                f.write(f"{date.strftime('%Y-%m-%d')},{date.strftime('%H:%M')},")
                f.write(f"\"{t.get('merchant', 'Desconocido')}\",")
                f.write(f"{t.get('category', 'Sin categoría')},")
                f.write(f"{'Ingreso' if t['type'] == 'ingreso' else 'Gasto'},")
                f.write(f"{t.get('amount', 0)},")
                f.write(f"\"{t.get('notes', '')}\"\n")
        
        print(f"📊 CSV generado: {csv_file}")
    
    # Generar resumen anual
    yearly_summary = {}
    for t in transactions:
        if not t.get("confirmed"):
            continue
        
        date = datetime.fromisoformat(t["date"])
        year = date.year
        
        if year not in yearly_summary:
            yearly_summary[year] = {"ingresos": 0, "gastos": 0, "meses": {}}
        
        month = date.month
        if month not in yearly_summary[year]["meses"]:
            yearly_summary[year]["meses"][month] = {"ingresos": 0, "gastos": 0}
        
        if t["type"] == "ingreso":
            yearly_summary[year]["ingresos"] += t["amount"]
            yearly_summary[year]["meses"][month]["ingresos"] += t["amount"]
        else:
            yearly_summary[year]["gastos"] += t["amount"]
            yearly_summary[year]["meses"][month]["gastos"] += t["amount"]
    
    # Exportar resumen
    summary_file = finance_dir / "resumen_anual.csv"
    with open(summary_file, 'w', encoding='utf-8') as f:
        f.write("Año,Mes,Ingresos,Gastos,Balance\n")
        for year, data in sorted(yearly_summary.items()):
            for month, mdata in sorted(data["meses"].items()):
                balance = mdata["ingresos"] - mdata["gastos"]
                f.write(f"{year},{month},{mdata['ingresos']},{mdata['gastos']},{balance}\n")
    
    print(f"📈 Resumen anual: {summary_file}")
    print("\n💡 Para importar a Google Sheets:")
    print("1. Ve a sheets.google.com")
    print("2. Crea nueva hoja")
    print("3. Archivo → Importar → Subir CSV")
    print("4. Selecciona el archivo generado")
    
    return finance_dir

def create_gsheet_template():
    """Crear plantilla de Google Sheets con fórmulas"""
    
    template = """
PLANTILLA GOOGLE SHEETS - FINANZAS PERSONALES
==============================================

HOJA 1: Transacciones (Importar CSV aquí)
------------------------------------------
Columnas:
A: Fecha
B: Hora
C: Descripción
D: Categoría
E: Tipo (Ingreso/Gasto)
F: Monto
G: Notas

HOJA 2: Dashboard Mensual
--------------------------
Fórmulas sugeridas:

Total Ingresos:
=SUMIF('Transacciones'!E:E,"Ingreso",'Transacciones'!F:F)

Total Gastos:
=SUMIF('Transacciones'!E:E,"Gasto",'Transacciones'!F:F)

Por Categoría:
=SUMIF('Transacciones'!D:D,"alimentacion",'Transacciones'!F:F)

Gráfico recomendado:
- Tipo: Gráfico circular
- Datos: Categorías vs Monto

HOJA 3: Comparación Mensual
----------------------------
Crear tabla con columnas:
Mes | Ingresos | Gastos | Balance | % Ahorro

"""
    
    finance_dir = Path.home() / "clawd" / "finance"
    template_file = finance_dir / "GSHEET_TEMPLATE.txt"
    
    with open(template_file, 'w', encoding='utf-8') as f:
        f.write(template)
    
    print(f"📋 Plantilla guardada: {template_file}")

if __name__ == "__main__":
    print("📊 Exportando datos para Google Sheets...\n")
    export_to_csv_for_sheets()
    print("\n" + "="*50)
    create_gsheet_template()
