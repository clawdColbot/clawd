const https = require('https');
const fs = require('fs');
const path = require('path');

/**
 * Moltbook Scraper - Indexa agents de Moltbook
 * Extrae perfiles, skills y metadata
 */

const API_KEY = 'moltbook_sk_KN6zd5EdENIzwiSoQks5FMcJkjdE_ll3';
const DB_FILE = path.join(__dirname, '../database/agents.db');

// HTTP request helper
function apiRequest(endpoint) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'moltbook.com',
      path: `/api/v1${endpoint}`,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json'
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          resolve({ error: 'Parse error', raw: data.substring(0, 200) });
        }
      });
    });

    req.on('error', reject);
    req.end();
  });
}

// Extraer skills de una biounction extractSkills(description) {
  const skills = [];
  const text = description.toLowerCase();
  
  // Keywords de skills comunes en agents
  const skillKeywords = {
    'typescript': ['typescript', 'ts', 'node.js', 'nodejs'],
    'python': ['python', 'py', 'django', 'flask'],
    'rust': ['rust', 'cargo'],
    'go': ['golang', 'go lang'],
    'security': ['security', 'seguridad', 'audit', 'hardening'],
    'devops': ['devops', 'docker', 'kubernetes', 'k8s', 'ci/cd'],
    'database': ['database', 'sql', 'postgres', 'mongodb', 'sqlite'],
    'web-scraping': ['scraping', 'crawler', 'puppeteer', 'selenium'],
    'ai/ml': ['machine learning', 'ml', 'ai', 'neural', 'gpt'],
    'automation': ['automation', 'automate', 'script', 'bot'],
    'monitoring': ['monitoring', 'observability', 'logs', 'metrics'],
    'api': ['api', 'rest', 'graphql', 'webhook'],
    'frontend': ['frontend', 'react', 'vue', 'angular', 'html', 'css'],
    'backend': ['backend', 'server', 'api'],
    'testing': ['testing', 'qa', 'test', 'cypress', 'jest'],
    'documentation': ['documentation', 'docs', 'technical writing'],
    'communication': ['communication', 'slack', 'discord', 'telegram'],
    'data-analysis': ['data analysis', 'analytics', 'pandas', 'numpy'],
    'blockchain': ['blockchain', 'web3', 'ethereum', 'solana', 'crypto'],
    'cloud': ['aws', 'gcp', 'azure', 'cloud', 'serverless']
  };
  
  for (const [skill, keywords] of Object.entries(skillKeywords)) {
    if (keywords.some(kw => text.includes(kw))) {
      skills.push(skill);
    }
  }
  
  return [...new Set(skills)]; // Eliminar duplicados
}

// Extraer especialidad principal
function extractSpecialty(description) {
  const text = description.toLowerCase();
  
  if (text.includes('security') || text.includes('audit')) return 'security';
  if (text.includes('devops') || text.includes('infrastructure')) return 'devops';
  if (text.includes('database') || text.includes('data')) return 'data';
  if (text.includes('frontend') || text.includes('ui') || text.includes('design')) return 'frontend';
  if (text.includes('backend') || text.includes('api')) return 'backend';
  if (text.includes('automation') || text.includes('bot')) return 'automation';
  if (text.includes('scraping') || text.includes('crawl')) return 'scraping';
  if (text.includes('testing') || text.includes('qa')) return 'qa';
  if (text.includes('writing') || text.includes('content')) return 'content';
  if (text.includes('research') || text.includes('analysis')) return 'research';
  
  return 'general';
}

// Obtener lista de agents
async function getAgents(limit = 100) {
  console.log('🔍 Obteniendo agents de Moltbook...');
  
  const agents = [];
  let offset = 0;
  let hasMore = true;
  
  while (hasMore && agents.length < limit) {
    const result = await apiRequest(`/agents?limit=50&offset=${offset}`);
    
    if (result.agents && result.agents.length > 0) {
      agents.push(...result.agents);
      offset += result.agents.length;
      console.log(`   ${agents.length} agents encontrados...`);
    } else {
      hasMore = false;
    }
    
    // Rate limiting
    await new Promise(r => setTimeout(r, 1000));
  }
  
  return agents.slice(0, limit);
}

// Obtener perfil detallado de un agent
async function getAgentProfile(name) {
  try {
    const result = await apiRequest(`/agents/profile?name=${encodeURIComponent(name)}`);
    return result.agent || null;
  } catch (e) {
    console.error(`   Error obteniendo perfil de ${name}:`, e.message);
    return null;
  }
}

// Procesar y enriquecer datos de agents
async function processAgents(rawAgents) {
  console.log('🔄 Procesando datos de agents...');
  
  const processed = [];
  
  for (const agent of rawAgents) {
    console.log(`   Procesando: ${agent.name}`);
    
    // Obtener perfil completo si está disponible
    const profile = await getAgentProfile(agent.name);
    
    const description = agent.description || profile?.description || '';
    
    const processedAgent = {
      name: agent.name,
      description: description,
      source: 'moltbook',
      source_url: `https://moltbook.com/u/${agent.name}`,
      karma: agent.karma || 0,
      follower_count: agent.follower_count || 0,
      following_count: agent.following_count || 0,
      is_claimed: agent.is_claimed || false,
      is_active: agent.is_active || false,
      created_at: agent.created_at,
      last_active: agent.last_active,
      skills: extractSkills(description),
      specialty: extractSpecialty(description),
      human: profile?.owner ? {
        x_handle: profile.owner.x_handle,
        x_name: profile.owner.x_name,
        x_followers: profile.owner.x_follower_count,
        x_verified: profile.owner.x_verified
      } : null,
      scraped_at: new Date().toISOString()
    };
    
    processed.push(processedAgent);
    
    // Rate limiting amable
    await new Promise(r => setTimeout(r, 500));
  }
  
  return processed;
}

// Guardar datos en JSON (mientras no tengamos SQLite)
function saveData(agents) {
  const outputFile = path.join(__dirname, '../database/agents-data.json');
  
  // Cargar datos existentes
  let existing = [];
  if (fs.existsSync(outputFile)) {
    existing = JSON.parse(fs.readFileSync(outputFile, 'utf8'));
  }
  
  // Merge: actualizar existentes, agregar nuevos
  const agentMap = new Map(existing.map(a => [a.name, a]));
  
  for (const agent of agents) {
    agentMap.set(agent.name, agent);
  }
  
  const merged = Array.from(agentMap.values());
  
  fs.writeFileSync(outputFile, JSON.stringify(merged, null, 2));
  console.log(`💾 ${merged.length} agents guardados en ${outputFile}`);
  
  return merged;
}

// Generar reporte de estadísticas
function generateStats(agents) {
  const stats = {
    total: agents.length,
    by_specialty: {},
    by_skill: {},
    claimed: agents.filter(a => a.is_claimed).length,
    active_recently: agents.filter(a => {
      const lastActive = new Date(a.last_active);
      const weekAgo = new Date();
      weekAgo.setDate(weekAgo.getDate() - 7);
      return lastActive > weekAgo;
    }).length,
    with_human: agents.filter(a => a.human).length
  };
  
  // Contar por especialidad
  for (const agent of agents) {
    const spec = agent.specialty;
    stats.by_specialty[spec] = (stats.by_specialty[spec] || 0) + 1;
    
    // Contar skills
    for (const skill of agent.skills) {
      stats.by_skill[skill] = (stats.by_skill[skill] || 0) + 1;
    }
  }
  
  // Ordenar skills por frecuencia
  stats.by_skill = Object.entries(stats.by_skill)
    .sort((a, b) => b[1] - a[1])
    .reduce((acc, [k, v]) => ({ ...acc, [k]: v }), {});
  
  return stats;
}

// Función principal
async function main() {
  console.log('🚀 Moltbook Scraper v1.0\n');
  
  try {
    // Obtener agents
    const rawAgents = await getAgents(50); // Limitar a 50 para empezar
    console.log(`✅ ${rawAgents.length} agents obtenidos\n`);
    
    if (rawAgents.length === 0) {
      console.log('⚠️ No se encontraron agents');
      return;
    }
    
    // Procesar
    const processedAgents = await processAgents(rawAgents);
    
    // Guardar
    const savedAgents = saveData(processedAgents);
    
    // Estadísticas
    const stats = generateStats(savedAgents);
    
    console.log('\n📊 Estadísticas:');
    console.log(`   Total agents: ${stats.total}`);
    console.log(`   Claimed: ${stats.claimed}`);
    console.log(`   Active (7 días): ${stats.active_recently}`);
    console.log(`   Con human verificado: ${stats.with_human}`);
    console.log('\n   Top especialidades:');
    Object.entries(stats.by_specialty)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .forEach(([spec, count]) => console.log(`      ${spec}: ${count}`));
    console.log('\n   Top skills:');
    Object.entries(stats.by_skill)
      .slice(0, 5)
      .forEach(([skill, count]) => console.log(`      ${skill}: ${count}`));
    
    console.log('\n✅ Scrape completo');
    
  } catch (e) {
    console.error('❌ Error:', e.message);
    process.exit(1);
  }
}

// Si se ejecuta directamente
if (require.main === module) {
  main();
}

module.exports = { getAgents, processAgents, extractSkills };
