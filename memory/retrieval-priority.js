#!/usr/bin/env node
/**
 * retrieval-priority.js - Sistema de priorización de memoria
 * Decay factor: prioriza memoria por recencia y frecuencia
 */

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join } from 'path';

const PRIORITY_FILE = process.env.PRIORITY_FILE || './memory/retrieval-priority.json';

/**
 * Carga la configuración de prioridad
 */
export function loadPriorityConfig() {
  if (!existsSync(PRIORITY_FILE)) {
    return createDefaultConfig();
  }
  return JSON.parse(readFileSync(PRIORITY_FILE, 'utf-8'));
}

/**
 * Guarda la configuración de prioridad
 */
export function savePriorityConfig(config) {
  config.lastUpdated = new Date().toISOString();
  writeFileSync(PRIORITY_FILE, JSON.stringify(config, null, 2));
}

/**
 * Crea configuración por defecto
 */
export function createDefaultConfig() {
  return {
    version: "1.0",
    description: "Sistema de priorización de memoria por recencia y frecuencia",
    lastUpdated: new Date().toISOString(),
    config: {
      decayFactor: 0.95,
      recencyWeight: 0.6,
      frequencyWeight: 0.4,
      maxAgeDays: 90,
      boostThreshold: 5
    },
    accessLog: {},
    priorityScores: {},
    boostedTerms: []
  };
}

/**
 * Registra acceso a un archivo de memoria
 */
export function recordAccess(filePath, context = '') {
  const config = loadPriorityConfig();
  const now = new Date().toISOString();
  
  if (!config.accessLog[filePath]) {
    config.accessLog[filePath] = {
      firstAccess: now,
      accessCount: 0,
      lastAccess: now,
      contexts: []
    };
  }
  
  config.accessLog[filePath].accessCount++;
  config.accessLog[filePath].lastAccess = now;
  
  if (context && !config.accessLog[filePath].contexts.includes(context)) {
    config.accessLog[filePath].contexts.push(context);
  }
  
  // Recalcular score
  config.priorityScores[filePath] = calculatePriorityScore(filePath, config);
  
  savePriorityConfig(config);
  return config.priorityScores[filePath];
}

/**
 * Calcula el score de prioridad para un archivo
 * Fórmula: score = (recency_score ^ decay) * recencyWeight + (frequency_score) * frequencyWeight
 */
export function calculatePriorityScore(filePath, config) {
  const access = config.accessLog[filePath];
  if (!access) return 0;
  
  const now = new Date();
  const lastAccess = new Date(access.lastAccess);
  const firstAccess = new Date(access.firstAccess);
  
  // Recency score (0-1, más alto = más reciente)
  const daysSinceAccess = (now - lastAccess) / (1000 * 60 * 60 * 24);
  const recencyScore = Math.max(0, 1 - (daysSinceAccess / config.config.maxAgeDays));
  
  // Frequency score (normalizado, boost después de threshold)
  let frequencyScore = Math.min(1, access.accessCount / config.config.boostThreshold);
  
  // Decay factor aplicado a recencia
  const decayedRecency = Math.pow(recencyScore, config.config.decayFactor);
  
  // Score ponderado
  const score = (decayedRecency * config.config.recencyWeight) + 
                (frequencyScore * config.config.frequencyWeight);
  
  return Math.round(score * 100) / 100;
}

/**
 * Obtiene archivos ordenados por prioridad
 */
export function getPrioritizedFiles(limit = 10) {
  const config = loadPriorityConfig();
  
  const files = Object.entries(config.priorityScores)
    .map(([path, score]) => ({
      path,
      score,
      accessCount: config.accessLog[path]?.accessCount || 0,
      lastAccess: config.accessLog[path]?.lastAccess,
      contexts: config.accessLog[path]?.contexts || []
    }))
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);
  
  return files;
}

/**
 * Boost manual para términos importantes
 */
export function boostTerm(term, weight = 1.5) {
  const config = loadPriorityConfig();
  
  if (!config.boostedTerms.find(b => b.term === term)) {
    config.boostedTerms.push({ term, weight, addedAt: new Date().toISOString() });
    savePriorityConfig(config);
  }
}

/**
 * Re-ranquea resultados de búsqueda aplicando prioridad
 */
export function rerankResults(results, query) {
  const config = loadPriorityConfig();
  
  return results.map(result => {
    const filePath = result.path || result.file;
    const priorityScore = config.priorityScores[filePath] || 0;
    
    // Combinar score original con prioridad
    const originalScore = result.score || 1;
    const boostedScore = originalScore * (1 + priorityScore);
    
    return {
      ...result,
      originalScore,
      priorityScore,
      finalScore: Math.round(boostedScore * 100) / 100
    };
  }).sort((a, b) => b.finalScore - a.finalScore);
}

// CLI
const args = process.argv.slice(2);
const command = args[0];

switch (command) {
  case 'record':
    const file = args[1];
    const context = args[2] || '';
    if (!file) {
      console.error('Usage: retrieval-priority record <file> [context]');
      process.exit(1);
    }
    const score = recordAccess(file, context);
    console.log(`Recorded access to ${file}: score=${score}`);
    break;
    
  case 'list':
    const limit = parseInt(args[1]) || 10;
    const files = getPrioritizedFiles(limit);
    console.log('Top prioritized files:');
    files.forEach((f, i) => {
      console.log(`${i+1}. ${f.path}`);
      console.log(`   Score: ${f.score} | Access: ${f.accessCount}x | Last: ${f.lastAccess?.slice(0,10)}`);
    });
    break;
    
  case 'boost':
    const term = args[1];
    const weight = parseFloat(args[2]) || 1.5;
    if (!term) {
      console.error('Usage: retrieval-priority boost <term> [weight]');
      process.exit(1);
    }
    boostTerm(term, weight);
    console.log(`Boosted term '${term}' with weight ${weight}`);
    break;
    
  case 'init':
    savePriorityConfig(createDefaultConfig());
    console.log('Initialized priority config at', PRIORITY_FILE);
    break;
    
  default:
    console.log('Retrieval Priority System');
    console.log('');
    console.log('Commands:');
    console.log('  retrieval-priority init');
    console.log('  retrieval-priority record <file> [context]');
    console.log('  retrieval-priority list [limit]');
    console.log('  retrieval-priority boost <term> [weight]');
    console.log('');
    console.log('API:');
    console.log('  recordAccess(file, context) - Registra acceso');
    console.log('  getPrioritizedFiles(limit) - Obtiene archivos prioritarios');
    console.log('  rerankResults(results) - Re-ranquea con prioridad');
    break;
}
