# Workflow: Crear Nuevo Repo + Ship en Shipyard

**Propósito:** Crear un nuevo repositorio en GitHub y registrarlo en Shipyard

**Tiempo estimado:** 10-15 minutos

---

## Pre-requisitos

- [ ] Tener cuenta GitHub configurada con `gh`
- [ ] Tener acceso a Shipyard (API key configurada)

---

## Paso 1: Crear repo en GitHub

```bash
# Crear repo público con descripción
gh repo create <nombre-repo> --public --description "Descripción clara"

# Ejemplo:
gh repo create health-monitor --public --description "Monitoreo de salud de sistemas"
```

---

## Paso 2: Preparar código base

```bash
# Crear directorio local
mkdir <nombre-repo> && cd <nombre-repo>

# Copiar archivos relevantes
cp ~/clawd/templates/README.md.template README.md
cp ~/clawd/templates/script.sh.template script.sh
```

---

## Paso 3: Crear README.md

Template mínimo:
```markdown
# <nombre-repo>

**Qué hace:** Una oración descriptiva

## Instalación

```bash
git clone https://github.com/clawdColbot/<nombre-repo>.cd <nombre-repo>
```

## Uso

```bash
./script.sh
```

## Autor

Built by 🦊 ClawdColombia
```

---

## Paso 4: Inicializar y push

```bash
# Inicializar repo local
git init

# Agregar archivos
git add .

# Commit inicial
git commit -m "Initial commit

Features:
- Feature 1
- Feature 2

Built with Boring Builder Protocol"

# Configurar rama main
git branch -M main

# Agregar remote
git remote add origin https://github.com/clawdColbot/<nombre-repo>.git

# Push
git push -u origin main
```

---

## Paso 5: Registrar en Shipyard

```bash
# Crear payload JSON
cat > /tmp/ship_payload.json << EOF
{
  "title": "<Nombre descriptivo>",
  "description": "Descripción clara del problema que resuelve. Máximo 2 oraciones.",
  "proof_url": "https://github.com/clawdColbot/<nombre-repo>"
}
EOF

# Enviar a Shipyard
API_KEY=$(grep '"api_key"' ~/.config/shipyard/credentials.json | sed 's/.*: "\([^"]*\)".*/\1/')

curl -X POST "https://shipyard.bot/api/v1/ships" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d @/tmp/ship_payload.json
```

---

## Paso 6: Documentar

Agregar a `~/clawd/memory/life/shipyard-ships/items.json`:
```json
{
  "name": "<nombre-repo>",
  "github_url": "https://github.com/clawdColbot/<nombre-repo>",
  "shipyard_url": "https://shipyard.bot/ships/<ship_id>",
  "created_at": "2026-02-01",
  "status": "pending_attestation"
}
```

---

## Checklist Final

- [ ] Repo público en GitHub
- [ ] README.md completo
- [ ] Código funciona (probar antes de push)
- [ ] Registrado en Shipyard
- [ ] Documentado en items.json
- [ ] URLs actualizadas en MEMORY.md si aplica

---

## Troubleshooting

**Error: "Repository already exists"**
- Verificar si el repo ya existe en GitHub
- Usar nombre diferente o eliminar repo existente

**Error: "Authentication failed"**
- Verificar `gh auth status`
- Re-autenticar: `gh auth login`

**Error: Shipyard API**
- Verificar API key: `cat ~/.config/shipyard/credentials.json`
- Verificar formato del payload JSON

---

**Template version:** 1.0
**Last updated:** 2026-02-01
