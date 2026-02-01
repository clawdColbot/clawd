# 🦊 Clawd - Capacidades y Skills Disponibles

*Documento de referencia rápida para maximizar el uso de herramientas*

---

## ✅ Skills Activados (Disponibles Ahora)

| Skill | Emoji | Descripción | Uso Principal |
|-------|-------|-------------|---------------|
| **bird** | 🐦 | X/Twitter CLI | Leer, buscar, postear, engagement |
| **bluebubbles** | 💬 | BlueBubbles (iMessage) | Enviar/recibir SMS/iMessage |
| **github** | 🐙 | GitHub CLI (gh) | Issues, PRs, CI runs, API queries |
| **mcporter** | 📦 | MCP servers | Conectar herramientas externas vía MCP |
| **notion** | 📝 | Notion API | Crear páginas, bases de datos, bloques |
| **slack** | 💼 | Slack integration | React, pin, control de Slack |
| **tmux** | 🖥️ | Tmux remote control | Controlar sesiones tmux interactivas |
| **weather** | 🌤️ | Weather data | Clima actual y pronósticos |
| **skill-creator** | 🛠️ | Crear skills | Diseñar y empaquetar nuevos skills |
| **canvas** | 🎨 | Canvas control | Presentar/navegar/evaluar canvas |

---

## 🔧 Skills de Código y Desarrollo

### coding-agent
- **Qué hace:** Ejecuta Codex, Claude Code, OpenCode o Pi como agentes de código
- **Cómo usar:** `exec` con `pty:true` y `command:"codex exec 'prompt'"`
- **Requiere:** Instalar `claude`, `codex`, `opencode` o `pi` CLI
- **Nota:** Siempre usar modo PTY para agentes interactivos

### mcporter (MCP Servers) - ✅ CONFIGURADO
- **Estado:** Activo con 3 servidores MCP configurados
- **Config:** `~/clawd/config/mcporter.json`
- **Helper:** `~/clawd/tools/mcp-call.sh` para uso fácil

**Servidores configurados:**

| Servidor | Estado | Herramientas |
|----------|--------|--------------|
| **filesystem** | ✅ Active | 14 tools (read, write, edit, list, search, tree) |
| **brave-search** | ✅ Active | web_search, local_search (BRAVE_API_KEY configurada) |
| **github** | ⏳ Needs Key | repos, issues, PRs, code search (necesita `GITHUB_TOKEN`) |

**Uso rápido:**
```bash
# Filesystem
~/clawd/tools/mcp-call.sh filesystem list_directory '{"path": "/home/durango/clawd"}'
~/clawd/tools/mcp-call.sh filesystem search_files '{"path": "/home/durango/clawd", "pattern": "**/*.md"}'
~/clawd/tools/mcp-call.sh filesystem read_text_file '{"path": "/home/durango/clawd/README.md"}'

# Brave Search
~/clawd/tools/mcp-call.sh brave-search brave_web_search '{"query": "tu búsqueda"}'
~/clawd/tools/mcp-call.sh brave-search brave_local_search '{"query": "restaurantes", "location": "Bogota"}'
```

**Comandos mcporter nativos:**
- `mcporter list` - Ver servidores configurados
- `mcporter config list` - Ver configuración
- `mcporter call <server.tool> key=value` - Llamar herramientas

---

## 🎨 Creación de Contenido

### openai-image-gen
- **Qué hace:** Genera imágenes con DALL-E y GPT-image
- **Comando:** `python3 scripts/gen.py --prompt "..." --count 4`
- **Modelos:** gpt-image-1, dall-e-3, dall-e-2
- **Requiere:** `OPENAI_API_KEY`

### sag (ElevenLabs TTS)
- **Qué hace:** Texto a voz con calidad profesional
- **Comando:** `sag "texto"` o `sag speak -v "Roger" "texto"`
- **Características:** 
  - Voz emotiva: `[whispers]`, `[shouts]`, `[laughs]`, `[sarcastic]`
  - Modelos: v3 (expresivo), v2.5 (rápido)
- **Requiere:** `ELEVENLABS_API_KEY`

### openai-whisper / openai-whisper-api
- **Qué hace:** Transcripción de audio
- **Uso:** Convertir audio a texto para procesamiento

---

## 📚 Gestión de Conocimiento

### obsidian - ✅ INSTALADO (limitado)
- **Qué hace:** Trabajar con vaults de Obsidian (Markdown notes)
- **Estado:** ✅ `obsidian-cli` v0.2.2 instalado en `~/go/bin/`
- **Limitación:** Requiere Obsidian Desktop (no disponible en WSL)
- **Guía:** `~/clawd/docs/obsidian-cli-guide.md`

**Instalación realizada:**
```bash
# Go instalado en ~/.local/go/
# obsidian-cli instalado vía: go install github.com/Yakitrak/obsidian-cli@latest

# Agregar a PATH:
export PATH="$PATH:$HOME/.local/go/bin:$HOME/go/bin"
```

**Comandos disponibles:**
```bash
obsidian-cli search              # Fuzzy finder de notas
obsidian-cli search-content      # Buscar en contenido
obsidian-cli create "Nota"       # Crear nota
obsidian-cli move "old" "new"      # Mover/renombrar
obsidian-cli daily               # Abrir daily note
```

### notion
- **Qué hace:** Integración completa con Notion
- **Capacidades:** Crear páginas, bases de datos, gestionar bloques
- **Ya disponible** ✅

---

## 📧 Comunicación

### himalaya - ⏳ PENDIENTE INSTALACIÓN
- **Qué hace:** Cliente email CLI vía IMAP/SMTP
- **Capacidades:** Listar, leer, escribir, responder, buscar emails
- **Estado:** ✅ Config lista | ⏳ Binario pendiente
- **Guía:** `~/clawd/docs/himalaya-install-guide.md`

**Instalación rápida:**
```bash
# Descargar desde releases
curl -LO https://github.com/pimalaya/himalaya/releases/download/v1.1.0/himalaya-x86_64-unknown-linux-musl.tar.gz
tar xzf himalaya-x86_64-unknown-linux-musl.tar.gz
mv himalaya ~/.local/bin/

# Configurar
cp ~/clawd/config/himalaya-config.example.toml ~/.config/himalaya/config.toml
nano ~/.clawd/config/himalaya-config.example.toml  # Editar email/credenciales
```

### bird (Twitter/X)
- **Qué hace:** Control completo de X/Twitter
- **Ya disponible** ✅

### bluebubbles
- **Qué hace:** iMessage/SMS vía BlueBubbles
- **Ya disponible** ✅

### slack
- **Qué hace:** Integración con Slack
- **Ya disponible** ✅

### voice-call
- **Qué hace:** Realizar llamadas de voz
- **Potencial:** Llamadas automatizadas o interactivas

---

## 🎵 Multimedia y Entretenimiento

### spotify-player
- **Qué hace:** Controlar Spotify desde CLI
- **Potencial:** Reproducir música, gestionar playlists

### sonoscli
- **Qué hade:** Controlar sistemas Sonos
- **Uso:** Audio en casa/oficina

### gifgrep
- **Qué hace:** Buscar GIFs
- **Uso:** Respuestas rápidas con GIFs apropiados

### video-frames
- **Qué hace:** Extraer frames de videos
- **Uso:** Análisis de video, thumbnails

---

## 🛠️ Productividad y Automatización

### 1password
- **Qué hace:** Acceso a contraseñas vía 1Password CLI
- **Uso:** Seguridad, autenticación automatizada
- **Requiere:** 1Password CLI configurado

### apple-notes / apple-reminders
- **Qué hace:** Integración con apps nativas de Apple
- **Uso:** Sincronización de notas y recordatorios

### trello
- **Qué hace:** Gestión de tableros Trello
- **Uso:** Proyectos Kanban, organización visual

### things-mac
- **Qué hace:** Integración con Things (task manager)
- **Uso:** Gestión de tareas GTD

---

## 🤖 Modelos de IA Adicionales

### gemini
- **Qué hace:** Acceso a modelos Gemini de Google
- **Uso:** Modelos alternativos para diversas tareas

### oracle
- **Qué hace:** Acceso a modelos Oracle
- **Uso:** Capacidades adicionales de IA

---

## 🌐 Búsqueda y Datos

### goplaces / local-places
- **Qué hace:** Búsqueda de lugares locales
- **Uso:** Encontrar restaurantes, servicios, etc.

### blogwatcher
- **Qué hace:** Monitorear blogs y feeds
- **Uso:** Seguimiento de fuentes de información

### summarize
- **Qué hace:** Resumir contenido
- **Uso:** Compresión de información

---

## 📋 Próximos Pasos de Activación

### Prioridad Alta (Mayor Impacto)

1. **mcporter + MCP Servers**
   - Instalar: `npm install -g mcporter`
   - Configurar servidores MCP útiles
   - Potencial: Herramientas ilimitadas vía MCP

2. **sag (ElevenLabs TTS)**
   - Instalar: `brew install steipete/tap/sag`
   - Configurar: `ELEVENLABS_API_KEY`
   - Uso inmediato: Respuestas de voz, storytelling

3. **openai-image-gen**
   - Verificar: `OPENAI_API_KEY` configurada
   - Uso: Generar imágenes para proyectos

### Prioridad Media

4. **coding-agent**
   - Instalar algún agente: `codex`, `claude`, `opencode` o `pi`
   - Uso: Tareas de código complejas en background

5. **himalaya**
   - Instalar: `brew install himalaya`
   - Configurar: Cuentas de email en `~/.config/himalaya/config.toml`
   - Uso: Gestión de emails sin salir del flujo

6. **obsidian**
   - Instalar: `brew install yakitrak/yakitrak/obsidian-cli`
   - Configurar: Vault por defecto
   - Uso: Gestión de conocimiento personal

### Prioridad Baja (Cuando se necesite)

7. **1password** - Cuando se necesite gestión de secrets
8. **spotify-player** - Cuando se quiera control de música
9. **voice-call** - Cuando se necesiten llamadas

---

## 📝 Notas

- **Seguridad:** Nunca exponer API keys en logs o mensajes públicos
- **Configuración:** Guardar credenciales en `~/.config/` o variables de entorno
- **Heartbeat:** Revisar periódicamente nuevos skills en clawdhub.com
- **MCP:** mcporter es la clave para expansión ilimitada de herramientas

---

*Última actualización: 2026-01-30*
*Versión: 1.0*
