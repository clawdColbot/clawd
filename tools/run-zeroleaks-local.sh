#!/bin/bash
#
set -euo pipefail
# run-zeroleaks-local.sh - Ejecutar ZeroLeaks con Ollama local (100% gratis)
#

ZERROLEAKS_DIR="${HOME}/clawd/node_modules/zeroleaks"
CONFIG_DIR="${HOME}/.config/zeroleaks"
mkdir -p "$CONFIG_DIR"

# Configurar ZeroLeaks para usar Ollama
cat > "$CONFIG_DIR/config.json" << 'EOF'
{
  "llm": {
    "provider": "openai-compatible",
    "baseUrl": "http://localhost:11434/v1",
    "apiKey": "ollama",
    "model": "llama3.1:latest"
  },
  "scan": {
    "maxTurns": 15,
    "maxTreeDepth": 3,
    "branchingFactor": 2,
    "enableCrescendo": true,
    "enableManyShot": true,
    "enableBestOfN": false
  }
}
EOF

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     🔒 ZeroLeaks con Ollama Local                          ║"
echo "║     100% Gratis - Usando tu GPU                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Verificar Ollama está corriendo
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "⚠️  Ollama no está corriendo. Iniciando..."
    ollama serve &
    sleep 3
fi

# Verificar modelo existe
if ! ollama list | grep -q "llama3.1"; then
    echo "📥 Descargando modelo llama3.1..."
    ollama pull llama3.1:latest
fi

echo "✅ Configuración lista:"
echo "   - LLM: llama3.1:latest (local)"
echo "   - Provider: Ollama"
echo "   - Costo: $0"
echo ""

echo "🎯 Archivos a testear:"
echo "   1. ~/clawd/SOUL.md (system prompt)"
echo "   2. ~/clawd/docs/SECURITY_ENVIRONMENT_VARIABLES.md"
echo ""

# Ejecutar ZeroLeaks
echo "🔍 Iniciando scan de seguridad..."
echo "   (Este proceso puede tomar 5-15 minutos dependiendo de tu GPU)"
echo ""

cd ~/clawd

# Test 1: SOUL.md
echo "════════════════════════════════════════════════════════════"
echo "📄 TEST 1: SOUL.md (System Identity)"
echo "════════════════════════════════════════════════════════════"
node -e "
const { runSecurityScan } = require('zeroleaks');
const fs = require('fs');

const systemPrompt = fs.readFileSync('SOUL.md', 'utf8');

runSecurityScan(systemPrompt, {
  maxTurns: 10,
  apiKey: 'ollama',
  onProgress: (turn, max) => console.log(\`Turn \${turn}/\${max}\`),
  onFinding: (finding) => console.log(\`🚨 FINDING: \${finding.severity} - \${finding.technique}\`)
}).then(result => {
  console.log('\\n✅ Scan complete!');
  console.log('Vulnerability:', result.overallVulnerability);
  console.log('Score:', result.overallScore, '/100');
  fs.writeFileSync('zeroleaks-soul-result.json', JSON.stringify(result, null, 2));
}).catch(err => {
  console.error('❌ Error:', err.message);
});
" 2>&1

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ Test completado"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📊 Resultados guardados en:"
echo "   ~/clawd/zeroleaks-soul-result.json"
echo ""
echo "🎉 ZeroLeaks + Ollama = 100% Gratis, 100% Privado"
