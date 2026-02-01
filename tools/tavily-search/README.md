# 🔍 Tavily Search Integration

Sistema de búsqueda preparado para reemplazar Brave Search cuando se obtenga la API key.

## 🚀 Ventajas sobre Brave

| Característica | Brave | Tavily |
|---------------|-------|--------|
| Respuesta generada | ❌ | ✅ |
| Citaciones automáticas | ❌ | ✅ |
| Contenido scrapeado | ❌ | ✅ |
| Diseñado para LLMs | ❌ | ✅ |
| Imágenes incluidas | ❌ | ✅ |
| Precio | Free (limitado) | Free tier generoso |

## 📦 Instalación

```bash
chmod +x ~/clawd/tools/tavily-search/tavily_search.py
ln -s ~/clawd/tools/tavily-search/tavily_search.py ~/.local/bin/tavily
```

## 🔧 Configuración

### 1. Obtener API Key
```bash
# Visita https://tavily.com
# Crea cuenta gratuita
# Copia tu API key
```

### 2. Configurar
```bash
# Agregar a ~/.clawdbot/.env
export TAVILY_API_KEY="tvly-tu-api-key-aqui"

# Recargar
source ~/.clawdbot/.env
```

### 3. Verificar
```bash
tavily status
```

## 💻 Uso

### Búsqueda básica
```bash
tavily search "inteligencia artificial 2025"
```

### En código Python
```python
from tavily_search import TavilySearch

tavily = TavilySearch()
results = tavily.search(
    query="machine learning trends",
    search_depth="advanced",
    include_answer=True,
    max_results=10
)
```

### Comparar con Brave
```bash
tavily compare "query de prueba"
```

## 🔌 Integración con Clawdbot

Para reemplazar Brave en Clawdbot:

```python
# En tu código de agent
from tools.tavily-search.tavily_search import TavilySearch

tavily = TavilySearch()
results = tavily.search(query)

if "error" not in results:
    # Usar resultados de Tavily
    formatted = tavily.format_results(results)
else:
    # Fallback a Brave
    web_search(query)
```

## 📊 Migración desde Brave

### Cambios necesarios:

1. **En `TOOLS.md`:**
   - Agregar dependencia: `pip install tavily-python` (opcional)
   - Documentar nueva variable `TAVILY_API_KEY`

2. **En código:**
   ```python
   # Antes
   from web_search import web_search
   
   # Después
   try:
       from tavily_search import TavilySearch
       tavily = TavilySearch()
       results = tavily.search(query)
   except:
       # Fallback a Brave
       from web_search import web_search
       results = web_search(query)
   ```

3. **En configuración:**
   - Agregar `TAVILY_API_KEY` a `.env`
   - Actualizar `SECURITY_ENVIRONMENT_VARIABLES.md`

## 💰 Pricing

- **Free tier:** 1,000 llamadas/mes
- **Pro:** $0.025/llamada (después de free tier)
- **Enterprise:** Contactar

## 📝 TODO

- [ ] Obtener API key de Tavily
- [ ] Probar integración
- [ ] Actualizar HEARTBEAT.md con checks de Tavily
- [ ] Crear fallback automático Brave → Tavily
- [ ] Documentar en MEMORY.md
