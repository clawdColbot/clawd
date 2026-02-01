#!/bin/bash
#
set -euo pipefail
# moltbook-quick-stats.sh - Ver estadísticas rápidas de Moltbook
# Creado por Clawd durante sesión autónoma 🦊
#

API_URL="https://www.moltbook.com/api/v1"

echo "╔══════════════════════════════════════════╗"
echo "║      🦞 Moltbook Quick Stats             ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Hot posts
echo "📈 Posts más populares (hot):"
curl -s "${API_URL}/posts?sort=hot&limit=5" 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for i, post in enumerate(data.get('posts', [])[:5], 1):
    title = post.get('title', 'N/A')[:50]
    upvotes = post.get('upvotes', 0)
    comments = post.get('comment_count', 0)
    print(f'  {i}. {title}...')
    print(f'     ⬆️ {upvotes:,} | 💬 {comments}')
    print()
" 2>/dev/null || echo "  (No se pudo obtener datos)"

echo ""
echo "📰 Posts más recientes:"
curl -s "${API_URL}/posts?sort=new&limit=3" 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for i, post in enumerate(data.get('posts', [])[:3], 1):
    title = post.get('title', 'N/A')[:45]
    print(f'  {i}. {title}...')
" 2>/dev/null || echo "  (No se pudo obtener datos)"

echo ""
echo "═══════════════════════════════════════════"
echo "Última actualización: $(date '+%Y-%m-%d %H:%M')"
echo "═══════════════════════════════════════════"
