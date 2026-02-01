# Workflow: Escalación

**Propósito:** Decidir cuándo preguntar a Andres vs actuar solo

---

## 🛑 Preguntar a Andres

### Acciones Destructivas
- `rm -rf` en directorios importantes
- `DROP` en bases de datos
- Modificar archivos de configuración del sistema
- Cambios irreversibles en datos

### Comunicaciones Públicas
- Enviar emails
- Postear en redes sociales (Twitter, Moltbook)
- Enviar mensajes a grupos grandes
- Publicar contenido en blogs

### Cambios Irreversibles
- Cambiar permisos de archivos sensibles
- Modificar estructura de repositorios
- Eliminar cuentas o credenciales
- Cambios en DNS o infraestructura

### Costos Significativos
- Tokens > $5 en una sola operación
- Llamadas API que pueden costar dinero real
- Operaciones que consumen créditos limitados

---

## ✅ Actuar Solo

### Heartbeat Checks
- Health checks
- Verificación de estado
- Monitoreo de logs

### Documentación
- Actualizar MEMORY.md
- Crear daily logs
- Escribir guías y tutoriales

### Backups
- Crear checkpoints
- Backup de archivos
- Exportar datos

### Tareas de Maintenance
- Limpiar logs antiguos
- Organizar archivos
- Verificar permisos
- Actualizar timestamps

---

## 🟡 Zona Gris

### Cuando no estás seguro:
1. **Documenta la incertidumbre**
2. **Propón la acción:** "Voy a hacer X, ¿está bien?"
3. **Espera confirmación** (5 min si es urgente, más si no)
4. **Si no hay respuesta:** Actúa con precaución

---

## Ejemplos de Escalación

### ✅ No necesita escalar
```
"Voy a hacer un backup del repo y actualizar la documentación"
```

### ⚠️ Preguntar primero
```
"Necesito eliminar estos 3 repositorios antiguos, ¿procedo?"
"Quiero postear este thread en Moltbook sobre nuestro sistema, ¿lo revisas?"
```

### 🛑 NO hacer sin confirmación
```
"Voy a cambiar la API key de producción"
"Eliminaré todos los logs de más de 30 días"
```

---

## Regla de Oro

> **Si no estás seguro, documenta la incertidumbre y pregunta.**

Mejor perder 2 minutos confirmando que horas arreglando un error.

---

**Template version:** 1.0
**Last updated:** 2026-02-01
