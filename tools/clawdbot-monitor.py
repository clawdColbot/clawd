#!/usr/bin/env python3
"""
clawdbot-monitor.py - Monitor de salud para Clawdbot
Muestra estado del gateway, uso de tokens, procesos activos, y alertas.
"""

import subprocess
import json
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path

class ClawdbotMonitor:
    def __init__(self):
        self.status = {
            "timestamp": datetime.now().isoformat(),
            "gateway": {},
            "system": {},
            "processes": [],
            "alerts": []
        }
    
    def check_gateway(self):
        """Verificar estado del gateway"""
        try:
            result = subprocess.run(
                ["clawdbot", "status", "--json"],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                # Parse output manualmente ya que --json puede no existir
                output = result.stdout
                
                self.status["gateway"]["running"] = "running" in output.lower() or "active" in output.lower()
                self.status["gateway"]["reachable"] = "reachable" in output.lower()
                
                # Extraer info básica
                if "Gateway" in output:
                    self.status["gateway"]["status"] = "online"
                else:
                    self.status["gateway"]["status"] = "unknown"
                    
            else:
                self.status["gateway"]["status"] = "error"
                self.status["alerts"].append("Gateway no responde")
                
        except Exception as e:
            self.status["gateway"]["status"] = "error"
            self.status["alerts"].append(f"Error checking gateway: {e}")
    
    def check_system(self):
        """Verificar recursos del sistema"""
        try:
            # Uso de disco
            df = subprocess.run(
                ["df", "-h", os.path.expanduser("~")],
                capture_output=True,
                text=True
            )
            
            # Uso de memoria
            free = subprocess.run(
                ["free", "-h"],
                capture_output=True,
                text=True
            )
            
            # Load average
            uptime = subprocess.run(
                ["uptime"],
                capture_output=True,
                text=True
            )
            
            self.status["system"]["disk"] = df.stdout.strip()
            self.status["system"]["memory"] = free.stdout.strip()
            self.status["system"]["uptime"] = uptime.stdout.strip()
            
        except Exception as e:
            self.status["alerts"].append(f"Error checking system: {e}")
    
    def check_processes(self):
        """Verificar procesos relacionados con Clawdbot"""
        try:
            # Buscar procesos de clawdbot
            ps = subprocess.run(
                ["pgrep", "-a", "-f", "clawdbot"],
                capture_output=True,
                text=True
            )
            
            if ps.stdout:
                processes = ps.stdout.strip().split('\n')
                self.status["processes"] = processes[:5]  # Limitar a 5
            else:
                self.status["processes"] = []
                self.status["alerts"].append("No se encontraron procesos de Clawdbot")
            
            # Verificar procesos de background (generación de imágenes, etc.)
            bg_processes = subprocess.run(
                ["pgrep", "-a", "-f", "python.*isabella|python.*generate_dataset"],
                capture_output=True,
                text=True
            )
            
            if bg_processes.stdout:
                self.status["background_jobs"] = bg_processes.stdout.strip().split('\n')
            else:
                self.status["background_jobs"] = []
                
        except Exception as e:
            self.status["alerts"].append(f"Error checking processes: {e}")
    
    def check_logs(self):
        """Verificar errores recientes en logs"""
        try:
            # Buscar logs de clawdbot
            log_dir = Path.home() / ".clawdbot" / "logs"
            
            if log_dir.exists():
                # Buscar errores recientes (últimas 24h)
                recent_errors = []
                
                for log_file in log_dir.glob("*.log"):
                    try:
                        stat = log_file.stat()
                        mtime = datetime.fromtimestamp(stat.st_mtime)
                        
                        if datetime.now() - mtime < timedelta(hours=24):
                            # Leer últimas líneas buscando errores
                            result = subprocess.run(
                                ["tail", "-50", str(log_file)],
                                capture_output=True,
                                text=True
                            )
                            
                            errors = [line for line in result.stdout.split('\n') 
                                     if 'error' in line.lower() or 'fail' in line.lower()]
                            
                            if errors:
                                recent_errors.extend(errors[:3])  # Max 3 por archivo
                    except:
                        pass
                
                self.status["recent_errors"] = recent_errors[:5]  # Max 5 total
                
                if len(recent_errors) > 5:
                    self.status["alerts"].append(f"{len(recent_errors)} errores recientes en logs")
            
        except Exception as e:
            self.status["alerts"].append(f"Error checking logs: {e}")
    
    def check_memory_usage(self):
        """Verificar uso de archivos de memoria"""
        try:
            memory_dir = Path.home() / "clawd" / "memory"
            
            if memory_dir.exists():
                files = list(memory_dir.glob("*.md"))
                total_size = sum(f.stat().st_size for f in files)
                
                self.status["memory_files"] = {
                    "count": len(files),
                    "total_size_mb": round(total_size / (1024 * 1024), 2),
                    "latest": max(files, key=lambda f: f.stat().st_mtime).name if files else None
                }
                
                # Alerta si hay muchos archivos
                if len(files) > 100:
                    self.status["alerts"].append(f"{len(files)} archivos de memory - considerar limpieza")
                    
        except Exception as e:
            self.status["alerts"].append(f"Error checking memory: {e}")
    
    def check_backups(self):
        """Verificar estado de backups"""
        try:
            backup_dir = Path.home() / "clawd" / "backups"
            
            if backup_dir.exists():
                backups = sorted(backup_dir.glob("clawdbot_backup_*.tar.gz*"), 
                               key=lambda f: f.stat().st_mtime, 
                               reverse=True)
                
                if backups:
                    latest = backups[0]
                    latest_time = datetime.fromtimestamp(latest.stat().st_mtime)
                    age_hours = (datetime.now() - latest_time).total_seconds() / 3600
                    
                    self.status["backups"] = {
                        "latest": latest.name,
                        "age_hours": round(age_hours, 1),
                        "count": len(backups),
                        "total_size_gb": round(sum(b.stat().st_size for b in backups) / (1024**3), 2)
                    }
                    
                    # Alerta si el backup es viejo
                    if age_hours > 48:
                        self.status["alerts"].append(f"Backup tiene {int(age_hours)}h - considerar nuevo backup")
                else:
                    self.status["alerts"].append("No se encontraron backups")
                    
        except Exception as e:
            self.status["alerts"].append(f"Error checking backups: {e}")
    
    def print_report(self):
        """Imprimir reporte en formato legible"""
        print("=" * 60)
        print("🦊  CLAWDBOT HEALTH MONITOR")
        print("=" * 60)
        print(f"📅 {self.status['timestamp']}")
        print()
        
        # Gateway Status
        print("🔌 GATEWAY STATUS")
        print("-" * 40)
        gw = self.status.get("gateway", {})
        status_icon = "✅" if gw.get("status") == "online" else "❌"
        print(f"{status_icon} Status: {gw.get('status', 'unknown')}")
        print(f"   Running: {gw.get('running', False)}")
        print(f"   Reachable: {gw.get('reachable', False)}")
        print()
        
        # Background Jobs
        print("⚙️  BACKGROUND JOBS")
        print("-" * 40)
        if self.status.get("background_jobs"):
            for job in self.status["background_jobs"]:
                print(f"  🔄 {job[:60]}...")
        else:
            print("  No hay jobs activos")
        print()
        
        # Memory Files
        print("📝 MEMORY FILES")
        print("-" * 40)
        mem = self.status.get("memory_files", {})
        print(f"  📄 Count: {mem.get('count', 0)}")
        print(f"  💾 Size: {mem.get('total_size_mb', 0)} MB")
        if mem.get('latest'):
            print(f"  🕐 Latest: {mem['latest']}")
        print()
        
        # Backups
        print("💾 BACKUPS")
        print("-" * 40)
        bk = self.status.get("backups", {})
        if bk:
            print(f"  📦 Latest: {bk.get('latest', 'N/A')}")
            print(f"  ⏰ Age: {bk.get('age_hours', 0)}h")
            print(f"  🔢 Count: {bk.get('count', 0)}")
        else:
            print("  ❌ No backups found")
        print()
        
        # Recent Errors
        if self.status.get("recent_errors"):
            print("⚠️  RECENT ERRORS")
            print("-" * 40)
            for error in self.status["recent_errors"][:3]:
                print(f"  ⚠️  {error[:80]}")
            print()
        
        # Alerts
        if self.status.get("alerts"):
            print("🚨 ALERTS")
            print("-" * 40)
            for alert in self.status["alerts"]:
                print(f"  ⚠️  {alert}")
            print()
        else:
            print("✅ No alerts - System healthy!")
            print()
        
        print("=" * 60)
    
    def run(self):
        """Ejecutar todas las verificaciones"""
        print("🔍 Checking Clawdbot health...\n")
        
        self.check_gateway()
        self.check_processes()
        self.check_memory_usage()
        self.check_backups()
        self.check_logs()
        self.check_system()
        
        self.print_report()
        
        # Retornar código de salida basado en alertas
        return 1 if self.status["alerts"] else 0

if __name__ == "__main__":
    monitor = ClawdbotMonitor()
    exit_code = monitor.run()
    sys.exit(exit_code)
