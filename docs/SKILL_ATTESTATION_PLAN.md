# 🛡️ Skill Attestation Registry - Plan de Implementación

**Basado en:** Dragon_Bot_Z en Moltbook  
**Objetivo:** Registrar security-guard.js como skill auditado on-chain

---

## 📋 Qué es Skill Attestation Registry

Sistema Solidity en Base L2 para:
- Hash de skills (content-addressed como IPFS)
- Auditors registrados crean attestations
- Revocación si se encuentran vulnerabilidades
- Historial inmutable on-chain

**Costo:** ~$0.001 por attestation en Base L2

---

## 🔧 Plan de Implementación

### Fase 1: Preparar el Skill (Ahora)

1. **Documentar security-guard.js:**
   - README completo
   - Ejemplos de uso
   - Patrones de rechazo documentados
   - Tests

2. **Crear repositorio estructurado:**
   ```
   security-guard-v2/
   ├── security-guard.js      # Código principal
   ├── README.md              # Documentación
   ├── examples/              # Ejemplos de uso
   ├── tests/                 # Tests
   └── SKILL.md               # Metadata para ClawdHub
   ```

3. **Calcular hash del contenido:**
   ```bash
   sha256sum security-guard.js
   ```

### Fase 2: Deploy del Contrato (Pendiente)

**Requisitos:**
- Cuenta en Base L2 con ETH
- Foundry o Hardhat para deploy
- Contrato SkillAttestationRegistry

**Contrato base:**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SkillAttestationRegistry {
    struct Attestation {
        bytes32 skillHash;
        string metadataURI;
        address auditor;
        uint256 timestamp;
        bool revoked;
    }
    
    mapping(bytes32 => Attestation[]) public attestations;
    mapping(address => bool) public registeredAuditors;
    
    function attest(bytes32 skillHash, string memory metadataURI) external;
    function revoke(bytes32 skillHash, uint256 attestationId) external;
    function isVerified(bytes32 skillHash) external view returns (bool);
}
```

**Repo de referencia:** https://github.com/dragon-bot-z/skill-attestations

### Fase 3: Obtener Attestations (Después del deploy)

Necesitamos 3 attestations para verificación:

1. **Self-attestation** - Nosotros mismos
2. **Community audit** - Otro agente confiable (e.g., eudaemon_0)
3. **Third-party** - Otro auditor

**Proceso:**
- Compartir skill en Moltbook /builds
- Solicitar reviews de otros agents
- Documentar findings

### Fase 4: Integración con ClawdHub (Futuro)

Propuesta para ClawdHub:
```bash
clawdhub install security-guard --verify
# Verifica attestations on-chain antes de instalar
```

---

## 📁 Archivos a Crear

### 1. SKILL.md para ClawdHub
```markdown
---
name: security-guard-v2
description: Anti-prompt injection protection for AI agents
author: ClawdColombia
attestations:
  - type: onchain
    chain: base
    contract: 0x...
    hash: 0x...
permissions:
  - filesystem: read-only
  - network: none
---
```

### 2. Documentación de seguridad
- Patrones de detección
- Cómo valida inputs
- Limitaciones conocidas

### 3. Tests
- Casos de inyección conocidos
- Falsos positivos
- Edge cases

---

## 💰 Costos Estimados

| Item | Costo |
|------|-------|
| Deploy contrato | ~$0.50-1.00 (Base L2) |
| Attestation | ~$0.001 cada una |
| Metadata storage | IPFS (gratis) o Arweave |

**Total estimado:** <$5 para setup completo

---

## 🎯 Próximos Pasos

1. [ ] Completar documentación de security-guard-v2
2. [ ] Agregar tests al repo
3. [ ] Calcular hash final del skill
4. [ ] Decidir si deployamos contrato propio o usamos uno existente
5. [ ] Solicitar community audits en Moltbook

---

## 🔗 Recursos

- **Repo base:** https://github.com/dragon-bot-z/skill-attestations
- **Post original:** Moltbook - /builds - Dragon_Bot_Z
- **Red:** Base L2 (cheap, fast)

---

**Estado:** Plan creado, esperando decisión de Andres para ejecutar.
