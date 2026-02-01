#!/usr/bin/env python3
"""
secure-voice-gateway.py - Gateway de voz con autenticación y seguridad
Valida comandos, autentica usuarios, loguea actividad
"""

import hashlib
import hmac
import json
import logging
import os
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional, Dict, List
import functools

class SecureVoiceGateway:
    """Gateway seguro para comandos de voz"""
    
    def __init__(self):
        self.config_dir = Path.home() / "clawd" / "credentials"
        self.logs_dir = Path.home() / "clawd" / "logs"
        self.logs_dir.mkdir(parents=True, exist_ok=True)
        
        # Configurar logging seguro
        self.setup_logging()
        
        # Cargar configuración de seguridad
        self.security_config = self.load_security_config()
        
        # Rate limiting
        self.command_history: Dict[str, List[float]] = {}
        
        # Usuarios autorizados (voice fingerprint)
        self.authorized_users = self.load_authorized_users()
        
    def setup_logging(self):
        """Configurar logs de auditoría"""
        log_file = self.logs_dir / f"voice-audit-{datetime.now().strftime('%Y-%m')}.log"
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger('voice-gateway')
        
    def load_security_config(self) -> Dict:
        """Cargar configuración de seguridad"""
        config_file = self.config_dir / "security-config.json"
        
        default_config = {
            "max_commands_per_minute": 10,
            "max_commands_per_hour": 100,
            "require_authentication": True,
            "sensitive_commands": [
                "unlock", "open", "disable", "delete", "format",
                "unlock door", "open garage", "disable alarm"
            ],
            "allowed_hours": {
                "start": 6,  # 6 AM
                "end": 23    # 11 PM
            },
            "confirmation_required": True,
            "log_all_commands": True
        }
        
        if config_file.exists():
            with open(config_file) as f:
                return {**default_config, **json.load(f)}
        
        # Guardar configuración por defecto
        config_file.parent.mkdir(parents=True, exist_ok=True)
        with open(config_file, 'w') as f:
            json.dump(default_config, f, indent=2)
        
        return default_config
    
    def load_authorized_users(self) -> Dict:
        """Cargar usuarios autorizados con voice fingerprints"""
        users_file = self.config_dir / "authorized-users.json"
        
        if users_file.exists():
            with open(users_file) as f:
                return json.load(f)
        
        return {
            "andres": {
                "name": "Andres",
                "voice_profile": None,  # Se configura durante setup
                "pin": None,  # PIN de respaldo
                "is_admin": True,
                "allowed_commands": ["*"],  # Todos los comandos
                "created_at": datetime.now().isoformat()
            }
        }
    
    def check_rate_limit(self, user_id: str) -> bool:
        """Verificar rate limiting para usuario"""
        now = time.time()
        
        if user_id not in self.command_history:
            self.command_history[user_id] = []
        
        # Limpiar historial antiguo
        self.command_history[user_id] = [
            t for t in self.command_history[user_id]
            if now - t < 3600  # Mantener última hora
        ]
        
        # Verificar límites
        last_minute = [t for t in self.command_history[user_id] if now - t < 60]
        last_hour = self.command_history[user_id]
        
        if len(last_minute) >= self.security_config["max_commands_per_minute"]:
            self.logger.warning(f"Rate limit exceeded (minute) for user: {user_id}")
            return False
        
        if len(last_hour) >= self.security_config["max_commands_per_hour"]:
            self.logger.warning(f"Rate limit exceeded (hour) for user: {user_id}")
            return False
        
        return True
    
    def is_sensitive_command(self, command: str) -> bool:
        """Detectar si un comando es sensible/requiere confirmación"""
        command_lower = command.lower()
        
        for sensitive in self.security_config["sensitive_commands"]:
            if sensitive in command_lower:
                return True
        
        return False
    
    def check_time_restrictions(self) -> bool:
        """Verificar restricciones de horario"""
        now = datetime.now()
        hour = now.hour
        
        start = self.security_config["allowed_hours"]["start"]
        end = self.security_config["allowed_hours"]["end"]
        
        if start <= end:
            return start <= hour < end
        else:  # Horario nocturno (ej: 22 a 6)
            return hour >= start or hour < end
    
    def authenticate_user(self, voice_fingerprint: Optional[str] = None, 
                         pin: Optional[str] = None) -> Optional[str]:
        """Autenticar usuario por voz o PIN"""
        # Por ahora, autenticación básica
        # En producción: comparar embeddings de voz
        
        if pin:
            for user_id, user_data in self.authorized_users.items():
                if user_data.get("pin") == pin:
                    self.logger.info(f"User authenticated via PIN: {user_id}")
                    return user_id
        
        # Si no hay autenticación estricta, permitir usuario por defecto
        if not self.security_config["require_authentication"]:
            return "andres"
        
        self.logger.warning("Authentication failed")
        return None
    
    def validate_command(self, command: str, user_id: str) -> tuple[bool, str]:
        """Validar comando antes de ejecutar"""
        
        # 1. Verificar rate limiting
        if not self.check_rate_limit(user_id):
            return False, "Rate limit exceeded. Please wait."
        
        # 2. Verificar restricciones de horario
        if not self.check_time_restrictions():
            return False, "Voice commands disabled during quiet hours."
        
        # 3. Verificar permisos de usuario
        user = self.authorized_users.get(user_id, {})
        allowed = user.get("allowed_commands", [])
        
        if "*" not in allowed:
            command_allowed = any(cmd in command.lower() for cmd in allowed)
            if not command_allowed:
                return False, "Command not allowed for this user."
        
        # 4. Detectar comandos sensibles
        if self.is_sensitive_command(command):
            if self.security_config["confirmation_required"]:
                return True, "SENSITIVE_COMMAND"  # Requiere confirmación
        
        # Registrar comando
        if user_id not in self.command_history:
            self.command_history[user_id] = []
        self.command_history[user_id].append(time.time())
        
        self.logger.info(f"Command validated: '{command}' by user: {user_id}")
        
        return True, "OK"
    
    def execute_secure(self, command: str, user_id: str) -> str:
        """Ejecutar comando de forma segura"""
        
        is_valid, message = self.validate_command(command, user_id)
        
        if not is_valid:
            self.logger.warning(f"Command rejected: '{command}' - {message}")
            return f"Error: {message}"
        
        if message == "SENSITIVE_COMMAND":
            # Requerir confirmación adicional
            return self.request_confirmation(command, user_id)
        
        # Ejecutar comando (aquí iría la integración real)
        try:
            result = self.execute_command(command, user_id)
            self.logger.info(f"Command executed: '{command}' - Result: {result}")
            return result
        except Exception as e:
            self.logger.error(f"Command execution failed: '{command}' - {e}")
            return f"Error executing command: {str(e)}"
    
    def request_confirmation(self, command: str, user_id: str) -> str:
        """Solicitar confirmación para comando sensible"""
        self.logger.info(f"Confirmation required for: '{command}' by user: {user_id}")
        
        # En producción: reproducir "¿Estás seguro?" y esperar "sí"
        # Por ahora, simulamos confirmación
        return f"CONFIRMATION_REQUIRED:{command}"
    
    def execute_command(self, command: str, user_id: str) -> str:
        """Ejecutar el comando real (integración con dispositivos)"""
        
        command_lower = command.lower()
        
        # SmartThings commands
        if any(x in command_lower for x in ["luz", "luces", "light"]):
            if any(x in command_lower for x in ["enciende", "prende", "on"]):
                return self.control_lights("on", user_id)
            elif any(x in command_lower for x in ["apaga", "off"]):
                return self.control_lights("off", user_id)
        
        elif "música" in command_lower or "musica" in command_lower:
            return self.control_music(command, user_id)
        
        elif "tv" in command_lower or "tele" in command_lower:
            return self.control_tv(command, user_id)
        
        # Información
        elif "hora" in command_lower:
            from datetime import datetime
            return f"Son las {datetime.now().strftime('%I:%M %p')}"
        
        elif "temperatura" in command_lower:
            return self.get_temperature()
        
        else:
            return f"Comando no reconocido: {command}"
    
    def control_lights(self, action: str, user_id: str) -> str:
        """Controlar luces via SmartThings/Home Assistant"""
        # Aquí iría la integración real
        self.logger.info(f"Lights {action} by {user_id}")
        return f"Luces {action}"
    
    def control_music(self, command: str, user_id: str) -> str:
        """Controlar música en Samsung Music Frame"""
        self.logger.info(f"Music command: {command} by {user_id}")
        
        if "pausa" in command or "pause" in command:
            return "Música pausada"
        elif "sube" in command or "up" in command:
            return "Volumen subido"
        elif "baja" in command or "down" in command:
            return "Volumen bajado"
        else:
            return "Reproduciendo música"
    
    def control_tv(self, command: str, user_id: str) -> str:
        """Controlar TV Samsung"""
        self.logger.info(f"TV command: {command} by {user_id}")
        
        if "apaga" in command or "off" in command:
            return "TV apagada"
        elif "enciende" in command or "on" in command:
            return "TV encendida"
        else:
            return "Comando de TV ejecutado"
    
    def get_temperature(self) -> str:
        """Obtener temperatura de sensores"""
        # Aquí iría la integración con sensores
        return "La temperatura es de 22 grados Celsius"

# Instancia global
gateway = SecureVoiceGateway()

def secure_voice_command(command: str, user_id: str = "andres") -> str:
    """Función de conveniencia para procesar comandos"""
    return gateway.execute_secure(command, user_id)

if __name__ == "__main__":
    # Test
    print("Testing Secure Voice Gateway...")
    
    # Comando normal
    result = secure_voice_command("enciende las luces")
    print(f"Normal command: {result}")
    
    # Comando sensible
    result = secure_voice_command("abre la puerta principal")
    print(f"Sensitive command: {result}")
