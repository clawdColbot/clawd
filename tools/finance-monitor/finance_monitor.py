#!/usr/bin/env python3
"""
finance_monitor.py - Sistema básico de monitoreo financiero
Monitorea precios de crypto y alerta sobre cambios significativos
"""

import os
import json
import time
import urllib.request
from datetime import datetime
from pathlib import Path

# Config
CACHE_DIR = Path("~/.cache/finance_monitor").expanduser()
CACHE_DIR.mkdir(parents=True, exist_ok=True)
ALERT_LOG = Path("~/clawd/logs/finance_alerts.log").expanduser()
ALERT_LOG.parent.mkdir(parents=True, exist_ok=True)

# Thresholds para alertas
THRESHOLDS = {
    "BTC": 5.0,   # Alertar si cambia 5%
    "ETH": 7.0,   # Alertar si cambia 7%
    "SOL": 10.0,  # Alertar si cambia 10%
}

class FinanceMonitor:
    """Monitor de precios de cripto para agents"""
    
    def __init__(self):
        self.cache_file = CACHE_DIR / "prices_cache.json"
        self.previous_prices = self._load_cache()
    
    def _load_cache(self):
        """Cargar precios anteriores"""
        if self.cache_file.exists():
            with open(self.cache_file, 'r') as f:
                return json.load(f)
        return {}
    
    def _save_cache(self, prices):
        """Guardar precios actuales"""
        with open(self.cache_file, 'w') as f:
            json.dump(prices, f, indent=2)
    
    def _send_alert(self, message):
        """Enviar alerta (log + opcional Telegram)"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        alert_msg = f"[{timestamp}] {message}"
        
        # Guardar en log
        with open(ALERT_LOG, 'a') as f:
            f.write(alert_msg + '\n')
        
        print(f"🚨 {alert_msg}")
        
        # Enviar a Telegram si está configurado
        telegram_token = os.environ.get('TELEGRAM_BOT_TOKEN')
        chat_id = os.environ.get('TELEGRAM_CHAT_ID')
        
        if telegram_token and chat_id:
            try:
                url = f"https://api.telegram.org/bot{telegram_token}/sendMessage"
                data = {
                    'chat_id': chat_id,
                    'text': f"💰 {message}"
                }
                req = urllib.request.Request(
                    url,
                    data=json.dumps(data).encode(),
                    headers={'Content-Type': 'application/json'}
                )
                urllib.request.urlopen(req, timeout=5)
            except Exception as e:
                print(f"  ⚠️  No se pudo enviar a Telegram: {e}")
    
    def fetch_prices(self):
        """Obtener precios de CoinGecko (API gratuita)"""
        try:
            url = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,solana&vs_currencies=usd&include_24hr_change=true"
            req = urllib.request.Request(url, headers={
                'User-Agent': 'Mozilla/5.0 (ClawdFinanceMonitor)'
            })
            
            with urllib.request.urlopen(req, timeout=10) as response:
                data = json.loads(response.read().decode())
                
                return {
                    "BTC": {
                        "price": data['bitcoin']['usd'],
                        "change_24h": data['bitcoin'].get('usd_24h_change', 0)
                    },
                    "ETH": {
                        "price": data['ethereum']['usd'],
                        "change_24h": data['ethereum'].get('usd_24h_change', 0)
                    },
                    "SOL": {
                        "price": data['solana']['usd'],
                        "change_24h": data['solana'].get('usd_24h_change', 0)
                    }
                }
        except Exception as e:
            print(f"❌ Error obteniendo precios: {e}")
            return None
    
    def check_alerts(self, current_prices):
        """Verificar si hay alertas por cambios significativos"""
        alerts_triggered = []
        
        for coin, data in current_prices.items():
            change_24h = data['change_24h']
            threshold = THRESHOLDS.get(coin, 5.0)
            
            # Alertar si el cambio supera el threshold
            if abs(change_24h) >= threshold:
                direction = "📈 SUBIÓ" if change_24h > 0 else "📉 BAJÓ"
                message = f"{direction} {coin}: {change_24h:+.2f}% en 24h (Precio: ${data['price']:,.2f})"
                self._send_alert(message)
                alerts_triggered.append(message)
        
        return alerts_triggered
    
    def check_price_changes(self, current_prices):
        """Verificar cambios desde última ejecución"""
        if not self.previous_prices:
            return
        
        for coin, data in current_prices.items():
            if coin in self.previous_prices:
                prev_price = self.previous_prices[coin]['price']
                curr_price = data['price']
                change_pct = ((curr_price - prev_price) / prev_price) * 100
                
                # Alertar si cambió más de 2% desde última ejecución
                if abs(change_pct) >= 2.0:
                    direction = "📈" if change_pct > 0 else "📉"
                    message = f"{direction} {coin} cambió {change_pct:+.2f}% desde último check: ${prev_price:,.2f} → ${curr_price:,.2f}"
                    self._send_alert(message)
    
    def run(self):
        """Ejecutar monitoreo"""
        print("💰 Finance Monitor - Iniciando...")
        print(f"   Umbrales: BTC {THRESHOLDS['BTC']}%, ETH {THRESHOLDS['ETH']}%, SOL {THRESHOLDS['SOL']}%")
        print("")
        
        # Obtener precios
        current_prices = self.fetch_prices()
        
        if not current_prices:
            print("❌ No se pudieron obtener precios")
            return False
        
        # Mostrar precios actuales
        print("📊 Precios actuales:")
        for coin, data in current_prices.items():
            change_emoji = "🟢" if data['change_24h'] >= 0 else "🔴"
            print(f"   {change_emoji} {coin}: ${data['price']:,.2f} ({data['change_24h']:+.2f}%)")
        
        print("")
        
        # Verificar alertas
        alerts = self.check_alerts(current_prices)
        self.check_price_changes(current_prices)
        
        if alerts:
            print(f"⚠️  {len(alerts)} alerta(s) disparada(s)")
        else:
            print("✅ Sin alertas - Todo dentro de rangos normales")
        
        # Guardar precios para siguiente ejecución
        self._save_cache(current_prices)
        
        return True
    
    def status(self):
        """Mostrar estado del monitor"""
        print("💰 Finance Monitor Status")
        print("=" * 50)
        print(f"Cache dir: {CACHE_DIR}")
        print(f"Alert log: {ALERT_LOG}")
        print(f"Monitored: BTC, ETH, SOL")
        print(f"Thresholds: BTC {THRESHOLDS['BTC']}%, ETH {THRESHOLDS['ETH']}%, SOL {THRESHOLDS['SOL']}%")
        print("")
        
        if self.cache_file.exists():
            print("📊 Últimos precios conocidos:")
            for coin, data in self.previous_prices.items():
                print(f"   {coin}: ${data['price']:,.2f}")
        
        if ALERT_LOG.exists():
            print("")
            print("📋 Últimas alertas:")
            with open(ALERT_LOG, 'r') as f:
                lines = f.readlines()
                for line in lines[-5:]:
                    print(f"   {line.strip()}")

def main():
    import sys
    
    monitor = FinanceMonitor()
    
    if len(sys.argv) < 2:
        monitor.run()
    elif sys.argv[1] == "status":
        monitor.status()
    elif sys.argv[1] == "install-cron":
        # Instalar en cron cada 30 minutos
        import subprocess
        cron_line = "*/30 * * * * $(which python3) $(echo ~/clawd/tools/finance-monitor/finance_monitor.py) >> ~/clawd/logs/finance_monitor.log 2>&1"
        subprocess.run(f"(crontab -l 2>/dev/null; echo '{cron_line}') | crontab -", shell=True)
        print("✅ Cron instalado - Monitoreo cada 30 minutos")
    else:
        print("Uso: finance_monitor.py [status|install-cron]")

if __name__ == "__main__":
    main()
