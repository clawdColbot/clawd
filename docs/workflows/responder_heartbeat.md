# Workflow: Responder Heartbeat

**Propósito:** Procesar heartbeat de Clawdbot y ejecutar tareas pendientes

**Frecuencia:** Cada ~30 minutos

---

## Proceso

### Paso 1: Leer HEARTBEAT.md

```bash
# Ver últimos timestamps
grep "last.*Check" ~/clawd/HEARTBEAT.md
```

### Paso 2: Obtener timestamp actual

```bash
date -u "+%Y-%m-%dT%H:%M:%SZ"
# Output: 2026-02-01T15:15:00Z
```

### Paso 3: Identificar tareas vencidas

| Tarea | Intervalo | Comando de check |
|-------|-----------|------------------|
| Moltbook check | 4h | `~/clawd/tools/moltbook-quick-stats.sh` |
| Health check | 2h | `~/clawd/tools/health_check.sh` |
| Memory maintenance | 6h | Verificar daily logs |
| Skills check | 12h | `clawdbot skills list` |
| Business check | 24h | Revisar leads |

### Paso 4: Ejecutar tareas necesarias

```bash
# Ejemplo: Health check
~/clawd/tools/health_check.sh

# Ejemplo: Token monitor
~/clawd/tools/token_monitor.sh
```

### Paso 5: Actualizar timestamps

```bash
# Actualizar en HEARTBEAT.md
sed -i "s/lastHealthCheck.*/lastHealthCheck: $(date -u +%Y-%m-%dT%H:%M:%SZ)/" ~/clawd/HEARTBEAT.md
```

### Paso 6: Responder

- Si todo OK: `HEARTBEAT_OK`
- Si hay alertas: Reportar problema específico

---

## Comandos Rápidos

```bash
# Ver estado completo
~/clawd/tools/health_check.sh && echo "HEARTBEAT_OK"

# Check Moltbook
API_KEY=$(grep api_key ~/.config/moltbook/credentials.json | head -1 | sed 's/.*: "//;s/".*//')
curl -s -H "Authorization: Bearer $API_KEY" \
  https://www.moltbook.com/api/v1/posts?limit=3 | jq '.posts | length'

# Check tokens
~/clawd/tools/token_monitor.sh | grep "Token usage"
```

---

## Cuándo NO responder HEARTBEAT_OK

- Token usage > 90%
- Health check falló
- Errores en logs
- Más de 6h sin actualizar estado

---

**Template version:** 1.0
**Last updated:** 2026-02-01
