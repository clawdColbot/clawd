#!/usr/bin/env node
/**
 * checkpoint.js - Sistema de checkpointing proactivo
 * Detecta tokens altos (>70%) y guarda resumen antes de compresión
 */

const { existsSync, writeFileSync, mkdirSync, readFileSync } = require('fs');
const { join } = require('path');
const { execSync } = require('child_process');

const MEMORY_DIR = process.env.MEMORY_DIR || './memory';
const TOKEN_THRESHOLD = 0.70; // 70% del context window

/**
 * Detecta si estamos cerca del límite de tokens
 */
function checkTokenThreshold(contextWindow = 262144, tokensUsed) {
  if (!tokensUsed) {
    tokensUsed = estimateTokenUsage();
  }
  
  const ratio = tokensUsed / contextWindow;
  return ratio >= TOKEN_THRESHOLD;
}

/**
 * Estima uso de tokens basado en archivos cargados
 */
function estimateTokenUsage() {
  try {
    const memoryFiles = execSync('ls -t memory/*.md 2>/dev/null | head -5', { encoding: 'utf-8' })
      .split('\n')
      .filter(f => f.trim());
    
    let totalChars = 0;
    for (const file of memoryFiles) {
      if (existsSync(file)) {
        totalChars += readFileSync(file, 'utf-8').length;
      }
    }
    
    // Estimación: ~4 caracteres = 1 token
    return Math.floor(totalChars / 4);
  } catch {
    return 0;
  }
}

/**
 * Obtiene el estado actual del sistema
 */
function getCurrentState() {
  const pendingTasks = [];
  const recentDecisions = [];
  
  try {
    const today = new Date().toISOString().slice(0, 10);
    const todayFile = join(MEMORY_DIR, `${today}.md`);
    
    if (existsSync(todayFile)) {
      const content = readFileSync(todayFile, 'utf-8');
      
      const pendingMatch = content.match(/[⏳⏳]\s*([^\n]+)/g);
      if (pendingMatch) {
        pendingTasks.push(...pendingMatch.map(m => m.replace(/^[⏳⏳]\s*/, '')));
      }
      
      const decisionMatch = content.match(/✅\s*([^\n]+)/g);
      if (decisionMatch) {
        recentDecisions.push(...decisionMatch.slice(-5).map(m => m.replace(/^✅\s*/, '')));
      }
    }
  } catch {
    // ignore
  }
  
  const currentTask = process.env.CURRENT_TASK || 'General operation';
  
  let contextWindow = 262144;
  try {
    const os = require('os');
    const configPath = join(os.homedir(), '.clawdbot', 'clawdbot.json');
    if (existsSync(configPath)) {
      const config = JSON.parse(readFileSync(configPath, 'utf-8'));
      contextWindow = config.models?.providers?.['kimi-code']?.models?.[0]?.contextWindow || 262144;
    }
  } catch {
    // use default
  }
  
  return {
    currentTask,
    pendingTasks: pendingTasks.slice(0, 10),
    recentDecisions: recentDecisions.slice(0, 5),
    contextWindow,
    tokensUsed: estimateTokenUsage(),
  };
}

/**
 * Obtiene información de memoria activa
 */
function getMemoryInfo() {
  try {
    const os = require('os');
    const qmdConfigPath = join(os.homedir(), '.qmd-lite', 'config.json');
    const activeCollections = [];
    
    if (existsSync(qmdConfigPath)) {
      const qmdConfig = JSON.parse(readFileSync(qmdConfigPath, 'utf-8'));
      activeCollections.push(...Object.keys(qmdConfig.collections || {}));
    }
    
    const recentFiles = execSync('ls -t memory/*.md 2>/dev/null | head -5', { encoding: 'utf-8' })
      .split('\n')
      .filter(f => f.trim())
      .map(f => f.replace('memory/', ''));
    
    return { recentFiles, activeCollections };
  } catch {
    return { recentFiles: [], activeCollections: [] };
  }
}

/**
 * Obtiene información de git
 */
function getGitInfo() {
  try {
    const branch = execSync('git branch --show-current 2>/dev/null', { encoding: 'utf-8' }).trim();
    const commit = execSync('git rev-parse --short HEAD 2>/dev/null', { encoding: 'utf-8' }).trim();
    const status = execSync('git status --porcelain 2>/dev/null', { encoding: 'utf-8' }).trim();
    
    return {
      branch: branch || 'unknown',
      commit: commit || 'unknown',
      changes: status ? status.split('\n').filter(l => l.trim()).length : 0,
    };
  } catch {
    return undefined;
  }
}

/**
 * Crea un checkpoint
 */
function createCheckpoint(reason = 'Token threshold reached') {
  const now = new Date();
  const timestamp = now.toISOString().slice(0, 16).replace(/[T:]/g, '-');
  const state = getCurrentState();
  
  const checkpoint = {
    timestamp: now.toISOString(),
    triggered: {
      tokenUsage: state.tokensUsed,
      threshold: TOKEN_THRESHOLD,
      reason,
    },
    state,
    memory: getMemoryInfo(),
    git: getGitInfo(),
  };
  
  const content = generateCheckpointMarkdown(checkpoint);
  
  if (!existsSync(MEMORY_DIR)) {
    mkdirSync(MEMORY_DIR, { recursive: true });
  }
  
  const filename = `checkpoint-${timestamp}.md`;
  const filepath = join(MEMORY_DIR, filename);
  writeFileSync(filepath, content);
  
  console.log(`✅ Checkpoint created: ${filepath}`);
  console.log(`   Reason: ${reason}`);
  console.log(`   Tokens: ${state.tokensUsed}/${state.contextWindow} (${Math.round((state.tokensUsed/state.contextWindow)*100)}%)`);
  
  return filepath;
}

/**
 * Genera markdown del checkpoint
 */
function generateCheckpointMarkdown(data) {
  const lines = [
    `# Checkpoint: ${data.timestamp.slice(0, 16).replace('T', ' ')}`,
    '',
    '## ⚠️ Trigger',
    `- **Reason:** ${data.triggered.reason}`,
    `- **Token Usage:** ${data.triggered.tokenUsage.toLocaleString()} / ${data.state.contextWindow.toLocaleString()} (${Math.round((data.triggered.tokenUsage/data.state.contextWindow)*100)}%)`,
    `- **Threshold:** ${Math.round(data.triggered.threshold * 100)}%`,
    '',
    '## 📋 Current State',
    '',
    '### Current Task',
    data.state.currentTask,
    '',
    '### Pending Tasks',
    data.state.pendingTasks.length > 0 
      ? data.state.pendingTasks.map(t => `- [ ] ${t}`).join('\n')
      : '- No pending tasks',
    '',
    '### Recent Decisions',
    data.state.recentDecisions.length > 0
      ? data.state.recentDecisions.map(d => `- ${d}`).join('\n')
      : '- No recent decisions',
    '',
    '## 💾 Memory Context',
    '',
    '### Recent Files',
    data.memory.recentFiles.map(f => `- ${f}`).join('\n') || '- None',
    '',
    '### Active Collections',
    data.memory.activeCollections.map(c => `- ${c}`).join('\n') || '- None',
    '',
  ];
  
  if (data.git) {
    lines.push(
      '## 📦 Repository',
      `- **Branch:** \`${data.git.branch}\``,
      `- **Commit:** \`${data.git.commit}\``,
      `- **Uncommitted Changes:** ${data.git.changes}`,
      ''
    );
  }
  
  lines.push(
    '---',
    `*Auto-generated checkpoint before compression*`,
    ''
  );
  
  return lines.join('\n');
}

/**
 * Verifica y crea checkpoint si es necesario
 */
function proactiveCheckpoint() {
  const state = getCurrentState();
  const ratio = state.tokensUsed / state.contextWindow;
  
  if (ratio >= TOKEN_THRESHOLD) {
    return createCheckpoint(`Token usage at ${Math.round(ratio * 100)}%`);
  }
  
  return null;
}

// Exportar funciones
module.exports = {
  checkTokenThreshold,
  estimateTokenUsage,
  getCurrentState,
  getMemoryInfo,
  getGitInfo,
  createCheckpoint,
  proactiveCheckpoint,
};

// CLI
const args = process.argv.slice(2);
const command = args[0];

switch (command) {
  case 'create':
    createCheckpoint(args[1] || 'Manual checkpoint');
    break;
    
  case 'check':
    const result = proactiveCheckpoint();
    if (result) {
      console.log('Checkpoint created automatically');
    } else {
      const state = getCurrentState();
      console.log(`Token usage: ${state.tokensUsed}/${state.contextWindow} (${Math.round((state.tokensUsed/state.contextWindow)*100)}%)`);
      console.log('Below threshold, no checkpoint needed');
    }
    break;
    
  case 'status':
    const s = getCurrentState();
    console.log('Current State:');
    console.log(`  Tokens: ${s.tokensUsed}/${s.contextWindow} (${Math.round((s.tokensUsed/s.contextWindow)*100)}%)`);
    console.log(`  Task: ${s.currentTask}`);
    console.log(`  Pending: ${s.pendingTasks.length} tasks`);
    break;
    
  default:
    console.log('Checkpoint System - Proactive Memory Preservation');
    console.log('');
    console.log('Commands:');
    console.log('  checkpoint check     # Check threshold and create if needed');
    console.log('  checkpoint create [reason]  # Create manual checkpoint');
    console.log('  checkpoint status    # Show current token status');
    console.log('');
    console.log('Environment:');
    console.log('  TOKEN_THRESHOLD=0.70 (default)');
    console.log('  MEMORY_DIR=./memory (default)');
    break;
}
