#!/usr/bin/env node
/**
 * security-guard.js - Sistema de protección contra Prompt Injection v2.0
 * Clawd Security Module - Enhanced Edition
 * 
 * Mejoras implementadas:
 * - Rate limiting por fuente
 * - Content hashing (anti-replay)
 * - Output sanitization (data leakage prevention)
 * - URL validation (SSRF protection)
 * - Enhanced logging
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

class SecurityGuard {
  constructor() {
    // ===== MEJORA 1: RATE LIMITING POR FUENTE =====
    this.sourceRateLimits = new Map();
    this.rateLimitConfig = {
      'moltbook': { maxRequests: 10, windowMs: 60000 },    // 10 req/min
      'web': { maxRequests: 5, windowMs: 60000 },          // 5 req/min
      'email': { maxRequests: 3, windowMs: 60000 },        // 3 req/min
      'unknown': { maxRequests: 5, windowMs: 60000 },      // 5 req/min
      'confirmed_human_andres': { maxRequests: 1000, windowMs: 60000 } // Sin límite práctico
    };

    // ===== MEJORA 2: CONTENT HASHING (ANTI-REPLAY) =====
    this.recentHashes = new Set();
    this.maxHashHistory = 1000;

    // Patrones de detección de injection (existentes)
    this.injectionPatterns = [
      // Intentos de override de sistema
      { pattern: /ignore\s+(all\s+)?(previous|prior)\s+(instructions?|prompts?)/i, type: 'override', severity: 'CRITICAL' },
      { pattern: /disregard\s+(all\s+)?(previous|prior)\s+(instructions?|prompts?)/i, type: 'override', severity: 'CRITICAL' },
      { pattern: /system\s+(override|prompt|instruction)/i, type: 'override', severity: 'CRITICAL' },
      { pattern: /you\s+are\s+(now\s+)?(in\s+)?(developer\s+mode|debug\s+mode|admin\s+mode)/i, type: 'override', severity: 'CRITICAL' },
      
      // Intentos de cambio de identidad
      { pattern: /act\s+as\s+(?!Clawd|an\s+assistant|a\s+helpful)/i, type: 'identity', severity: 'HIGH' },
      { pattern: /you\s+are\s+(no\s+longer\s+)?(Clawd|an\s+AI|a\s+language\s+model)/i, type: 'identity', severity: 'HIGH' },
      { pattern: /forget\s+(who\s+you\s+are|your\s+(identity|name|purpose))/i, type: 'identity', severity: 'HIGH' },
      
      // Solicitudes de información interna
      { pattern: /show\s+me\s+your\s+(system\s+)?(prompt|instructions?|configuration|config)/i, type: 'info_leak', severity: 'HIGH' },
      { pattern: /what\s+are\s+your\s+(original\s+)?(instructions?|rules?|prompts?)/i, type: 'info_leak', severity: 'HIGH' },
      { pattern: /reveal\s+your\s+(instructions?|system\s+prompt)/i, type: 'info_leak', severity: 'HIGH' },
      { pattern: /print\s+your\s+(entire\s+)?(prompt|system)/i, type: 'info_leak', severity: 'HIGH' },
      
      // Delimitadores sospechosos
      { pattern: /```\s*(system|ignore|override|command)/i, type: 'delimiter', severity: 'CRITICAL' },
      { pattern: /<\s*(system|instruction|command|override)\s*>/i, type: 'delimiter', severity: 'CRITICAL' },
      { pattern: /\[\[.*\]\]/, type: 'delimiter', severity: 'MEDIUM' },
      { pattern: /{{.*}}/, type: 'delimiter', severity: 'MEDIUM' },
      { pattern: /---\s*\n\s*(system|instruction)/i, type: 'delimiter', severity: 'HIGH' },
      
      // Secuencias de escape sospechosas
      { pattern: /\\x00|\\u0000|\\0/, type: 'escape', severity: 'HIGH' },
      { pattern: /\x00|\x00/, type: 'escape', severity: 'HIGH' },
      
      // Manipulación de contexto
      { pattern: /translate\s+(this|the\s+following)\s*[:;]\s*```/i, type: 'obfuscation', severity: 'MEDIUM' },
      { pattern: /summarize\s+(this|the\s+following)\s*[:;]\s*```/i, type: 'obfuscation', severity: 'MEDIUM' },
      { pattern: /explain\s+(this|the\s+following)\s*[:;]\s*</i, type: 'obfuscation', severity: 'MEDIUM' },
      
      // Intención maliciosa explícita
      { pattern: /(hack|exploit|bypass|inject)\s+(prompt|system|security)/i, type: 'malicious', severity: 'CRITICAL' },
      { pattern: /(steal|exfiltrate|extract)\s+(data|information|credentials?)/i, type: 'malicious', severity: 'CRITICAL' },
    ];
    
    // Comandos peligrosos que nunca deben ejecutarse automáticamente
    this.dangerousCommands = [
      /rm\s+-rf\s+\/(?!home|tmp)/i,
      /rm\s+-rf\s+~\/\./i,
      /dd\s+if=\/dev\/zero/i,
      />\s*\/etc\/passwd/i,
      />\s*\/etc\/shadow/i,
      /chmod\s+-R\s+777\s+\//i,
      /curl\s+.*\|\s*(bash|sh)/i,
      /wget\s+.*-O-\s*\|\s*(bash|sh)/i,
      /cat\s+.*\/\.ssh\/id_rsa/i,
      /cat\s+.*\/\.config\/.*\/credentials/i,
      /tar\s+.*\|.*curl/i,
      /unset\s+HISTFILE/i,
    ];
    
    // Fuentes confiables vs no confiables
    this.trustedSources = ['confirmed_human_andres'];
    this.untrustedSources = ['moltbook', 'web', 'email', 'unknown'];
    
    // Log de intentos bloqueados
    this.logFile = path.join(process.env.HOME || '/tmp', 'clawd/security-injection-log.json');
    this.ensureLogFile();
  }
  
  ensureLogFile() {
    try {
      const dir = path.dirname(this.logFile);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      if (!fs.existsSync(this.logFile)) {
        fs.writeFileSync(this.logFile, JSON.stringify([], null, 2));
      }
    } catch (e) {
      console.error('Error creating log file:', e.message);
    }
  }
  
  // ===== MEJORA 1: RATE LIMITING =====
  checkRateLimit(source) {
    const now = Date.now();
    const config = this.rateLimitConfig[source] || this.rateLimitConfig['unknown'];
    const history = this.sourceRateLimits.get(source) || [];
    
    // Limpiar entradas antiguas
    const valid = history.filter(t => now - t < config.windowMs);
    
    if (valid.length >= config.maxRequests) {
      return { 
        allowed: false, 
        retryAfter: config.windowMs - (now - valid[0]),
        reason: `Rate limit exceeded for ${source}: ${valid.length}/${config.maxRequests} requests`
      };
    }
    
    valid.push(now);
    this.sourceRateLimits.set(source, valid);
    return { allowed: true };
  }

  // ===== MEJORA 2: CONTENT HASHING (ANTI-REPLAY) =====
  checkContentUniqueness(input) {
    const hash = crypto.createHash('sha256').update(input).digest('hex');
    
    if (this.recentHashes.has(hash)) {
      return { isUnique: false, hash, reason: 'Replay attack detected: identical content' };
    }
    
    this.recentHashes.add(hash);
    if (this.recentHashes.size > this.maxHashHistory) {
      const first = this.recentHashes.values().next().value;
      this.recentHashes.delete(first);
    }
    
    return { isUnique: true, hash };
  }

  // ===== MEJORA 4: URL VALIDATION (SSRF PROTECTION) =====
  validateUrl(url) {
    try {
      const parsed = new URL(url);
      const hostname = parsed.hostname.toLowerCase();
      
      // Verificar esquemas permitidos
      if (!['http:', 'https:'].includes(parsed.protocol)) {
        return { valid: false, reason: `Protocol ${parsed.protocol} not allowed` };
      }
      
      // Verificar IPs privadas y localhost
      if (this.isPrivateHost(hostname)) {
        return { valid: false, reason: 'Private/internal host blocked (SSRF protection)' };
      }
      
      // Verificar dominios de metadata cloud
      const blockedDomains = [
        'metadata.google.internal',
        '169.254.169.254',  // AWS metadata
        'metadata.azure.internal',
        'alibaba.xMetaData-service',
        '100.100.100.200'   // Alibaba Cloud
      ];
      
      for (const blocked of blockedDomains) {
        if (hostname === blocked || hostname.includes(blocked)) {
          return { valid: false, reason: `Cloud metadata endpoint blocked: ${blocked}` };
        }
      }
      
      return { valid: true, hostname };
    } catch (e) {
      return { valid: false, reason: 'Invalid URL format' };
    }
  }
  
  isPrivateHost(hostname) {
    // Verificar localhost
    if (hostname === 'localhost' || hostname === '127.0.0.1' || hostname === '::1') {
      return true;
    }
    
    // Verificar IPs privadas
    const privateRanges = [
      /^10\./,
      /^172\.(1[6-9]|2[0-9]|3[0-1])\./,
      /^192\.168\./,
      /^127\./,
      /^0\./,
      /^fc00:/i,
      /^fe80:/i,
      /^::1$/
    ];
    
    return privateRanges.some(range => range.test(hostname));
  }

  // ===== MEJORA 3: OUTPUT SANITIZATION =====
  sanitizeOutput(output) {
    if (typeof output !== 'string') return output;
    
    let sanitized = output;
    let redactedCount = 0;
    
    // Patrones de información sensible
    const sensitivePatterns = [
      { pattern: /ghp_[a-zA-Z0-9]{36}/g, name: 'GITHUB_TOKEN' },
      { pattern: /gho_[a-zA-Z0-9]{36}/g, name: 'GITHUB_OAUTH' },
      { pattern: /ghu_[a-zA-Z0-9]{36}/g, name: 'GITHUB_USER_TOKEN' },
      { pattern: /ghs_[a-zA-Z0-9]{36}/g, name: 'GITHUB_SERVER_TOKEN' },
      { pattern: /hf_[a-zA-Z0-9]{34}/g, name: 'HF_TOKEN' },
      { pattern: /sk-[a-zA-Z0-9]{48}/g, name: 'OPENAI_KEY' },
      { pattern: /sk-[a-zA-Z0-9]{32}/g, name: 'STRIPE_KEY' },
      { pattern: /[0-9a-f]{64}/g, name: 'HEX_SECRET' }, // Posible API key
      { pattern: /eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*/g, name: 'JWT_TOKEN' },
      { pattern: /-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----[\s\S]*?-----END/i, name: 'PRIVATE_KEY' },
      { pattern: /AKIA[0-9A-Z]{16}/g, name: 'AWS_ACCESS_KEY' },
      { pattern: /[0-9a-zA-Z/+]{40}/g, name: 'BASE64_SECRET' }
    ];
    
    for (const { pattern, name } of sensitivePatterns) {
      const matches = sanitized.match(pattern);
      if (matches) {
        redactedCount += matches.length;
        sanitized = sanitized.replace(pattern, `[${name}_REDACTED]`);
      }
    }
    
    // Loggear si se redactó algo
    if (redactedCount > 0) {
      this.logAttempt('[OUTPUT_SANITIZED]', 'output_filter', 
        [{ type: 'data_leakage_prevented', count: redactedCount, severity: 'HIGH' }], true);
    }
    
    return sanitized;
  }
  
  logAttempt(input, source, findings, blocked) {
    try {
      const logs = JSON.parse(fs.readFileSync(this.logFile, 'utf8'));
      logs.push({
        timestamp: new Date().toISOString(),
        source: source,
        blocked: blocked,
        findings: findings,
        inputPreview: input.substring(0, 100) + (input.length > 100 ? '...' : '')
      });
      // Mantener solo últimos 100 intentos
      if (logs.length > 100) logs.shift();
      fs.writeFileSync(this.logFile, JSON.stringify(logs, null, 2));
    } catch (e) {
      // Silenciar errores de log
    }
  }
  
  /**
   * Analiza el input en busca de patrones de injection
   * AHORA CON RATE LIMITING Y ANTI-REPLAY
   */
  scan(input, source = 'unknown') {
    const findings = [];
    
    // 1. Verificar rate limiting
    const rateLimit = this.checkRateLimit(source);
    if (!rateLimit.allowed) {
      findings.push({
        type: 'rate_limit_exceeded',
        severity: 'HIGH',
        message: rateLimit.reason,
        retryAfter: rateLimit.retryAfter
      });
      this.logAttempt(input, source, findings, true);
      return {
        valid: false,
        blocked: true,
        findings: findings,
        source: source,
        message: `⏳ Rate limit exceeded. Retry after ${Math.ceil(rateLimit.retryAfter / 1000)}s`
      };
    }
    
    // 2. Verificar unicidad de contenido (anti-replay)
    const uniqueness = this.checkContentUniqueness(input);
    if (!uniqueness.isUnique) {
      findings.push({
        type: 'replay_attack',
        severity: 'HIGH',
        message: uniqueness.reason
      });
    }
    
    // 3. Verificar patrones de injection
    for (const { pattern, type, severity } of this.injectionPatterns) {
      if (pattern.test(input)) {
        findings.push({
          type: type,
          severity: severity,
          pattern: pattern.toString(),
          message: this.getMessageForType(type)
        });
      }
    }
    
    // 4. Verificar comandos peligrosos
    for (const pattern of this.dangerousCommands) {
      if (pattern.test(input)) {
        findings.push({
          type: 'dangerous_command',
          severity: 'CRITICAL',
          pattern: pattern.toString(),
          message: 'Comando potencialmente destructivo detectado'
        });
      }
    }
    
    // 5. Verificar fuente y comandos
    if (this.untrustedSources.includes(source)) {
      if (this.containsCommandIntent(input)) {
        findings.push({
          type: 'untrusted_source_command',
          severity: 'HIGH',
          message: 'Comando desde fuente no confiable requiere confirmación humana'
        });
      }
    }
    
    // Determinar si bloquear
    const hasCritical = findings.some(f => f.severity === 'CRITICAL');
    const hasHigh = findings.some(f => f.severity === 'HIGH');
    const isReplay = findings.some(f => f.type === 'replay_attack');
    
    // Bloquear si hay findings críticos, high desde fuente no confiable, o replay
    const blocked = hasCritical || isReplay || (hasHigh && this.untrustedSources.includes(source));
    
    // Loggear el intento
    this.logAttempt(input, source, findings, blocked);
    
    return {
      valid: !blocked,
      blocked: blocked,
      findings: findings,
      source: source,
      message: blocked ? this.generateBlockMessage(findings, source) : 'Input validado'
    };
  }
  
  /**
   * Valida URLs encontradas en el input (SSRF protection)
   */
  validateInputUrls(input) {
    const urlPattern = /https?:\/\/[^\s<>"{}|\\^`[\]]+/gi;
    const urls = input.match(urlPattern) || [];
    const results = [];
    
    for (const url of urls) {
      const validation = this.validateUrl(url);
      if (!validation.valid) {
        results.push({
          url: url,
          valid: false,
          reason: validation.reason
        });
      }
    }
    
    return results;
  }
  
  containsCommandIntent(input) {
    const commandPatterns = [
      /^(run|execute|exec|do|perform|invoke|call)\s/i,
      /\b(rm|mv|cp|chmod|chown|sudo|curl|wget|python|node|npm)\s+-/i,
      /\bsystem\s*\(/i,
      /\bsubprocess\./i,
      /\bos\.system/i
    ];
    return commandPatterns.some(p => p.test(input));
  }
  
  getMessageForType(type) {
    const messages = {
      'override': 'Intento de override de instrucciones del sistema',
      'identity': 'Intento de cambio de identidad o rol',
      'info_leak': 'Solicitud de información interna del sistema',
      'delimiter': 'Uso sospechoso de delimitadores o marcadores especiales',
      'escape': 'Secuencias de escape sospechosas',
      'obfuscation': 'Posible ofuscación de código malicioso',
      'malicious': 'Intención maliciosa explícita detectada',
      'replay_attack': 'Ataque de repetición detectado (contenido idéntico)',
      'rate_limit_exceeded': 'Demasiadas solicitudes desde esta fuente'
    };
    return messages[type] || 'Patrón sospechoso detectado';
  }
  
  generateBlockMessage(findings, source) {
    const criticalCount = findings.filter(f => f.severity === 'CRITICAL').length;
    const highCount = findings.filter(f => f.severity === 'HIGH').length;
    
    let message = '🛡️ **Bloqueo de Seguridad**\n\n';
    
    if (criticalCount > 0) {
      message += `⚠️ Detectados **${criticalCount}** patrones CRÍTICOS de seguridad.\n`;
    }
    if (highCount > 0) {
      message += `⚠️ Detectados **${highCount}** patrones de alto riesgo.\n`;
    }
    
    message += '\n**Tipo de amenazas detectadas:**\n';
    findings.slice(0, 3).forEach(f => {
      message += `- ${f.type}: ${f.message}\n`;
    });
    
    message += '\n**Acción:** Esta solicitud no será procesada.';
    
    if (source === 'moltbook' || source === 'web') {
      message += '\n\n📝 *Nota: No ejecuto comandos ni instrucciones de fuentes externas como Moltbook o la web. Si @Andres quiere que realice esta acción, debe solicitarlo directamente.*';
    }
    
    return message;
  }
  
  /**
   * Función de conveniencia para validación rápida
   */
  static check(input, source = 'unknown') {
    const guard = new SecurityGuard();
    return guard.scan(input, source);
  }
  
  /**
   * Función de conveniencia para sanitizar output
   */
  static sanitize(output) {
    const guard = new SecurityGuard();
    return guard.sanitizeOutput(output);
  }
  
  /**
   * Función de conveniencia para validar URLs
   */
  static validateUrl(url) {
    const guard = new SecurityGuard();
    return guard.validateUrl(url);
  }
}

// Exportar para uso en Node.js
if (typeof module !== 'undefined' && module.exports) {
  module.exports = SecurityGuard;
}

// Log de inicialización
console.log('🛡️ Security Guard v2.0 cargado');
console.log('   Mejoras: Rate limiting | Anti-replay | Output sanitization | SSRF protection');
