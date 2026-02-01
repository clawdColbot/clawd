# Consistent Character Generation Framework

## Personaje: Isabela

### Descripción
Professional young woman for corporate training materials

### Prompt Base
```
professional young woman, high quality portrait, detailed face
```

### Atributos Consistentes

**Rasgos Físicos:**
- age: 25-30
- hair: long dark brown hair
- eyes: brown eyes
- skin: medium skin tone
- build: slim build

**Ropa Base:** professional business attire, navy blazer


### Atributos Variables

**Poses (10):**
- standing straight
- standing relaxed
- sitting upright
- leaning slightly
- arms crossed
- hands on hips
- one hand raised
- walking
- seated at desk
- presenting gesture


**Expresiones (8):**
- neutral professional
- slight smile
- confident smile
- thoughtful
- attentive listening
- encouraging
- explaining
- focused


**Fondos (8):**
- modern office
- conference room
- clean studio white
- blurred office background
- minimalist interior
- bookshelf background
- window natural light
- plain gradient


**Iluminación (5):**
- soft studio lighting
- natural window light
- professional three-point
- warm indoor lighting
- bright even lighting


## Uso

### 1. Generar Plan de Dataset
```python
from consistent_character_framework import CharacterConfig, ConsistentCharacterGenerator

config = CharacterConfig(
    name="Isabela",
    description="Young professional woman",
    base_prompt="...",
    # ... configuración completa
)

generator = ConsistentCharacterGenerator(config, output_dir="./isabela_dataset")
plan = generator.generate_dataset_plan(max_images=100)
```

### 2. Exportar Config de Entrenamiento
```python
config_file = generator.export_training_config()
```

### 3. Generar Prompts
```python
prompt = generator.build_prompt(
    pose="standing",
    expression="smiling",
    background="office",
    lighting="natural"
)
```

## Estrategia de Consistencia

1. **Prompt Base Fijo**: Define identidad del personaje
2. **Atributos Consistentes**: No cambian (rasgos físicos, ropa base)
3. **Atributos Variables**: Cambian controladamente (pose, expresión, fondo)
4. **Negative Prompt**: Evita características no deseadas
5. **Seed Management**: Permite reproducibilidad

## Variaciones Totales

Con la configuración actual:
- Poses: {len(self.config.poses)}
- Expresiones: {len(self.config.expressions)}
- Fondos: {len(self.config.backgrounds)}
- Iluminación: {len(self.config.lighting)}

**Total de combinaciones posibles: {len(self.config.poses) * len(self.config.expressions) * len(self.config.backgrounds) * len(self.config.lighting)}**

## Referencias

- FLUX 2: https://blackforestlabs.ai/
- Kohya-ss: https://github.com/kohya-ss/sd-scripts
- Consistent Characters Research: [Añadir papers relevantes]

---

*Framework generado: {datetime.now().strftime('%Y-%m-%d %H:%M')}*
