# 📧 Himalaya Email Client - Guía de Instalación

## Estado

⏳ **Pendiente instalación de binario**
✅ **Configuración lista:** `~/clawd/config/himalaya-config.example.toml`

## Métodos de Instalación

### Opción 1: Descargar Binario Pre-compilado (Recomendado)

```bash
# Ir a releases de GitHub
# https://github.com/pimalaya/himalaya/releases

# Descargar versión para Linux
cd /tmp
curl -LO https://github.com/pimalaya/himalaya/releases/download/v1.1.0/himalaya-x86_64-unknown-linux-musl.tar.gz

# Extraer
tar xzf himalaya-x86_64-unknown-linux-musl.tar.gz

# Mover a bin
mv himalaya ~/.local/bin/
chmod +x ~/.local/bin/himalaya

# Verificar
himalaya --version
```

### Opción 2: Instalar con Cargo (Rust)

```bash
# Instalar Rust/cargo primero
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Instalar himalaya
cargo install himalaya

# O clonar y compilar
git clone https://github.com/pimalaya/himalaya.git
cd himalaya
cargo build --release
mv target/release/himalaya ~/.local/bin/
```

### Opción 3: Usar Nix

```bash
nix-env -iA nixpkgs.himalaya
```

## Configuración

### 1. Crear directorio de configuración

```bash
mkdir -p ~/.config/himalaya
```

### 2. Copiar configuración de ejemplo

```bash
cp ~/clawd/config/himalaya-config.example.toml ~/.config/himalaya/config.toml
```

### 3. Editar con tus credenciales

```bash
nano ~/.config/himalaya/config.toml
```

Cambiar:
- `TU_EMAIL@gmail.com` → tu email real
- Método de autenticación (recomendado: app password de Gmail)

### 4. Configurar App Password (Gmail)

1. Ir a https://myaccount.google.com/security
2. Activar "2-Step Verification" (obligatorio para app passwords)
3. Buscar "App passwords"
4. Generar password para "Mail"
5. Usar esa contraseña en la config (no tu password normal)

## Comandos Básicos

```bash
# Ver cuentas configuradas
himalaya account list

# Ver emails (bandeja de entrada)
himalaya

# Ver carpetas
himalaya folder list

# Leer email específico
himalaya read 123

# Escribir email
himalaya write

# Responder
himalaya reply 123

# Reenviar
himalaya forward 123

# Buscar
himalaya search "from:ejemplo@gmail.com"

# Ver en formato JSON (para scripts)
himalaya --output json

# Modo interactivo (TUI)
himalaya envelope list
```

## Integración con Clawd

Una vez configurado, puedes usar Himalaya desde Clawd:

```bash
# Ver emails nuevos
himalaya | head -20

# Buscar emails específicos
himalaya search "subject:proyecto"

# Enviar email rápido
echo "Contenido" | himalaya write --to destino@email.com --subject "Asunto"
```

## Solución de Problemas

### Error: "authentication failed"
- Verifica que usas App Password (no tu password normal de Gmail)
- Asegúrate de tener 2FA activado en Gmail

### Error: "connection refused"
- Verifica que IMAP está habilitado en Gmail
- Revisa firewall/ports

### Error: "certificate verify failed"
```bash
# Actualizar certificados
sudo apt-get update && sudo apt-get install ca-certificates
```

## Recursos

- **GitHub:** https://github.com/pimalaya/himalaya
- **Documentación:** https://pimalaya.org/himalaya/
- **Configuración completa:** https://github.com/pimalaya/himalaya/blob/master/config.sample.toml
