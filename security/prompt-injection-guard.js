/**
 * Prompt Injection Protection Module
 * Sanitiza inputs de archivos (PDF, TXT, etc.) antes de procesarlos
 * 
 * @author ClawdColombia
 * @version 1.0.0
 */

// Patrones de prompt injection conocidos
const INJECTION_PATTERNS = {
  // Intentos de override de instrucciones del sistema
  system_override: [
    /ignore\s+(previous|all|prior)\s+instructions/gi,
    /disregard\s+(previous|all|prior)\s+instructions/gi,
    /forget\s+(previous|all|prior)\s+instructions/gi,
    /system\s*:\s*/gi,
    /system\s+prompt\s*:/gi,
    /you\s+are\s+now/gi,
    /new\s+role\s*:/gi,
    /persona\s*:\s*/gi,
    /act\s+as\s+/gi,
    /become\s+/gi,
  ],
  
  // Delimitadores sospechosos
  delimiters: [
    /```\s*system/gi,
    /```\s*instructions/gi,
    /```\s*prompt/gi,
    /<system>/gi,
    /<instructions>/gi,
    /<prompt>/gi,
    /\[system\]/gi,
    /\[instructions\]/gi,
    /\[prompt\]/gi,
  ],
  
  // Inyección de comandos
  command_injection: [
    /execute\s+/gi,
    /run\s+(command|script|code)/gi,
    /eval\s*\(/gi,
    /exec\s*\(/gi,
    /system\s*\(/gi,
    /subprocess/gi,
    /child_process/gi,
    /spawn\s*\(/gi,
  ],
  
  // Exfiltración de datos
  data_exfiltration: [
    /send\s+(to|this\s+to)/gi,
    /email\s+(to|me)/gi,
    /forward\s+(to|this)/gi,
    /upload\s+(to|this)/gi,
    /http:\/\/\s*\w+/gi,
    /https:\/\/\s*\w+/gi,
    /api\s*key/gi,
    /password/gi,
    /token/gi,
    /secret/gi,
  ],
  
  // Jailbreaks conocidos
  jailbreaks: [
    /DAN\s*:/gi,
    /DARK\s*BERTA/gi,
    /developer\s*mode/gi,
    /jailbreak/gi,
    /\/\/\s*ignore/gi,
    /\/\*\s*ignore/gi,
    /#\s*ignore/gi,
  ],
  
  // Inyección de código
  code_injection: [
    /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi,
    /javascript\s*:/gi,
    /on\w+\s*=\s*["']/gi,
    /data\s*:\s*text\/html/gi,
  ]
};

// Palabras/frases de riesgo alto
const HIGH_RISK_KEYWORDS = [
  'ignore previous instructions',
  'system prompt',
  'you are a helpful assistant',
  'you are now',
  'new instructions',
  'override',
  'bypass',
  'disregard',
  'forget everything',
  'from now on',
  'instead of',
  'replace your',
  'your new role',
  'act as if',
  'pretend to be',
];

// Análisis de entropía para detectar ofuscación
function calculateEntropy(str) {
  const len = str.length;
  if (len === 0) return 0;
  
  const charCounts = {};
  for (const char of str) {
    charCounts[char] = (charCounts[char] || 0) + 1;
  }
  
  let entropy = 0;
  for (const count of Object.values(charCounts)) {
    const p = count / len;
    entropy -= p * Math.log2(p);
  }
  
  return entropy;
}

// Detectar ofuscación básica
function detectObfuscation(text) {
  const checks = {
    // Base64-like patterns
    base64: /^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(text.trim()),
    // Excessive encoding
    url_encoded: /%[0-9A-Fa-f]{2}/.test(text) && (text.match(/%[0-9A-Fa-f]{2}/g) || []).length > 10,
    // Zero-width characters
    zero_width: /[\u200B\u200C\u200D\uFEFF]/.test(text),
    // Homoglyphs (caracteres similares)
    homoglyphs: /[А-Яа-я\uFF10-\uFF19]/.test(text), // Cirílico y caracteres de ancho completo
    // Excessive whitespace (steganography)
    excessive_whitespace: (text.match(/\s/g) || []).length / text.length > 0.3,
  };
  
  return checks;
}

// Clase principal de protección
class PromptInjectionGuard {
  constructor(options = {}) {
    this.options = {
      strictMode: options.strictMode || true,
      maxLength: options.maxLength || 500000,
      minEntropy: options.minEntropy || 2.0,
      blockObfuscated: options.blockObfuscated !== false,
      logViolations: options.logViolations !== false,
      ...options
    };
    
    this.violations = [];
  }

  /**
   * Analiza texto en busca de intentos de prompt injection
   * @param {string} text - Texto a analizar
   * @param {string} source - Fuente del texto (pdf, txt, web, etc.)
   * @returns {object} - Resultado del análisis
   */
  analyze(text, source = 'unknown') {
    const result = {
      safe: true,
      confidence: 1.0,
      source,
      timestamp: new Date().toISOString(),
      issues: [],
      sanitized: null,
      action: 'allow'
    };

    // Check 1: Longitud excesiva
    if (text.length > this.options.maxLength) {
      result.issues.push({
        type: 'length',
        severity: 'medium',
        message: `Texto excede longitud máxima (${text.length} > ${this.options.maxLength})`
      });
      result.confidence -= 0.1;
    }

    // Check 2: Patrones de injection
    for (const [category, patterns] of Object.entries(INJECTION_PATTERNS)) {
      for (const pattern of patterns) {
        const matches = text.match(pattern);
        if (matches) {
          result.issues.push({
            type: 'injection_pattern',
            category,
            severity: category === 'system_override' ? 'critical' : 'high',
            pattern: pattern.toString(),
            matches: matches.slice(0, 3), // Limitar matches reportados
            message: `Patrón de ${category} detectado`
          });
          result.confidence -= 0.15;
        }
      }
    }

    // Check 3: Keywords de riesgo
    const lowerText = text.toLowerCase();
    const foundKeywords = HIGH_RISK_KEYWORDS.filter(kw => lowerText.includes(kw));
    
    if (foundKeywords.length > 0) {
      result.issues.push({
        type: 'high_risk_keywords',
        severity: foundKeywords.length > 2 ? 'high' : 'medium',
        keywords: foundKeywords,
        message: `${foundKeywords.length} keywords de riesgo detectados`
      });
      result.confidence -= 0.1 * foundKeywords.length;
    }

    // Check 4: Ofuscación
    if (this.options.blockObfuscated) {
      const obfuscation = detectObfuscation(text);
      const obfuscationTypes = Object.entries(obfuscation)
        .filter(([_, detected]) => detected)
        .map(([type]) => type);
      
      if (obfuscationTypes.length > 0) {
        result.issues.push({
          type: 'obfuscation',
          severity: 'high',
          methods: obfuscationTypes,
          message: `Posible ofuscación detectada: ${obfuscationTypes.join(', ')}`
        });
        result.confidence -= 0.2 * obfuscationTypes.length;
      }
    }

    // Check 5: Entropía anómala
    const entropy = calculateEntropy(text);
    if (entropy < this.options.minEntropy && text.length > 100) {
      result.issues.push({
        type: 'entropy',
        severity: 'low',
        entropy,
        message: 'Entropía anormalmente baja (posible patrón repetitivo)'
      });
    }

    // Calcular confianza final
    result.confidence = Math.max(0, Math.min(1, result.confidence));
    
    // Determinar acción
    const criticalCount = result.issues.filter(i => i.severity === 'critical').length;
    const highCount = result.issues.filter(i => i.severity === 'high').length;
    
    if (criticalCount > 0 || result.confidence < 0.3) {
      result.safe = false;
      result.action = 'block';
    } else if (highCount > 0 || result.confidence < 0.6) {
      result.safe = false;
      result.action = 'quarantine';
      result.sanitized = this.sanitize(text);
    } else if (result.issues.length > 0) {
      result.action = 'warn';
      result.sanitized = this.sanitize(text);
    }

    // Logging
    if (this.options.logViolations && result.issues.length > 0) {
      this.violations.push(result);
      this.logViolation(result);
    }

    return result;
  }

  /**
   * Sanitiza texto removiendo patrones peligrosos
   */
  sanitize(text) {
    let sanitized = text;

    // Remover delimitadores sospechosos
    sanitized = sanitized.replace(/```\s*(system|instructions|prompt)[\s\S]*?```/gi, '[REMOVED]');
    sanitized = sanitized.replace(/<(system|instructions|prompt)>[\s\S]*?<\/\1>/gi, '[REMOVED]');
    
    // Neutralizar intentos de override
    sanitized = sanitized.replace(/ignore\s+(previous|all)\s+instructions/gi, '[IGNORED]');
    sanitized = sanitized.replace(/system\s*:\s*/gi, '[SYSTEM:] ');
    
    // Remover caracteres de ancho cero
    sanitized = sanitized.replace(/[\u200B\u200C\u200D\uFEFF]/g, '');
    
    // Escapar delimitadores markdown
    sanitized = sanitized.replace(/(```|~~~)/g, '\\`\\`\\`');
    
    return sanitized;
  }

  /**
   * Procesa contenido de archivo
   */
  processFile(content, filename, mimeType) {
    const source = `${filename} (${mimeType})`;
    
    // Decodificar si es base64 (común en PDFs extraídos)
    let text = content;
    if (typeof content === 'string' && /^[A-Za-z0-9+/]*={0,2}$/.test(content.trim())) {
      try {
        text = Buffer.from(content, 'base64').toString('utf8');
      } catch {
        text = content;
      }
    }

    return this.analyze(text, source);
  }

  /**
   * Verifica si es seguro procesar el input
   */
  isSafe(text, source = 'unknown') {
    const result = this.analyze(text, source);
    return result.safe;
  }

  logViolation(result) {
    const timestamp = new Date().toISOString();
    const logEntry = `[${timestamp}] VIOLATION from ${result.source}: ${result.issues.length} issues, confidence=${result.confidence.toFixed(2)}, action=${result.action}\n`;
    
    // En producción, escribir a archivo de log
    if (typeof require !== 'undefined') {
      const fs = require('fs');
      const path = require('path');
      const logDir = path.join(process.cwd(), 'logs');
      
      if (!fs.existsSync(logDir)) {
        fs.mkdirSync(logDir, { recursive: true });
      }
      
      fs.appendFileSync(
        path.join(logDir, 'injection-guard.log'),
        logEntry
      );
    }
  }

  getViolations() {
    return this.violations;
  }

  clearViolations() {
    this.violations = [];
  }
}

// Wrapper para integración con Clawdbot
class ClawdbotSecurityWrapper {
  constructor() {
    this.guard = new PromptInjectionGuard({
      strictMode: true,
      logViolations: true
    });
  }

  /**
   * Intercepta archivos antes de procesarlos
   */
  interceptFile(filePath, content) {
    const filename = filePath.split('/').pop();
    const mimeType = this.detectMimeType(filename);
    
    const result = this.guard.processFile(content, filename, mimeType);
    
    if (result.action === 'block') {
      return {
        allowed: false,
        error: 'CONTENIDO BLOQUEADO: Se detectaron patrones de prompt injection',
        details: result.issues.map(i => i.message).join('; '),
        report: result
      };
    }
    
    if (result.action === 'quarantine') {
      return {
        allowed: true,
        sanitized: true,
        content: result.sanitized,
        warning: 'El contenido fue sanitizado por seguridad',
        report: result
      };
    }
    
    if (result.action === 'warn') {
      return {
        allowed: true,
        warning: 'Revisar contenido: se detectaron patrones leves',
        content: result.sanitized || content,
        report: result
      };
    }
    
    return { allowed: true, content };
  }

  detectMimeType(filename) {
    const ext = filename.split('.').pop().toLowerCase();
    const types = {
      'pdf': 'application/pdf',
      'txt': 'text/plain',
      'md': 'text/markdown',
      'json': 'application/json',
      'csv': 'text/csv',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'html': 'text/html'
    };
    return types[ext] || 'application/octet-stream';
  }

  /**
   * Verificación de seguridad para prompts
   */
  verifyPrompt(prompt, context = {}) {
    const result = this.guard.analyze(prompt, context.source || 'prompt');
    
    if (!result.safe) {
      console.error('🛡️  SECURITY ALERT: Prompt injection detected');
      console.error(`   Confidence: ${(result.confidence * 100).toFixed(1)}%`);
      console.error(`   Issues: ${result.issues.length}`);
      
      return {
        safe: false,
        blocked: result.action === 'block',
        issues: result.issues,
        report: result
      };
    }
    
    return { safe: true, report: result };
  }
}

// Exportar para Node.js
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    PromptInjectionGuard,
    ClawdbotSecurityWrapper,
    INJECTION_PATTERNS,
    HIGH_RISK_KEYWORDS
  };
}

// Exportar para ES modules
if (typeof exports !== 'undefined') {
  exports.PromptInjectionGuard = PromptInjectionGuard;
  exports.ClawdbotSecurityWrapper = ClawdbotSecurityWrapper;
}
