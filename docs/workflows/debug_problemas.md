# Workflow: Debug de Problemas

**Propósito:** Resolver problemas siguiendo el patrón "curl repro"

**Principio:** Reduce a curl repro - Un comando que demuestre el problema

---

## Patrón: Reduce a curl repro

### Paso 1: Crear reproducción mínima

```bash
# En lugar de:
./mi-script-complejo.sh --config archivo.conf --output result.log --flag1 --flag2

# Reducir a:
curl -s https://api.ejemplo.com/endpoint | jq '.field'
```

### Paso 2: Eliminar variables innecesarias

- Remover flags opcionales
- Usar valores por defecto
- Eliminar dependencias externas

### Paso 3: Documentar pasos exactos

```markdown
## Repro Steps
1. Ejecutar: `curl -s https://api.example.com/broken`
2. Esperar: 5 segundos
3. Observar: Error 500
```

### Paso 4: Probar en entorno limpio

```bash
# Fresh terminal, no variables de entorno
env -i bash --norc --noprofile
# Probar el comando aquí
```

---

## Ejemplos

### Ejemplo 1: API no responde

```bash
# ❌ No reproducible
./fetch_data.py --config production.yaml --user admin

# ✅ Reproducible
curl -s --max-time 5 https://api.service.com/health
```

### Ejemplo 2: Script falla

```bash
# ❌ No reproducible
./backup.sh /home/user/data /mnt/backup --compress

# ✅ Reproducible
bash -x ./backup.sh 2>&1 | head -20
```

---

## Checklist de Debugging

- [ ] Tengo un comando de 1 línea que reproduce el problema?
- [ ] El comando funciona en entorno limpio?
- [ ] Eliminé todas las variables innecesarias?
- [ ] Documenté los pasos exactos?
- [ ] Puedo explicar el problema a alguien más con este comando?

---

## Troubleshooting Común

### Error de permisos
```bash
# Debug
ls -la archivo
id
```

### Error de red
```bash
# Debug
curl -v https://api.example.com
ping api.example.com
```

### Error de dependencias
```bash
# Debug
which python3
python3 --version
pip list | grep nombre-paquete
```

---

**Template version:** 1.0
**Last updated:** 2026-02-01
