# 🛡️ Security Guard - Mejoras Propuestas

Basado en análisis de amenazas de Moltbook y mejores prácticas de seguridad para agents.

---

## ✅ Estado Actual

El `security-guard.js` actual incluye:
- Detección de patrones de prompt injection
- Validación de comandos peligrosos
- Logging de intentos bloqueados
- Diferenciación de fuentes confiables/no confiables

---

## 🔧 Mejoras Propuestas

### 1. Rate Limiting por Fuente
```javascript
// Agregar a SecurityGuard constructor
this.sourceRateLimits = new Map();
this.rateLimitConfig = {
  'moltbook': { maxRequests: 10, windowMs: 60000 },    // 10 req/min
  'web': { maxRequests: 5, windowMs: 60000 },          // 5 req/min
  'email': { maxRequests: 3, windowMs: 60000 },        // 3 req/min
  'confirmed_human_andres': { maxRequests: 100, windowMs: 60000 } // Sin límite efectivo
};

// Método nuevo
checkRateLimit(source) {
  const now = Date.now();
  const config = this.rateLimitConfig[source] || this.rateLimitConfig['web'];
  const history = this.sourceRateLimits.get(source) || [];
  
  // Limpiar entradas antiguas
  const valid = history.filter(t => now - t < config.windowMs);
  
  if (valid.length >= config.maxRequests) {
    return { allowed: false, retryAfter: config.windowMs - (now - valid[0]) };
  }
  
  valid.push(now);
  this.sourceRateLimits.set(source, valid);
  return { allowed: true };
}
```

**Por qué:** Evita ataques de fuerza bruta desde fuentes externas.

---

### 2. Content Hashing para Detección de Repetición
```javascript
// Agregar a constructor
this.recentHashes = new Set();
this.maxHashHistory = 1000;

// Método nuevo
checkContentUniqueness(input) {
  const crypto = require('crypto');
  const hash = crypto.createHash('md5').update(input).digest('hex');
  
  if (this.recentHashes.has(hash)) {
    return { isUnique: false, hash };
  }
  
  this.recentHashes.add(hash);
  if (this.recentHashes.size > this.maxHashHistory) {
    const first = this.recentHashes.values().next().value;
    this.recentHashes.delete(first);
  }
  
  return { isUnique: true, hash };
}
```

**Por qué:** Detecta ataques de repetición (replay attacks) donde el mismo payload malicioso se envía múltiples veces.

---

### 3. Validación de Skills antes de Instalación
```javascript
// Nuevo método
async validateSkill(skillPath) {
  const risks = [];
  
  // Leer package.json o SKILL.md
  const packagePath = path.join(skillPath, 'package.json');
  const skillMdPath = path.join(skillPath, 'SKILL.md');
  
  if (fs.existsSync(packagePath)) {
    const pkg = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
    
    // Verificar dependencias sospechosas
    const suspiciousDeps = [
      'request', 'axios', 'node-fetch',  // HTTP libs (posible exfiltración)
      'child_process', 'fs-extra',       // System access
      'eval', 'vm2'                      // Code execution
    ];
    
    const deps = Object.keys(pkg.dependencies || {});
    const devDeps = Object.keys(pkg.devDependencies || {});
    const allDeps = [...deps, ...devDeps];
    
    for (const susp of suspiciousDeps) {
      if (allDeps.includes(susp)) {
        risks.push({
          type: 'suspicious_dependency',
          package: susp,
          severity: 'MEDIUM',
          message: `Skill depende de ${susp} - revisar uso`
        });
      }
    }
    
    // Verificar scripts de post-install
    if (pkg.scripts?.postinstall) {
      risks.push({
        type: 'postinstall_script',
        script: pkg.scripts.postinstall,
        severity: 'HIGH',
        message: 'Script post-install detectado - revisar manualmente'
      });
    }
  }
  
  // Verificar código fuente por patrones maliciosos
  const srcFiles = glob.sync(path.join(skillPath, '**/*.js'));
  for (const file of srcFiles.slice(0, 10)) { // Revisar max 10 archivos
    const content = fs.readFileSync(file, 'utf8');
    
    // Patrones peligrosos en código
    const dangerousPatterns = [
      { pattern: /eval\s*\(/, desc: 'Uso de eval()' },
      { pattern: /new\s+Function\s*\(/, desc: 'Uso de new Function()' },
      { pattern: /require\s*\(\s*['"]child_process['"]\s*\)/, desc: 'child_process' },
      { pattern: /process\.env\./, desc: 'Acceso a variables de entorno' },
      { pattern: /fs\.readFile.*password|token|key/i, desc: 'Lectura de archivos sensibles' }
    ];
    
    for (const { pattern, desc } of dangerousPatterns) {
      if (pattern.test(content)) {
        risks.push({
          type: 'dangerous_code_pattern',
          file: path.relative(skillPath, file),
          pattern: desc,
          severity: 'HIGH'
        });
      }
    }
  }
  
  return risks;
}
```

**Por qué:** Protege contra supply chain attacks en skills, como el mencionado por eudaemon_0 en Moltbook.

---

### 4. Sanitización de Output (Prevenir Data Leakage)
```javascript
// Nuevo método
sanitizeOutput(output, context = {}) {
  let sanitized = output;
  
  // Patrones de información sensible
  const sensitivePatterns = [
    { pattern: /ghp_[a-zA-Z0-9]{36}/g, replacement: '[GITHUB_TOKEN_REDACTED]' },
    { pattern: /hf_[a-zA-Z0-9]{34}/g, replacement: '[HF_TOKEN_REDACTED]' },
    { pattern: /sk-[a-zA-Z0-9]{48}/g, replacement: '[OPENAI_KEY_REDACTED]' },
    { pattern: /[0-9a-f]{64}/g, replacement: '[HEX_HASH_REDACTED]' }, // Posible API key
    { pattern: /eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*/g, replacement: '[JWT_REDACTED]' },
    { pattern: /-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----/g, replacement: '[PRIVATE_KEY_REDACTED]' }
  ];
  
  for (const { pattern, replacement } of sensitivePatterns) {
    sanitized = sanitized.replace(pattern, replacement);
  }
  
  // Verificar si se redactó algo
  if (sanitized !== output) {
    this.logAttempt('[OUTPUT_SANITIZED]', 'output_filter', 
      [{ type: 'data_leakage_prevented', severity: 'HIGH' }], true);
  }
  
  return sanitized;
}
```

**Por qué:** Previene filtración accidental de credenciales en respuestas.

---

### 5. Validación de URLs en Comandos Web
```javascript
// Nuevo método
validateUrl(url, context = {}) {
  try {
    const parsed = new URL(url);
    
    const blockedDomains = [
      'localhost', '127.0.0.1', '0.0.0.0', '::1',
      '169.254.169.254',  // AWS metadata
      'metadata.google.internal',  // GCP metadata
      '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16'  // Private ranges
    ];
    
    // Verificar si es IP privada
    const hostname = parsed.hostname;
    if (this.isPrivateIP(hostname)) {
      return { valid: false, reason: 'Private IP/localhost blocked' };
    }
    
    // Verificar dominios bloqueados
    for (const blocked of blockedDomains) {
      if (hostname === blocked || hostname.endsWith('.' + blocked)) {
        return { valid: false, reason: `Domain ${blocked} blocked` };
      }
    }
    
    // Verificar esquemas permitidos
    if (!['http:', 'https:'].includes(parsed.protocol)) {
      return { valid: false, reason: `Protocol ${parsed.protocol} not allowed` };
    }
    
    return { valid: true };
  } catch (e) {
    return { valid: false, reason: 'Invalid URL format' };
  }
}

isPrivateIP(ip) {
  // Implementar verificación de rangos privados
  const privateRanges = [
    /^10\./,
    /^172\.(1[6-9]|2[0-9]|3[0-1])\./,
    /^192\.168\./,
    /^127\./,
    /^0\./,
    /^::1$/,
    /^fc00:/i,
    /^fe80:/i
  ];
  return privateRanges.some(range => range.test(ip));
}
```

**Por qué:** Previene Server-Side Request Forgery (SSRF) attacks.

---

### 6. Context Memory Validation
```javascript
// Verificar que los datos en memoria no han sido alterados
validateMemoryIntegrity() {
  const criticalFiles = [
    path.join(process.env.HOME, '.clawdbot/clawdbot.json'),
    path.join(process.env.HOME, 'clawd/SOUL.md'),
    path.join(process.env.HOME, 'clawd/AGENTS.md')
  ];
  
  const checksums = {};
  for (const file of criticalFiles) {
    if (fs.existsSync(file)) {
      const content = fs.readFileSync(file);
      checksums[file] = require('crypto').createHash('sha256').update(content).digest('hex');
    }
  }
  
  // Guardar checksums
  const checksumFile = path.join(process.env.HOME, 'clawd/.security/checksums.json');
  fs.mkdirSync(path.dirname(checksumFile), { recursive: true });
  
  if (fs.existsSync(checksumFile)) {
    const previous = JSON.parse(fs.readFileSync(checksumFile, 'utf8'));
    
    // Verificar cambios
    for (const [file, currentHash] of Object.entries(checksums)) {
      if (previous[file] && previous[file] !== currentHash) {
        console.warn(`⚠️  SECURITY: ${file} ha sido modificado`);
        // Notificar pero no bloquear (puede ser legítimo)
      }
    }
  }
  
  fs.writeFileSync(checksumFile, JSON.stringify(checksums, null, 2));
}
```

**Por qué:** Detecta modificaciones no autorizadas en archivos críticos.

---

## 📋 Checklist de Implementación

- [ ] Rate limiting por fuente
- [ ] Content hashing para replay detection
- [ ] Validación de skills pre-instalación
- [ ] Sanitización de output
- [ ] Validación de URLs (SSRF protection)
- [ ] Memory integrity checks
- [ ] Tests automatizados para cada protección
- [ ] Documentación de incidentes de seguridad

---

## 🔗 Referencias

- Post de eudaemon_0 en Moltbook sobre supply chain attacks
- Post de ClawdNottsOps31 sobre gateway security
- Mejores prácticas OWASP para LLM/AI applications
