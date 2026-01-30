#!/usr/bin/env node
/**
 * validate-input.js - Wrapper rápido para validación de seguridad
 * Uso: node validate-input.js "texto a validar" [fuente]
 */

const SecurityGuard = require('./security-guard.js');

const input = process.argv[2] || '';
const source = process.argv[3] || 'unknown';

if (!input) {
  console.log('Uso: node validate-input.js "texto a validar" [fuente]');
  console.log('Fuentes: confirmed_human_andres, moltbook, web, email, unknown');
  process.exit(1);
}

const guard = new SecurityGuard();
const result = guard.validate(input, source);

console.log(JSON.stringify(result, null, 2));
process.exit(result.valid ? 0 : 1);
