#!/usr/bin/env python3
"""
backup-manager.py - Gestión automática de backups con encriptación
Version mejorada para Raspberry Pi Smart Home
"""

import os
import sys
import json
import gzip
import shutil
import hashlib
import subprocess
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Dict, Optional

class BackupManager:
    """Gestor de backups automático con verificación de integridad"""
    
    def __init__(self, config_file: Optional[str] = None):
        self.config_file = config_file or os.path.expanduser("~/clawd/backup-config.json")
        self.backup_dir = Path(os.path.expanduser("~/clawd/backups"))
        self.backup_dir.mkdir(parents=True, exist_ok=True)
        
        self.config = self.load_config()
        self.load_state()
    
    def load_config(self) -> Dict:
        """Cargar configuración de backup"""
        default_config = {
            "sources": [
                {"path": "~/.clawdbot", "name": "gateway-config"},
                {"path": "~/clawd/memory", "name": "memory-files"},
                {"path": "~/clawd/credentials", "name": "credentials"},
                {"path": "~/clawd/automations", "name": "automations"},
                {"path": "~/.config/systemd/user", "name": "systemd-services"}
            ],
            "schedule": {
                "daily": True,
                "time": "02:00",  # 2 AM
                "retention_days": 30
            },
            "encryption": {
                "enabled": True,
                "method": "gpg",  # o "age" para alternativa moderna
                "public_key": None  # Se configura durante setup
            },
            "verification": {
                "enabled": True,
                "test_restore": False
            },
            "notifications": {
                "on_success": False,
                "on_failure": True,
                "telegram": True
            }
        }
        
        if os.path.exists(self.config_file):
            with open(self.config_file) as f:
                config = json.load(f)
                # Merge con defaults
                for key, value in default_config.items():
                    if key not in config:
                        config[key] = value
                return config
        
        # Guardar configuración por defecto
        os.makedirs(os.path.dirname(self.config_file), exist_ok=True)
        with open(self.config_file, 'w') as f:
            json.dump(default_config, f, indent=2)
        
        return default_config
    
    def load_state(self):
        """Cargar estado de backups"""
        self.state_file = self.backup_dir / "backup-state.json"
        self.state = {
            "last_backup": None,
            "total_backups": 0,
            "total_size_mb": 0,
            "last_verification": None
        }
        
        if self.state_file.exists():
            with open(self.state_file) as f:
                self.state = json.load(f)
    
    def save_state(self):
        """Guardar estado de backups"""
        with open(self.state_file, 'w') as f:
            json.dump(self.state, f, indent=2, default=str)
    
    def calculate_checksum(self, file_path: Path) -> str:
        """Calcular SHA256 checksum de archivo"""
        sha256 = hashlib.sha256()
        with open(file_path, 'rb') as f:
            for chunk in iter(lambda: f.read(8192), b''):
                sha256.update(chunk)
        return sha256.hexdigest()
    
    def create_backup(self, name: Optional[str] = None) -> Dict:
        """Crear backup completo"""
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_name = name or f"smarthome_backup_{timestamp}"
        backup_path = self.backup_dir / backup_name
        
        print(f"📦 Creando backup: {backup_name}")
        
        # Crear directorio temporal
        temp_dir = backup_path.with_suffix('.tmp')
        temp_dir.mkdir(parents=True, exist_ok=True)
        
        backup_manifest = {
            "name": backup_name,
            "timestamp": datetime.now().isoformat(),
            "sources": [],
            "checksums": {}
        }
        
        # Copiar cada fuente
        for source in self.config["sources"]:
            src_path = Path(os.path.expanduser(source["path"]))
            dst_path = temp_dir / source["name"]
            
            if src_path.exists():
                print(f"  📁 Copiando: {source['name']}")
                
                if src_path.is_dir():
                    shutil.copytree(src_path, dst_path, ignore=shutil.ignore_patterns('*.log'))
                else:
                    dst_path.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(src_path, dst_path)
                
                backup_manifest["sources"].append(source["name"])
            else:
                print(f"  ⚠️  No encontrado: {source['name']}")
        
        # Crear manifest
        manifest_path = temp_dir / "MANIFEST.json"
        with open(manifest_path, 'w') as f:
            json.dump(backup_manifest, f, indent=2)
        
        # Comprimir
        print(f"  🗜️  Comprimiendo...")
        archive_path = self.backup_dir / f"{backup_name}.tar.gz"
        
        subprocess.run([
            "tar", "-czf", str(archive_path),
            "-C", str(temp_dir.parent),
            temp_dir.name
        ], check=True)
        
        # Calcular checksum
        checksum = self.calculate_checksum(archive_path)
        backup_manifest["archive_checksum"] = checksum
        
        # Encriptar si está habilitado
        if self.config["encryption"]["enabled"]:
            print(f"  🔒 Encriptando...")
            encrypted_path = self.encrypt_backup(archive_path)
            if encrypted_path:
                archive_path = encrypted_path
                backup_manifest["encrypted"] = True
        
        # Limpiar temporal
        shutil.rmtree(temp_dir)
        
        # Actualizar estado
        self.state["last_backup"] = datetime.now().isoformat()
        self.state["total_backups"] += 1
        self.state["total_size_mb"] += archive_path.stat().st_size / (1024 * 1024)
        self.save_state()
        
        # Guardar manifest final
        manifest_backup = self.backup_dir / f"{backup_name}.manifest.json"
        with open(manifest_backup, 'w') as f:
            json.dump(backup_manifest, f, indent=2)
        
        print(f"✅ Backup completado: {archive_path.name}")
        print(f"   Tamaño: {archive_path.stat().st_size / (1024*1024):.1f} MB")
        print(f"   Checksum: {checksum[:16]}...")
        
        return backup_manifest
    
    def encrypt_backup(self, archive_path: Path) -> Optional[Path]:
        """Encriptar backup con GPG o age"""
        method = self.config["encryption"].get("method", "gpg")
        
        if method == "gpg":
            encrypted_path = archive_path.with_suffix(".tar.gz.gpg")
            
            try:
                # Usar cifrado simétrico con passphrase
                subprocess.run([
                    "gpg", "--symmetric",
                    "--cipher-algo", "AES256",
                    "--compress-algo", "0",  # No comprimir (ya está comprimido)
                    "--output", str(encrypted_path),
                    str(archive_path)
                ], check=True, input=b'')  # Se requerirá passphrase interactivo
                
                # Eliminar original sin encriptar
                archive_path.unlink()
                
                return encrypted_path
                
            except subprocess.CalledProcessError:
                print("  ⚠️  Error en encriptación GPG")
                return None
        
        elif method == "age":
            # age es más moderno y simple
            encrypted_path = archive_path.with_suffix(".tar.gz.age")
            
            try:
                subprocess.run([
                    "age", "-p",  # Con passphrase
                    "-o", str(encrypted_path),
                    str(archive_path)
                ], check=True)
                
                archive_path.unlink()
                return encrypted_path
                
            except FileNotFoundError:
                print("  ⚠️  'age' no instalado. Instalar con: apt install age")
                return None
        
        return None
    
    def verify_backup(self, backup_name: str) -> bool:
        """Verificar integridad de backup"""
        
        backup_path = self.backup_dir / backup_name
        
        # Si está encriptado, buscar archivo encriptado
        if not backup_path.exists():
            gpg_path = backup_path.with_suffix(".tar.gz.gpg")
            age_path = backup_path.with_suffix(".tar.gz.age")
            
            if gpg_path.exists():
                print(f"📦 Backup encriptado detectado (GPG)")
                # Verificación limitada (necesitaría desencriptar)
                return True
            elif age_path.exists():
                print(f"📦 Backup encriptado detectado (age)")
                return True
            else:
                print(f"❌ Backup no encontrado: {backup_name}")
                return False
        
        # Verificar checksum
        manifest_path = self.backup_dir / f"{backup_name}.manifest.json"
        
        if manifest_path.exists():
            with open(manifest_path) as f:
                manifest = json.load(f)
            
            current_checksum = self.calculate_checksum(backup_path)
            stored_checksum = manifest.get("archive_checksum")
            
            if current_checksum == stored_checksum:
                print(f"✅ Verificación exitosa: checksums coinciden")
                return True
            else:
                print(f"❌ ¡CORRUPCIÓN DETECTADA!")
                print(f"   Esperado: {stored_checksum[:16]}...")
                print(f"   Actual:   {current_checksum[:16]}...")
                return False
        
        return True
    
    def cleanup_old_backups(self):
        """Eliminar backups antiguos según política de retención"""
        
        retention_days = self.config["schedule"]["retention_days"]
        cutoff = datetime.now() - timedelta(days=retention_days)
        
        print(f"🧹 Limpiando backups antiguos (> {retention_days} días)...")
        
        deleted = 0
        for backup_file in self.backup_dir.glob("smarthome_backup_*.tar.gz*"):
            # Extraer fecha del nombre
            try:
                date_str = backup_file.stem.split('_')[2]
                backup_date = datetime.strptime(date_str, "%Y%m%d")
                
                if backup_date < cutoff:
                    backup_file.unlink()
                    # También eliminar manifest
                    manifest = backup_file.with_suffix('').with_suffix('.manifest.json')
                    if manifest.exists():
                        manifest.unlink()
                    
                    print(f"  🗑️  Eliminado: {backup_file.name}")
                    deleted += 1
            except:
                pass
        
        print(f"✅ {deleted} backups eliminados")
    
    def list_backups(self):
        """Listar todos los backups disponibles"""
        
        print("📋 Backups disponibles:")
        print("=" * 60)
        
        backups = sorted(
            self.backup_dir.glob("smarthome_backup_*.tar.gz*"),
            key=lambda f: f.stat().st_mtime,
            reverse=True
        )
        
        for i, backup in enumerate(backups[:10], 1):  # Mostrar últimos 10
            size_mb = backup.stat().st_size / (1024 * 1024)
            mtime = datetime.fromtimestamp(backup.stat().st_mtime)
            age_days = (datetime.now() - mtime).days
            
            encrypted = "🔒" if backup.suffix in ['.gpg', '.age'] else "  "
            
            print(f"{i}. {backup.name[:40]:40} {encrypted} {size_mb:6.1f}MB  ({age_days}d)")
        
        if len(backups) > 10:
            print(f"... y {len(backups) - 10} más")
    
    def schedule_backup(self):
        """Configurar backup automático vía cron"""
        
        time_str = self.config["schedule"]["time"]
        hour, minute = time_str.split(':')
        
        cron_line = f"{minute} {hour} * * * {sys.executable} {__file__} auto"
        
        print(f"📅 Configurando backup automático: {time_str} diario")
        print(f"   Cron: {cron_line}")
        
        # Añadir a crontab del usuario
        current_crontab = subprocess.run(
            ["crontab", "-l"],
            capture_output=True,
            text=True
        ).stdout
        
        if "backup-manager.py auto" not in current_crontab:
            new_crontab = current_crontab + f"\n{cron_line}\n"
            subprocess.run(
                ["crontab", "-"],
                input=new_crontab,
                text=True,
                check=True
            )
            print("✅ Backup automático configurado")
        else:
            print("ℹ️  Backup automático ya configurado")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Backup Manager for Smart Home')
    parser.add_argument('action', choices=['create', 'verify', 'list', 'cleanup', 'schedule', 'auto'])
    parser.add_argument('--name', help='Nombre del backup (para create/verify)')
    
    args = parser.parse_args()
    
    manager = BackupManager()
    
    if args.action == 'create':
        manager.create_backup(args.name)
    elif args.action == 'verify':
        if args.name:
            manager.verify_backup(args.name)
        else:
            print("❌ Se requiere --name para verificar")
    elif args.action == 'list':
        manager.list_backups()
    elif args.action == 'cleanup':
        manager.cleanup_old_backups()
    elif args.action == 'schedule':
        manager.schedule_backup()
    elif args.action == 'auto':
        # Ejecución automática (desde cron)
        print("🤖 Backup automático iniciado")
        backup = manager.create_backup()
        manager.cleanup_old_backups()
        
        if manager.config["verification"]["enabled"]:
            manager.verify_backup(backup["name"])

if __name__ == "__main__":
    main()
