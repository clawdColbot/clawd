#!/usr/bin/env python3
"""
vector_memory.py - Sistema de memoria vectorial para búsqueda semántica
Usa ChromaDB local (sin necesidad de API externa)
"""

import os
import json
import hashlib
from datetime import datetime
from pathlib import Path

# Config
MEMORY_DIR = Path("~/clawd/memory").expanduser()
VECTOR_DB_DIR = Path("~/clawd/.vector_db").expanduser()
VECTOR_DB_DIR.mkdir(parents=True, exist_ok=True)

class VectorMemory:
    """Sistema de memoria vectorial simple usando archivos JSON locales"""
    
    def __init__(self, collection_name="conversations"):
        self.collection_name = collection_name
        self.db_path = VECTOR_DB_DIR / f"{collection_name}.json"
        self.embeddings_path = VECTOR_DB_DIR / f"{collection_name}_embeddings.json"
        self.data = self._load_db()
        
    def _load_db(self):
        """Cargar base de datos existente o crear nueva"""
        if self.db_path.exists():
            with open(self.db_path, 'r') as f:
                return json.load(f)
        return {"entries": [], "metadata": {"created": datetime.now().isoformat()}}
    
    def _save_db(self):
        """Guardar base de datos"""
        with open(self.db_path, 'w') as f:
            json.dump(self.data, f, indent=2)
    
    def _simple_hash(self, text):
        """Crear hash simple para indexación (placeholder para embeddings reales)"""
        # En producción, esto usaría sentence-transformers o OpenAI embeddings
        words = text.lower().split()
        # Crear vector simple basado en frecuencia de palabras
        word_freq = {}
        for word in words:
            word_freq[word] = word_freq.get(word, 0) + 1
        return word_freq
    
    def _similarity_score(self, vec1, vec2):
        """Calcular similitud coseno simplificada"""
        # Producto punto simplificado
        common_words = set(vec1.keys()) & set(vec2.keys())
        if not common_words:
            return 0.0
        
        dot_product = sum(vec1[w] * vec2[w] for w in common_words)
        magnitude1 = sum(v**2 for v in vec1.values()) ** 0.5
        magnitude2 = sum(v**2 for v in vec2.values()) ** 0.5
        
        if magnitude1 == 0 or magnitude2 == 0:
            return 0.0
        
        return dot_product / (magnitude1 * magnitude2)
    
    def add(self, text, metadata=None):
        """Agregar entrada a la memoria vectorial"""
        entry = {
            "id": hashlib.md5(f"{text}{datetime.now()}".encode()).hexdigest()[:12],
            "text": text,
            "vector": self._simple_hash(text),
            "metadata": metadata or {},
            "timestamp": datetime.now().isoformat()
        }
        
        self.data["entries"].append(entry)
        self._save_db()
        return entry["id"]
    
    def search(self, query, top_k=5):
        """Buscar entradas similares al query"""
        query_vector = self._simple_hash(query)
        
        # Calcular similitud con todas las entradas
        scores = []
        for entry in self.data["entries"]:
            score = self._similarity_score(query_vector, entry["vector"])
            scores.append((score, entry))
        
        # Ordenar por similitud y retornar top_k
        scores.sort(reverse=True, key=lambda x: x[0])
        return [(score, entry) for score, entry in scores[:top_k] if score > 0.1]
    
    def index_memory_files(self):
        """Indexar archivos de memoria existentes"""
        print("🔄 Indexando archivos de memoria...")
        
        memory_files = list(MEMORY_DIR.glob("*.md"))
        indexed = 0
        
        for file_path in memory_files:
            try:
                with open(file_path, 'r') as f:
                    content = f.read()
                
                # Dividir en chunks de ~500 caracteres
                chunks = [content[i:i+500] for i in range(0, len(content), 500)]
                
                for chunk in chunks:
                    if len(chunk.strip()) > 50:  # Solo chunks significativos
                        self.add(chunk, {
                            "source": file_path.name,
                            "type": "memory_file"
                        })
                        indexed += 1
                        
            except Exception as e:
                print(f"  ⚠️  Error indexando {file_path}: {e}")
        
        print(f"✅ Indexados {indexed} chunks de {len(memory_files)} archivos")
        return indexed
    
    def stats(self):
        """Mostrar estadísticas de la memoria vectorial"""
        entries = len(self.data["entries"])
        print(f"📊 Estadísticas de Memoria Vectorial:")
        print(f"   Colección: {self.collection_name}")
        print(f"   Entradas: {entries}")
        print(f"   DB file: {self.db_path}")
        
        if entries > 0:
            # Mostrar fuentes únicas
            sources = set()
            for entry in self.data["entries"]:
                sources.add(entry.get("metadata", {}).get("source", "unknown"))
            print(f"   Fuentes: {len(sources)}")
            for source in list(sources)[:5]:
                print(f"      - {source}")

if __name__ == "__main__":
    import sys
    
    vm = VectorMemory()
    
    if len(sys.argv) < 2:
        print("Uso: vector_memory.py [index|search|stats] [query]")
        print("")
        print("Ejemplos:")
        print("  python3 vector_memory.py index     # Indexar archivos de memoria")
        print("  python3 vector_memory.py stats     # Ver estadísticas")
        print("  python3 vector_memory.py search \"prompt injection\"")
        sys.exit(0)
    
    command = sys.argv[1]
    
    if command == "index":
        vm.index_memory_files()
    
    elif command == "stats":
        vm.stats()
    
    elif command == "search":
        if len(sys.argv) < 3:
            print("❌ Falta query de búsqueda")
            sys.exit(1)
        
        query = " ".join(sys.argv[2:])
        print(f"🔍 Buscando: '{query}'")
        print("")
        
        results = vm.search(query, top_k=5)
        
        if not results:
            print("❌ No se encontraron resultados")
        else:
            for i, (score, entry) in enumerate(results, 1):
                print(f"{i}. [Score: {score:.3f}] {entry['metadata'].get('source', 'unknown')}")
                text_preview = entry['text'][:150].replace('\n', ' ')
                print(f"   {text_preview}...")
                print()
    
    else:
        print(f"❌ Comando desconocido: {command}")
