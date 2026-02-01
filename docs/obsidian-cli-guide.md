# 📝 Obsidian CLI - Guía de Uso

## Estado de Instalación

✅ **Binario instalado:** `~/go/bin/obsidian-cli` (v0.2.2)
⚠️ **Limitación:** Requiere Obsidian Desktop (no disponible en WSL/Linux sin GUI)

## Instalación Completada

```bash
# Go instalado en: ~/.local/go/
# obsidian-cli instalado en: ~/go/bin/

# Agregar a ~/.bashrc o ~/.zshrc:
export PATH="$PATH:$HOME/.local/go/bin:$HOME/go/bin"
```

## Comandos Disponibles

```bash
# Ver ayuda
obsidian-cli --help

# Configurar vault por defecto (requiere Obsidian Desktop instalado)
obsidian-cli set-default "nombre-del-vault"
obsidian-cli sd "nombre-del-vault"

# Buscar notas (fuzzy finder)
obsidian-cli search
obsidian-cli s

# Buscar en contenido
obsidian-cli search-content "término"
obsidian-cli sc "término"

# Crear nota
obsidian-cli create "Nombre de Nota" --content "Contenido inicial"
obsidian-cli c "Nombre de Nota" --content "Contenido"

# Crear daily note
obsidian-cli daily
obsidian-cli d

# Abrir nota
obsidian-cli open "Nombre de Nota"
obsidian-cli o "Nombre de Nota"

# Mover/renombrar (actualiza links)
obsidian-cli move "nota-antigua" "nota-nueva"
obsidian-cli m "nota-antigua" "nota-nueva"

# Ver contenido
obsidian-cli print "Nombre de Nota"
obsidian-cli p "Nombre de Nota"

# Modificar frontmatter
obsidian-cli frontmatter "Nombre de Nota" --add etiquetas "valor1,valor2"
obsidian-cli fm "Nombre de Nota" --add etiquetas "valor1,valor2"

# Borrar nota
obsidian-cli delete "Nombre de Nota"
```

## Configuración

### 1. Vault por Defecto

```bash
# Listar vaults (desde obsidian.json)
obsidian-cli print-default

# Configurar vault por defecto
obsidian-cli set-default "Mi Vault"
```

### 2. Estructura de obsidian.json

Ubicación:
- **macOS:** `~/Library/Application Support/obsidian/obsidian.json`
- **Linux:** `~/.config/obsidian/obsidian.json`

Ejemplo:
```json
{
  "vaults": {
    "mi-vault-id": {
      "path": "/Users/usuario/Documents/Obsidian/Mi Vault",
      "open": true
    }
  }
}
```

## Uso desde Clawd

Cuando tengas Obsidian Desktop funcionando, puedes usar el skill así:

```bash
# Buscar notas
obsidian-cli search

# Crear nota con contenido
obsidian-cli create "Ideas/Proyecto Nuevo" --content "# Proyecto Nuevo\n\nIdeas iniciales..."

# Buscar en contenido
obsidian-cli search-content "clave de API"
```

## Alternativa para WSL/Linux sin GUI

Como Obsidian-cli requiere Obsidian Desktop, alternativas para gestión de notas Markdown:

1. **Uso directo de archivos:**
   ```bash
   # Crear nota manualmente
   echo "# Título\n\nContenido" >> ~/vault/nota.md
   
   # Buscar en notas
   grep -r "término" ~/vault/
   
   # Listar notas
   ls -la ~/vault/
   ```

2. **Usar mcporter + filesystem:**
   ```bash
   # Ya configurado
   ~/clawd/tools/mcp-call.sh filesystem list_directory '{"path": "/home/durango/clawd"}'
   ```

## Notas

- obsidian-cli v0.2.2 instalado vía `go install github.com/Yakitrak/obsidian-cli@latest`
- Go 1.22.0 instalado en `~/.local/go/`
- Para uso completo, instalar Obsidian Desktop desde: https://obsidian.md/
