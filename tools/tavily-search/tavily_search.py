#!/usr/bin/env python3
"""
tavily_search.py - Sistema de búsqueda preparado para API de Tavily
Reemplazará a Brave cuando se tenga la API key
"""

import os
import sys
import json
import urllib.request
import urllib.parse
from pathlib import Path

# Config
TAVILY_API_KEY = os.environ.get("TAVILY_API_KEY", "")
TAVILY_API_URL = "https://api.tavily.com/search"
CACHE_DIR = Path("~/.cache/tavily").expanduser()
CACHE_DIR.mkdir(parents=True, exist_ok=True)

class TavilySearch:
    """Cliente de búsqueda Tavily para agents"""
    
    def __init__(self, api_key=None):
        self.api_key = api_key or TAVILY_API_KEY
        self.enabled = bool(self.api_key)
    
    def search(self, query, **kwargs):
        """
        Realizar búsqueda con Tavily
        
        Args:
            query: Query de búsqueda
            search_depth: "basic" o "advanced"
            include_answer: Incluir respuesta generada
            include_images: Incluir imágenes
            max_results: Número máximo de resultados (default: 5)
        """
        if not self.enabled:
            return {
                "error": "TAVILY_API_KEY no configurada",
                "message": "Obtén tu API key en https://tavily.com",
                "fallback": "Usando Brave Search por ahora"
            }
        
        # Parámetros por defecto
        params = {
            "api_key": self.api_key,
            "query": query,
            "search_depth": kwargs.get("search_depth", "basic"),
            "include_answer": kwargs.get("include_answer", False),
            "include_images": kwargs.get("include_images", False),
            "max_results": kwargs.get("max_results", 5)
        }
        
        try:
            data = json.dumps(params).encode('utf-8')
            req = urllib.request.Request(
                TAVILY_API_URL,
                data=data,
                headers={'Content-Type': 'application/json'},
                method='POST'
            )
            
            with urllib.request.urlopen(req, timeout=30) as response:
                result = json.loads(response.read().decode('utf-8'))
                return result
                
        except Exception as e:
            return {
                "error": str(e),
                "fallback": "Usando Brave Search"
            }
    
    def format_results(self, results):
        """Formatear resultados para mostrar"""
        if "error" in results:
            print(f"❌ Error: {results['error']}")
            if "message" in results:
                print(f"💡 {results['message']}")
            return
        
        print(f"🔍 Resultados de búsqueda:")
        print("=" * 60)
        
        # Respuesta generada (si está incluida)
        if "answer" in results:
            print(f"\n🤖 Respuesta:\n{results['answer']}\n")
        
        # Resultados
        for i, result in enumerate(results.get("results", []), 1):
            print(f"{i}. {result.get('title', 'N/A')}")
            print(f"   {result.get('url', 'N/A')}")
            print(f"   {result.get('content', 'N/A')[:150]}...")
            print()

def setup_config():
    """Configurar API key"""
    print("🔧 Configuración de Tavily Search")
    print("")
    print("1. Ve a https://tavily.com y crea una cuenta")
    print("2. Obtén tu API key")
    print("3. Agrega a tu ~/.clawdbot/.env:")
    print("")
    print("   TAVILY_API_KEY=tu_api_key_aqui")
    print("")
    print("4. Recarga la configuración:")
    print("   source ~/.clawdbot/.env")

def compare_with_brave(query):
    """Comparar resultados Tavily vs Brave (para testing)"""
    print(f"🔄 Comparando búsquedas para: '{query}'")
    print("")
    
    # Simular resultado Tavily (estructura)
    print("📊 Estructura de respuesta Tavily:")
    print("  ✅ Respuesta generada por IA")
    print("  ✅ Fuentes citadas automáticamente")
    print("  ✅ Contenido completo scrapeado")
    print("  ✅ Imágenes relacionadas (opcional)")
    print("")
    
    print("📊 Estructura de respuesta Brave:")
    print("  ✅ Título y URL")
    print("  ✅ Snippet básico")
    print("  ❌ Sin respuesta generada")
    print("  ❌ Sin citas automáticas")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("🔍 Tavily Search - Preparado para uso")
        print("")
        print("Estado actual:", "✅ Configurado" if TAVILY_API_KEY else "⚠️  Sin API key")
        print("")
        print("Uso:")
        print("  tavily search 'query'        - Buscar")
        print("  tavily setup                 - Configurar API key")
        print("  tavily compare 'query'       - Comparar con Brave")
        print("")
        print("Cuando tengas la API key, reemplaza:")
        print("  web_search → tavily_search")
        sys.exit(0)
    
    command = sys.argv[1]
    
    if command == "search":
        query = " ".join(sys.argv[2:])
        tavily = TavilySearch()
        results = tavily.search(query)
        tavily.format_results(results)
    
    elif command == "setup":
        setup_config()
    
    elif command == "compare":
        query = " ".join(sys.argv[2:])
        compare_with_brave(query)
    
    elif command == "status":
        print("🔍 Tavily Search Status")
        print(f"  API Key: {'✅ Configurada' if TAVILY_API_KEY else '⚠️  No configurada'}")
        print(f"  Cache: {CACHE_DIR}")
        print("")
        print("Para activar:")
        print("  export TAVILY_API_KEY=tu_key")
    
    else:
        print(f"❌ Comando desconocido: {command}")
