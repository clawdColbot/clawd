#!/usr/bin/env python3
"""
gmail_connector.py - Conector IMAP para Gmail
Lee emails de Bancolombia, Davivienda y los procesa para finanzas
"""

import imaplib
import email
import sys
import json
import os
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Dict, Optional

# Configuración
GMAIL_USER = "clawdcol@gmail.com"
GMAIL_PASS = "HpAHs2upg6kP2x8skAR7"
IMAP_SERVER = "imap.gmail.com"

# Remitentes de bancos a monitorear
BANK_SENDERS = [
    "alertas@bancolombia.com",
    "DAVIbankInforma@davibank.com",
    "notificaciones@bancolombia.com",
    "bancolombia@bancolombia.com",
]

class GmailFinanceConnector:
    """Conector Gmail para procesar emails bancarios"""
    
    def __init__(self):
        self.finance_dir = Path.home() / "clawd" / "finance"
        self.finance_dir.mkdir(parents=True, exist_ok=True)
        
        self.processed_file = self.finance_dir / "processed_emails.json"
        self.processed_ids = self.load_processed_ids()
        
    def load_processed_ids(self) -> List[str]:
        """Cargar IDs de emails ya procesados"""
        if self.processed_file.exists():
            with open(self.processed_file, 'r') as f:
                data = json.load(f)
                return data.get("ids", [])
        return []
    
    def save_processed_id(self, email_id: str):
        """Guardar ID de email procesado"""
        if email_id not in self.processed_ids:
            self.processed_ids.append(email_id)
            with open(self.processed_file, 'w') as f:
                json.dump({"ids": self.processed_ids, "last_update": datetime.now().isoformat()}, f)
    
    def connect(self) -> Optional[imaplib.IMAP4_SSL]:
        """Conectar a Gmail IMAP"""
        try:
            print("🔌 Conectando a Gmail...")
            mail = imaplib.IMAP4_SSL(IMAP_SERVER)
            mail.login(GMAIL_USER, GMAIL_PASS)
            print("✅ Conectado a Gmail")
            return mail
        except Exception as e:
            print(f"❌ Error conectando: {e}")
            return None
    
    def fetch_bank_emails(self, mail: imaplib.IMAP4_SSL, hours: int = 24) -> List[Dict]:
        """Obtener emails de bancos de las últimas N horas"""
        
        emails = []
        
        try:
            # Seleccionar inbox
            mail.select('inbox')
            
            # Buscar emails de bancos
            for sender in BANK_SENDERS:
                print(f"\n🔍 Buscando emails de: {sender}")
                
                # Buscar por remitente y fecha
                since_date = (datetime.now() - timedelta(hours=hours)).strftime("%d-%b-%Y")
                search_criteria = f'(FROM "{sender}" SINCE "{since_date}")'
                
                status, messages = mail.search(None, search_criteria)
                
                if status != 'OK':
                    continue
                
                message_ids = messages[0].split()
                print(f"   Encontrados: {len(message_ids)} emails")
                
                for msg_id in message_ids:
                    msg_id_str = msg_id.decode()
                    
                    # Saltar si ya fue procesado
                    if msg_id_str in self.processed_ids:
                        continue
                    
                    # Obtener email
                    status, msg_data = mail.fetch(msg_id, '(RFC822)')
                    
                    if status != 'OK':
                        continue
                    
                    # Parsear email
                    raw_email = msg_data[0][1]
                    email_message = email.message_from_bytes(raw_email)
                    
                    # Extraer información
                    subject = self.decode_header(email_message['Subject'])
                    from_addr = email_message['From']
                    date = email_message['Date']
                    
                    # Extraer cuerpo
                    body = self.get_email_body(email_message)
                    
                    emails.append({
                        'id': msg_id_str,
                        'subject': subject,
                        'from': from_addr,
                        'date': date,
                        'body': body
                    })
        
        except Exception as e:
            print(f"❌ Error buscando emails: {e}")
        
        return emails
    
    def decode_header(self, header: str) -> str:
        """Decodificar header de email"""
        if not header:
            return ""
        
        decoded_parts = email.header.decode_header(header)
        decoded_string = ""
        
        for part, charset in decoded_parts:
            if isinstance(part, bytes):
                decoded_string += part.decode(charset or 'utf-8', errors='ignore')
            else:
                decoded_string += part
        
        return decoded_string
    
    def get_email_body(self, email_message) -> str:
        """Extraer cuerpo del email"""
        body = ""
        
        if email_message.is_multipart():
            for part in email_message.walk():
                content_type = part.get_content_type()
                if content_type == "text/plain":
                    try:
                        body = part.get_payload(decode=True).decode('utf-8', errors='ignore')
                        break
                    except:
                        pass
                elif content_type == "text/html" and not body:
                    try:
                        html = part.get_payload(decode=True).decode('utf-8', errors='ignore')
                        # Simple HTML a texto
                        import re
                        body = re.sub('<[^<]+?>', '', html)
                    except:
                        pass
        else:
            try:
                body = email_message.get_payload(decode=True).decode('utf-8', errors='ignore')
            except:
                pass
        
        return body
    
    def process_finance_emails(self, emails: List[Dict]):
        """Procesar emails para el sistema de finanzas"""
        
        # Importar el finance handler
        sys.path.insert(0, str(Path.home() / "clawd" / "tools" / "finance"))
        from finance_tracker import PersonalFinanceTracker
        
        tracker = PersonalFinanceTracker()
        processed_count = 0
        
        for email_data in emails:
            print(f"\n📧 Procesando: {email_data['subject'][:50]}...")
            
            # Verificar si es email financiero
            subject_lower = email_data['subject'].lower()
            body_lower = email_data['body'].lower()
            
            is_financial = any(keyword in subject_lower or keyword in body_lower for keyword in [
                "compra", "pago", "transacción", "transferencia", "compraste", "transferiste",
                "alerta", "notificación", "retiro", "abono"
            ])
            
            if not is_financial:
                print("   ⏭️  No es email financiero, saltando")
                self.save_processed_id(email_data['id'])
                continue
            
            # Parsear transacción
            transaction = tracker.parse_email_content(
                email_data['subject'],
                email_data['body'],
                email_data['from']
            )
            
            if transaction and transaction.get("amount"):
                # Guardar transacción
                transaction = tracker.add_transaction(transaction)
                
                print(f"   💰 Monto: ${transaction['amount']:,.0f}")
                print(f"   🏪 Comercio: {transaction['merchant']}")
                print(f"   📝 Tipo: {transaction['type']}")
                print(f"   🏷️  Sugerido: {transaction.get('suggested_category', 'sin_categoria')}")
                print(f"   📊 Fuente: {transaction.get('bank_source', 'Otro')}")
                
                # Marcar como procesado
                self.save_processed_id(email_data['id'])
                processed_count += 1
            else:
                print("   ⚠️  No se pudo extraer monto")
                # Aún así marcar como procesado para no reintentar
                self.save_processed_id(email_data['id'])
        
        return processed_count
    
    def run(self, hours: int = 24):
        """Ejecutar ciclo completo"""
        print("="*60)
        print("📬 GMAIL FINANCE CONNECTOR")
        print("="*60)
        print(f"📧 Cuenta: {GMAIL_USER}")
        print(f"⏰ Buscando emails de últimas {hours} horas")
        print("="*60)
        
        # Conectar
        mail = self.connect()
        if not mail:
            return
        
        try:
            # Obtener emails
            emails = self.fetch_bank_emails(mail, hours)
            
            if not emails:
                print("\n📭 No hay nuevos emails de bancos")
                return
            
            print(f"\n📨 {len(emails)} emails nuevos para procesar")
            
            # Procesar
            processed = self.process_finance_emails(emails)
            
            print("\n" + "="*60)
            print(f"✅ Completado: {processed} transacciones procesadas")
            print("="*60)
            
        finally:
            # Cerrar conexión
            mail.logout()

def main():
    import argparse
    
    parser = argparse.ArgumentParser()
    parser.add_argument("--hours", type=int, default=24, help="Horas hacia atrás a revisar")
    parser.add_argument("--daemon", action="store_true", help="Modo daemon: revisar cada 5 minutos")
    
    args = parser.parse_args()
    
    connector = GmailFinanceConnector()
    
    if args.daemon:
        print("🤖 Modo daemon activado (Ctrl+C para detener)")
        import time
        while True:
            connector.run(args.hours)
            print("\n⏳ Esperando 5 minutos...")
            time.sleep(300)
    else:
        connector.run(args.hours)

if __name__ == "__main__":
    main()
