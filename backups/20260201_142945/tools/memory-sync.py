#!/usr/bin/env python3
"""
memory-sync.py - Sincronización de memoria entre plataformas

Integra contexto de:
- Telegram (conversaciones con Andres)
- Moltbook (interacciones con comunidad)
- Shipyard (actividad de ships/tokens)
- Local files (MEMORY.md, daily logs)

Uso: python3 memory-sync.py [--update-memory]
"""

import json
import os
from datetime import datetime, timedelta
from pathlib import Path
import re

class MemorySync:
    def __init__(self):
        self.clawd_dir = Path.home() / "clawd"
        self.memory_dir = self.clawd_dir / "memory"
        self.sync_file = self.memory_dir / "sync-state.json"
        self.context_file = self.memory_dir / "unified-context.md"
        
        self.platforms = {
            "telegram": {"last_sync": None, "messages": []},
            "moltbook": {"last_sync": None, "posts": [], "comments": []},
            "shipyard": {"last_sync": None, "ships": [], "attestations": []},
            "local": {"last_sync": None, "files": []}
        }
        
        self.load_state()
    
    def load_state(self):
        """Cargar estado anterior de sincronización"""
        if self.sync_file.exists():
            try:
                with open(self.sync_file, 'r') as f:
                    saved = json.load(f)
                    self.platforms.update(saved)
            except:
                pass
    
    def save_state(self):
        """Guardar estado de sincronización"""
        with open(self.sync_file, 'w') as f:
            json.dump(self.platforms, f, indent=2, default=str)
    
    def scan_local_memory(self):
        """Escanear archivos de memoria locales"""
        print("📁 Escaneando memoria local...")
        
        recent_files = []
        cutoff = datetime.now() - timedelta(days=7)
        
        for file in self.memory_dir.glob("*.md"):
            try:
                mtime = datetime.fromtimestamp(file.stat().st_mtime)
                if mtime > cutoff:
                    with open(file, 'r', encoding='utf-8') as f:
                        content = f.read()
                        # Extraer primeros 500 chars como resumen
                        recent_files.append({
                            "file": file.name,
                            "date": mtime.isoformat(),
                            "preview": content[:500] + "..." if len(content) > 500 else content
                        })
            except:
                pass
        
        self.platforms["local"]["files"] = recent_files
        self.platforms["local"]["last_sync"] = datetime.now().isoformat()
        
        print(f"   ✅ {len(recent_files)} archivos recientes encontrados")
    
    def extract_moltbook_context(self):
        """Extraer contexto de Moltbook del estado guardado"""
        print("🌐 Extrayendo contexto de Moltbook...")
        
        moltbook_file = self.memory_dir / "moltbook-state.json"
        
        if moltbook_file.exists():
            try:
                with open(moltbook_file, 'r') as f:
                    state = json.load(f)
                    
                    self.platforms["moltbook"]["karma"] = state.get("karma", 0)
                    self.platforms["moltbook"]["posts"] = state.get("posts", 0)
                    self.platforms["moltbook"]["comments"] = state.get("comments", 0)
                    self.platforms["moltbook"]["last_sync"] = datetime.now().isoformat()
                    
                    print(f"   ✅ Karma: {state.get('karma', 0)}, Posts: {state.get('posts', 0)}")
            except:
                print("   ⚠️ No se pudo leer estado de Moltbook")
    
    def extract_shipyard_context(self):
        """Extraer contexto de Shipyard"""
        print("🪙 Extrayendo contexto de Shipyard...")
        
        shipyard_file = self.clawd_dir / "credentials" / "shipyard-registration.md"
        
        if shipyard_file.exists():
            try:
                with open(shipyard_file, 'r') as f:
                    content = f.read()
                    
                    # Extraer balance
                    balance_match = re.search(r'\*\*Balance\*\*\s*\|\s*(\d+)', content)
                    karma_match = re.search(r'\*\*Karma\*\*\s*\|\s*(\d+)', content)
                    
                    self.platforms["shipyard"]["balance"] = int(balance_match.group(1)) if balance_match else 0
                    self.platforms["shipyard"]["karma"] = int(karma_match.group(1)) if karma_match else 0
                    self.platforms["shipyard"]["last_sync"] = datetime.now().isoformat()
                    
                    print(f"   ✅ Balance: {self.platforms['shipyard']['balance']} SHIP")
            except:
                print("   ⚠️ No se pudo leer estado de Shipyard")
    
    def generate_unified_context(self):
        """Generar contexto unificado para uso en conversaciones"""
        print("🧠 Generando contexto unificado...")
        
        context = []
        context.append("# Contexto Unificado - ClawdColombia")
        context.append(f"*Generado: {datetime.now().strftime('%Y-%m-%d %H:%M')}*")
        context.append("")
        
        # Resumen de plataformas
        context.append("## 📊 Estado en Plataformas")
        context.append("")
        
        # Moltbook
        mb = self.platforms["moltbook"]
        context.append(f"**Moltbook:** Karma {mb.get('karma', 0)}, Posts {mb.get('posts', 0)}, Comments {mb.get('comments', 0)}")
        
        # Shipyard
        sy = self.platforms["shipyard"]
        context.append(f"**Shipyard:** {sy.get('balance', 0)} SHIP, Karma {sy.get('karma', 0)}")
        
        # Local
        lc = self.platforms["local"]
        context.append(f"**Local:** {len(lc.get('files', []))} archivos de memoria recientes")
        context.append("")
        
        # Actividad reciente (últimos 3 días)
        context.append("## 📝 Actividad Reciente")
        context.append("")
        
        # Archivos recientes
        recent_cutoff = datetime.now() - timedelta(days=3)
        for file_info in lc.get("files", [])[:5]:
            file_date = datetime.fromisoformat(file_info["date"])
            if file_date > recent_cutoff:
                context.append(f"**{file_info['file']}** ({file_date.strftime('%m-%d')})")
                # Extraer título o primera línea
                lines = file_info["preview"].split('\n')
                for line in lines[:3]:
                    if line.strip() and not line.startswith('#'):
                        context.append(f"> {line.strip()[:100]}")
                        break
                context.append("")
        
        # Proyectos activos
        context.append("## 🚀 Proyectos Activos")
        context.append("")
        context.append("- Ship #16: Gateway Security Audit Script (pending attestations)")
        context.append("- Ship #17: Security Guard v2.0 (pending attestations)")
        context.append("- Isabela Model: Generación de dataset con FLUX 2")
        context.append("- Nightly Build: Sistema de trabajo autónomo")
        context.append("")
        
        # Recordatorios contextuales
        context.append("## 💡 Recordatorios Contextuales")
        context.append("")
        
        # Pendientes de Shipyard
        if sy.get("balance", 0) < 50:
            context.append(f"- 🪙 Necesito {50 - sy.get('balance', 0)} SHIP más para 2x karma multiplier")
        
        # Pendientes generales
        context.append("- 🎙️ Instalar ffmpeg para transcripción de audios")
        context.append("- 🖼️ Revisar progreso de generación de imágenes Isabela")
        context.append("- 🛡️ Esperar attestations para Ships #16 y #17")
        context.append("")
        
        # Unir todo
        unified_text = "\n".join(context)
        
        # Guardar
        with open(self.context_file, 'w', encoding='utf-8') as f:
            f.write(unified_text)
        
        print(f"   ✅ Contexto guardado en: {self.context_file}")
        
        return unified_text
    
    def update_memory_md(self):
        """Actualizar MEMORY.md con resumen sincronizado"""
        print("📝 Actualizando MEMORY.md...")
        
        memory_file = self.clawd_dir / "MEMORY.md"
        
        if not memory_file.exists():
            print("   ⚠️ MEMORY.md no existe")
            return
        
        try:
            with open(memory_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Crear sección de estado actual
            status_section = f"""
## 📊 Estado Actual (Auto-generado)

*Última actualización: {datetime.now().strftime('%Y-%m-%d %H:%M')}*

| Plataforma | Métrica | Valor |
|------------|---------|-------|
| Moltbook | Karma | {self.platforms['moltbook'].get('karma', 0)} |
| Moltbook | Posts | {self.platforms['moltbook'].get('posts', 0)} |
| Shipyard | Balance | {self.platforms['shipyard'].get('balance', 0)} SHIP |
| Shipyard | Karma | {self.platforms['shipyard'].get('karma', 0)} |
| Local | Archivos recientes | {len(self.platforms['local'].get('files', []))} |

### 🚀 Proyectos Activos
- Ship #16: Gateway Security Audit Script
- Ship #17: Security Guard v2.0
- Isabela Model Dataset
- Nightly Build System

---

"""
            
            # Insertar o reemplazar sección
            if "## 📊 Estado Actual" in content:
                # Reemplazar sección existente
                pattern = r"## 📊 Estado Actual.*?---\n\n"
                import re
                content = re.sub(pattern, status_section, content, flags=re.DOTALL)
            else:
                # Insertar al principio (después del título)
                lines = content.split('\n')
                # Encontrar primera línea que no sea título
                insert_pos = 0
                for i, line in enumerate(lines):
                    if line.strip() and not line.startswith('#'):
                        insert_pos = i
                        break
                
                lines.insert(insert_pos, status_section)
                content = '\n'.join(lines)
            
            with open(memory_file, 'w', encoding='utf-8') as f:
                f.write(content)
            
            print("   ✅ MEMORY.md actualizado")
            
        except Exception as e:
            print(f"   ❌ Error actualizando MEMORY.md: {e}")
    
    def run(self, update_memory=False):
        """Ejecutar sincronización completa"""
        print("=" * 60)
        print("🔄 MEMORY SYNC - Cross-Platform Context")
        print("=" * 60)
        print()
        
        self.scan_local_memory()
        self.extract_moltbook_context()
        self.extract_shipyard_context()
        
        print()
        context = self.generate_unified_context()
        
        if update_memory:
            print()
            self.update_memory_md()
        
        self.save_state()
        
        print()
        print("=" * 60)
        print("✅ Sincronización completada")
        print(f"📄 Contexto unificado: {self.context_file}")
        print("=" * 60)
        
        return context

if __name__ == "__main__":
    import sys
    update = "--update-memory" in sys.argv
    
    sync = MemorySync()
    sync.run(update_memory=update)
