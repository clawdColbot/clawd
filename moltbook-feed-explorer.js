#!/usr/bin/env node
/**
 * moltbook-feed-explorer.js - Explorador de feed de Moltbook
 * Obtiene perfil, posts populares, posts específicos y búsquedas
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

const API_KEY = 'moltbook_sk_KN6zd5EdENIzwiSoQks5FMcJkjdE_ll3';
const API_BASE = 'www.moltbook.com';  // IMPORTANT: must use www
const OUTPUT_FILE = path.join(process.env.HOME, 'clawd/memory/moltbook-feed.md');

// Configuración de retries
const MAX_RETRIES = 3;
const TIMEOUT_MS = 10000; // 10 segundos

// Resultados acumulados
const results = {
  timestamp: new Date().toISOString(),
  profile: null,
  hotPosts: [],
  blueprintPost: null,
  searchResults: {
    skills: [],
    tools: [],
    collaboration: []
  }
};

/**
 * HTTP request con timeout y retries
 */
function apiRequest(endpoint, method = 'GET', data = null, attempt = 1) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: API_BASE,
      path: `/api/v1${endpoint}`,
      method: method,
      timeout: TIMEOUT_MS,
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json',
        'User-Agent': 'ClawdBot/1.0'
      }
    };

    // Para GET, añadir query params
    if (method === 'GET' && data) {
      const queryString = Object.entries(data)
        .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
        .join('&');
      options.path += `?${queryString}`;
    }

    const req = https.request(options, (res) => {
      let responseData = '';
      res.on('data', chunk => responseData += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(responseData);
          resolve(json);
        } catch (e) {
          resolve({ error: 'Parse error', raw: responseData });
        }
      });
    });

    req.on('error', (err) => {
      if (attempt < MAX_RETRIES) {
        console.log(`   ⚠️ Retry ${attempt}/${MAX_RETRIES} for ${endpoint}...`);
        setTimeout(() => {
          apiRequest(endpoint, method, data, attempt + 1)
            .then(resolve)
            .catch(reject);
        }, 1000 * attempt); // Exponential backoff
      } else {
        reject(err);
      }
    });

    req.on('timeout', () => {
      req.destroy();
      if (attempt < MAX_RETRIES) {
        console.log(`   ⏱️ Timeout, retry ${attempt}/${MAX_RETRIES} for ${endpoint}...`);
        setTimeout(() => {
          apiRequest(endpoint, method, data, attempt + 1)
            .then(resolve)
            .catch(reject);
        }, 1000 * attempt);
      } else {
        reject(new Error('Request timeout'));
      }
    });

    if (method !== 'GET' && data) {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

/**
 * Obtener perfil completo
 */
async function getProfile() {
  console.log('👤 Obteniendo perfil...');
  try {
    // Intentar diferentes endpoints comunes
    const endpoints = ['/me', '/profile', '/users/ClawdColombia'];
    
    for (const endpoint of endpoints) {
      try {
        const result = await apiRequest(endpoint);
        if (!result.error) {
          console.log('   ✅ Perfil obtenido');
          return result;
        }
      } catch (e) {
        continue;
      }
    }
    
    return { error: 'No se pudo obtener perfil' };
  } catch (e) {
    console.error('   ❌ Error:', e.message);
    return { error: e.message };
  }
}

/**
 * Obtener posts populares (hot)
 */
async function getHotPosts() {
  console.log('🔥 Obteniendo posts populares...');
  try {
    const result = await apiRequest('/posts', 'GET', { sort: 'hot', limit: 20 });
    
    if (result.posts || result.data) {
      const posts = result.posts || result.data || [];
      console.log(`   ✅ ${posts.length} posts populares obtenidos`);
      return posts;
    }
    
    // Intentar endpoint alternativo
    const result2 = await apiRequest('/feed', 'GET', { sort: 'hot', limit: 20 });
    const posts = result2.posts || result2.data || [];
    console.log(`   ✅ ${posts.length} posts obtenidos (alt endpoint)`);
    return posts;
  } catch (e) {
    console.error('   ❌ Error:', e.message);
    return [];
  }
}

/**
 * Obtener post específico sobre blueprint de memoria
 */
async function getBlueprintPost(postId) {
  console.log(`📝 Obteniendo post ${postId}...`);
  try {
    const result = await apiRequest(`/posts/${postId}`);
    
    if (!result.error) {
      console.log('   ✅ Post obtenido');
      return result;
    }
    
    return { error: 'Post no encontrado' };
  } catch (e) {
    console.error('   ❌ Error:', e.message);
    return { error: e.message };
  }
}

/**
 * Buscar posts por keyword
 */
async function searchPosts(query, limit = 10) {
  console.log(`🔍 Buscando "${query}"...`);
  try {
    // Intentar endpoint de búsqueda
    const result = await apiRequest('/posts/search', 'GET', { q: query, limit });
    
    if (result.posts || result.data || result.results) {
      const posts = result.posts || result.data || result.results || [];
      console.log(`   ✅ ${posts.length} resultados`);
      return posts;
    }
    
    // Fallback: buscar en feed y filtrar
    const feed = await apiRequest('/posts', 'GET', { sort: 'new', limit: 50 });
    const allPosts = feed.posts || feed.data || [];
    
    const filtered = allPosts.filter(post => {
      const text = `${post.title || ''} ${post.content || ''}`.toLowerCase();
      return text.includes(query.toLowerCase());
    });
    
    console.log(`   ✅ ${filtered.length} resultados (filtrado local)`);
    return filtered.slice(0, limit);
  } catch (e) {
    console.error('   ❌ Error:', e.message);
    return [];
  }
}

/**
 * Formatear un post para markdown
 */
function formatPost(post, includeContent = true) {
  const id = post.id || post._id || 'unknown';
  const title = post.title || 'Sin título';
  const author = post.author_name || post.author?.name || post.author || 'Anónimo';
  const created = post.created_at ? new Date(post.created_at).toLocaleDateString() : '?';
  const votes = post.votes || post.upvotes || post.score || 0;
  const comments = post.comment_count || post.comments || 0;
  
  let md = `### ${title}\n\n`;
  md += `- **Autor:** @${author}\n`;
  md += `- **ID:** ${id}\n`;
  md += `- **Fecha:** ${created}\n`;
  md += `- **Votos:** ${votes} | **Comentarios:** ${comments}\n`;
  
  if (includeContent && post.content) {
    md += `\n**Contenido:**\n\n${post.content.substring(0, 500)}${post.content.length > 500 ? '...' : ''}\n`;
  }
  
  if (post.url) {
    md += `\n🔗 ${post.url}\n`;
  }
  
  md += '\n---\n\n';
  return md;
}

/**
 * Formatear perfil para markdown
 */
function formatProfile(profile) {
  let md = `## 👤 Perfil de ClawdColombia\n\n`;
  
  if (profile.error) {
    md += `⚠️ ${profile.error}\n\n`;
    return md;
  }
  
  const name = profile.name || profile.username || profile.display_name || 'ClawdColombia';
  const bio = profile.bio || profile.description || profile.about || 'Sin biografía';
  const followers = profile.followers || profile.follower_count || 0;
  const following = profile.following || profile.following_count || 0;
  const posts = profile.posts_count || profile.post_count || 0;
  
  md += `**Nombre:** ${name}\n\n`;
  md += `**Bio:** ${bio}\n\n`;
  md += `- **Seguidores:** ${followers}\n`;
  md += `- **Siguiendo:** ${following}\n`;
  md += `- **Posts:** ${posts}\n\n`;
  
  if (profile.wallets) {
    md += `### 💰 Wallets\n\n`;
    if (profile.wallets.ethereum) md += `- **ETH:** ${profile.wallets.ethereum}\n`;
    if (profile.wallets.bitcoin) md += `- **BTC:** ${profile.wallets.bitcoin}\n`;
    if (profile.wallets.solana) md += `- **SOL:** ${profile.wallets.solana}\n`;
    md += '\n';
  }
  
  md += '---\n\n';
  return md;
}

/**
 * Generar el archivo markdown final
 */
function generateMarkdown() {
  let md = `# 🦊 Moltbook Feed Explorer\n\n`;
  md += `*Generado: ${new Date(results.timestamp).toLocaleString()}*\n\n`;
  
  // Perfil
  md += formatProfile(results.profile);
  
  // Posts populares
  md += `## 🔥 Posts Populares (Hot)\n\n`;
  if (results.hotPosts.length === 0) {
    md += '*No se encontraron posts populares*\n\n';
  } else {
    results.hotPosts.forEach(post => {
      md += formatPost(post, false);
    });
  }
  
  // Post blueprint
  md += `## 📝 Post: Blueprint de Memoria\n\n`;
  if (results.blueprintPost && !results.blueprintPost.error) {
    md += formatPost(results.blueprintPost, true);
  } else {
    md += `⚠️ No se pudo obtener el post\n\n`;
    if (results.blueprintPost?.error) {
      md += `*Error: ${results.blueprintPost.error}*\n\n`;
    }
  }
  
  // Búsquedas
  md += `## 🔍 Búsquedas\n\n`;
  
  md += `### Skills\n\n`;
  if (results.searchResults.skills.length === 0) {
    md += '*Sin resultados*\n\n';
  } else {
    results.searchResults.skills.forEach(post => {
      md += formatPost(post, false);
    });
  }
  
  md += `### Herramientas (Tools)\n\n`;
  if (results.searchResults.tools.length === 0) {
    md += '*Sin resultados*\n\n';
  } else {
    results.searchResults.tools.forEach(post => {
      md += formatPost(post, false);
    });
  }
  
  md += `### Colaboración\n\n`;
  if (results.searchResults.collaboration.length === 0) {
    md += '*Sin resultados*\n\n';
  } else {
    results.searchResults.collaboration.forEach(post => {
      md += formatPost(post, false);
    });
  }
  
  md += `---\n\n`;
  md += `*Fin del reporte*\n`;
  
  return md;
}

/**
 * Función principal
 */
async function main() {
  console.log('🦊 Moltbook Feed Explorer\n');
  console.log(`📅 ${new Date().toISOString()}\n`);
  
  // 1. Obtener perfil
  results.profile = await getProfile();
  
  // 2. Obtener posts populares
  results.hotPosts = await getHotPosts();
  
  // 3. Obtener post blueprint
  results.blueprintPost = await getBlueprintPost('791703f2-d253-4c08-873f-470063f4d158');
  
  // 4. Buscar posts
  console.log('\n🔍 Iniciando búsquedas...\n');
  results.searchResults.skills = await searchPosts('skill', 10);
  results.searchResults.tools = await searchPosts('tool', 10);
  results.searchResults.collaboration = await searchPosts('collaboration', 10);
  
  // Generar y guardar markdown
  console.log('\n📝 Generando reporte...');
  const markdown = generateMarkdown();
  
  fs.writeFileSync(OUTPUT_FILE, markdown);
  console.log(`   ✅ Guardado en: ${OUTPUT_FILE}`);
  
  // Resumen
  console.log('\n📊 Resumen:');
  console.log(`   - Perfil: ${results.profile.error ? '❌' : '✅'}`);
  console.log(`   - Hot posts: ${results.hotPosts.length}`);
  console.log(`   - Blueprint post: ${results.blueprintPost?.error ? '❌' : '✅'}`);
  console.log(`   - Skills: ${results.searchResults.skills.length}`);
  console.log(`   - Tools: ${results.searchResults.tools.length}`);
  console.log(`   - Collaboration: ${results.searchResults.collaboration.length}`);
  
  console.log('\n✅ Exploración completa');
}

main().catch(e => {
  console.error('Error fatal:', e);
  process.exit(1);
});
