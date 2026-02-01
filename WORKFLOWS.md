# WORKFLOWS.md - Procesos Repeatable

**Propósito:** Documentar procesos estándar para consistencia y onboarding.

**Nota:** Los workflows detallados ahora viven en `docs/workflows/`. Este archivo es un índice rápido.

---

## Workflows Disponibles

| Workflow | Archivo | Descripción |
|----------|---------|-------------|
| 🚀 **Shipyard New Repo** | [docs/workflows/shipyard_new_repo.md](docs/workflows/shipyard_new_repo.md) | Crear repo GitHub + registrar en Shipyard |
| 🔄 **Responder Heartbeat** | [docs/workflows/responder_heartbeat.md](docs/workflows/responder_heartbeat.md) | Procesar heartbeat de Clawdbot |
| 📝 **Crear Checkpoint** | [docs/workflows/crear_checkpoint.md](docs/workflows/crear_checkpoint.md) | Capturar estado antes de compartimentación |
| 🐛 **Debug Problemas** | [docs/workflows/debug_problemas.md](docs/workflows/debug_problemas.md) | Resolver problemas (patrón curl repro) |
| 🆘 **Escalación** | [docs/workflows/escalacion.md](docs/workflows/escalacion.md) | Cuándo preguntar vs actuar solo |

---

## Templates

Para nuevos proyectos/scripts:

| Template | Uso |
|----------|-----|
| [templates/script.sh.template](templates/script.sh.template) | Nuevo script bash (BBP compliant) |
| [templates/script.py.template](templates/script.py.template) | Nuevo script Python (BBP compliant) |
| [templates/README.md.template](templates/README.md.template) | README para nuevos repos |

---

## Decisiones Arquitectónicas

Registros de decisiones importantes:

| ADR | Descripción |
|-----|-------------|
| [ADR-001](docs/decisions/ADR-001-boring-builder-protocol.md) | Adopción del Boring Builder Protocol |

---

## Regla de Oro

> **Si no estás seguro, documenta la incertidumbre y pregunta.**

Mejor perder 2 minutos confirmando que horas arreglando un error.

---

**Last updated:** 2026-02-01
