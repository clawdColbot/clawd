#!/usr/bin/env python3
"""
consistent-character-framework.py - Framework para generación de personajes consistentes

Este framework permite generar datasets de imágenes consistentes de un personaje
usando FLUX 2 + técnicas de prompting avanzado.

Basado en el proyecto "Isabela" - Generación de modelo consistente.
"""

import json
import os
from pathlib import Path
from typing import List, Dict, Optional
from dataclasses import dataclass, asdict
from datetime import datetime

@dataclass
class CharacterConfig:
    """Configuración de personaje para generación consistente"""
    name: str
    description: str
    base_prompt: str
    negative_prompt: str = ""
    
    # Atributos consistentes (no cambian entre imágenes)
    physical_traits: Dict[str, str] = None
    clothing_base: str = ""
    
    # Atributos variables (cambian según la imagen)
    poses: List[str] = None
    expressions: List[str] = None
    backgrounds: List[str] = None
    lighting: List[str] = None
    
    def __post_init__(self):
        if self.physical_traits is None:
            self.physical_traits = {}
        if self.poses is None:
            self.poses = []
        if self.expressions is None:
            self.expressions = []
        if self.backgrounds is None:
            self.backgrounds = []
        if self.lighting is None:
            self.lighting = []

class ConsistentCharacterGenerator:
    """
    Generador de personajes consistentes usando FLUX 2
    
    Estrategia:
    1. Prompt base con descripción física detallada
    2. Variaciones controladas (pose, expresión, fondo, luz)
    3. Negative prompt para evitar inconsistencias
    4. Seed management para reproducibilidad
    """
    
    def __init__(self, config: CharacterConfig, output_dir: str = "./dataset"):
        self.config = config
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Metadata del dataset
        self.metadata = {
            "character": config.name,
            "created_at": datetime.now().isoformat(),
            "total_images": 0,
            "variations": {}
        }
    
    def build_prompt(self, 
                     pose: Optional[str] = None,
                     expression: Optional[str] = None,
                     background: Optional[str] = None,
                     lighting: Optional[str] = None) -> str:
        """
        Construir prompt completo combinando elementos consistentes y variables
        """
        parts = [self.config.base_prompt]
        
        # Añadir atributos físicos consistentes
        if self.config.physical_traits:
            traits = ", ".join([f"{k}: {v}" for k, v in self.config.physical_traits.items()])
            parts.append(f"Physical traits: {traits}")
        
        # Añadir variaciones
        if pose:
            parts.append(f"pose: {pose}")
        if expression:
            parts.append(f"expression: {expression}")
        if background:
            parts.append(f"background: {background}")
        if lighting:
            parts.append(f"lighting: {lighting}")
        
        # Ropa base (consistente)
        if self.config.clothing_base:
            parts.append(f"wearing: {self.config.clothing_base}")
        
        # Añadir calidad técnica
        parts.append("high quality, detailed, professional photography")
        
        return ", ".join(parts)
    
    def generate_variation_matrix(self) -> List[Dict]:
        """
        Generar matriz de todas las combinaciones posibles
        """
        variations = []
        
        poses = self.config.poses or ["neutral"]
        expressions = self.config.expressions or ["neutral"]
        backgrounds = self.config.backgrounds or ["studio"]
        lightings = self.config.lighting or ["soft"]
        
        for pose in poses:
            for expression in expressions:
                for background in backgrounds:
                    for lighting in lightings:
                        variations.append({
                            "pose": pose,
                            "expression": expression,
                            "background": background,
                            "lighting": lighting
                        })
        
        return variations
    
    def generate_dataset_plan(self, max_images: int = 100) -> Dict:
        """
        Crear plan de dataset con distribución balanceada
        """
        variations = self.generate_variation_matrix()
        
        # Calcular cuántas imágenes por variación
        if len(variations) > max_images:
            # Seleccionar subset representativo
            import random
            random.seed(42)  # Reproducible
            selected = random.sample(variations, max_images)
        else:
            selected = variations
        
        plan = {
            "character": self.config.name,
            "total_planned": len(selected),
            "variations": selected,
            "output_directory": str(self.output_dir),
            "generation_date": datetime.now().isoformat()
        }
        
        return plan
    
    def export_training_config(self) -> str:
        """
        Exportar configuración para entrenamiento (Kohya-ss, etc.)
        """
        config = {
            "model_arguments": {
                "pretrained_model_name_or_path": "black-forest-labs/FLUX.2-dev",
                "vae": "black-forest-labs/FLUX.2-dev/vae"
            },
            "dataset_arguments": {
                "debug_dataset": False,
                "training_comment": f"Training {self.config.name} character",
                "keep_tokens": 1,
                "caption_extension": ".txt"
            },
            "training_arguments": {
                "output_dir": str(self.output_dir / "output"),
                "output_name": self.config.name.lower().replace(" ", "_"),
                "save_precision": "fp16",
                "num_train_epochs": 10,
                "max_train_steps": 1000,
                "learning_rate": 1e-4,
                "optimizer_type": "AdamW8bit",
                "lr_scheduler": "constant_with_warmup",
                "lr_warmup_steps": 100
            },
            "sampling_arguments": {
                "sample_every_n_epochs": 2,
                "sample_prompts": self._generate_sample_prompts()
            }
        }
        
        output_file = self.output_dir / "training_config.json"
        with open(output_file, 'w') as f:
            json.dump(config, f, indent=2)
        
        return str(output_file)
    
    def _generate_sample_prompts(self) -> List[str]:
        """Generar prompts de ejemplo para sampling durante entrenamiento"""
        prompts = []
        
        # Algunas variaciones representativas
        test_combinations = [
            {"pose": "standing", "expression": "smiling", "background": "studio"},
            {"pose": "sitting", "expression": "neutral", "background": "office"},
            {"pose": "walking", "expression": "happy", "background": "street"},
        ]
        
        for combo in test_combinations:
            prompt = self.build_prompt(**combo)
            prompts.append(prompt)
        
        return prompts
    
    def create_documentation(self) -> str:
        """Crear documentación completa del framework"""
        
        doc = f"""# Consistent Character Generation Framework

## Personaje: {self.config.name}

### Descripción
{self.config.description}

### Prompt Base
```
{self.config.base_prompt}
```

### Atributos Consistentes
"""
        
        if self.config.physical_traits:
            doc += "\n**Rasgos Físicos:**\n"
            for trait, value in self.config.physical_traits.items():
                doc += f"- {trait}: {value}\n"
        
        if self.config.clothing_base:
            doc += f"\n**Ropa Base:** {self.config.clothing_base}\n"
        
        doc += f"""

### Atributos Variables

**Poses ({len(self.config.poses)}):**
"""
        for pose in self.config.poses[:10]:  # Limitar a 10
            doc += f"- {pose}\n"
        
        doc += f"""

**Expresiones ({len(self.config.expressions)}):**
"""
        for expr in self.config.expressions[:10]:
            doc += f"- {expr}\n"
        
        doc += f"""

**Fondos ({len(self.config.backgrounds)}):**
"""
        for bg in self.config.backgrounds[:10]:
            doc += f"- {bg}\n"
        
        doc += f"""

**Iluminación ({len(self.config.lighting)}):**
"""
        for light in self.config.lighting[:10]:
            doc += f"- {light}\n"
        
        doc += """

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
"""
        
        return doc

def create_example_isabela_config() -> CharacterConfig:
    """Crear configuración de ejemplo basada en Isabela"""
    
    return CharacterConfig(
        name="Isabela",
        description="Professional young woman for corporate training materials",
        base_prompt="professional young woman, high quality portrait, detailed face",
        negative_prompt="blurry, low quality, deformed, ugly, duplicate",
        
        physical_traits={
            "age": "25-30",
            "hair": "long dark brown hair",
            "eyes": "brown eyes",
            "skin": "medium skin tone",
            "build": "slim build"
        },
        
        clothing_base="professional business attire, navy blazer",
        
        poses=[
            "standing straight",
            "standing relaxed",
            "sitting upright",
            "leaning slightly",
            "arms crossed",
            "hands on hips",
            "one hand raised",
            "walking",
            "seated at desk",
            "presenting gesture"
        ],
        
        expressions=[
            "neutral professional",
            "slight smile",
            "confident smile",
            "thoughtful",
            "attentive listening",
            "encouraging",
            "explaining",
            "focused"
        ],
        
        backgrounds=[
            "modern office",
            "conference room",
            "clean studio white",
            "blurred office background",
            "minimalist interior",
            "bookshelf background",
            "window natural light",
            "plain gradient"
        ],
        
        lighting=[
            "soft studio lighting",
            "natural window light",
            "professional three-point",
            "warm indoor lighting",
            "bright even lighting"
        ]
    )

# Ejemplo de uso
if __name__ == "__main__":
    print("=" * 60)
    print("🎨 CONSISTENT CHARACTER FRAMEWORK")
    print("=" * 60)
    print()
    
    # Crear configuración de ejemplo
    config = create_example_isabela_config()
    
    print(f"📝 Personaje: {config.name}")
    print(f"📝 Descripción: {config.description}")
    print()
    
    # Crear generador
    generator = ConsistentCharacterGenerator(config, output_dir="./isabela_dataset")
    
    # Generar plan
    print("📊 Generando plan de dataset...")
    plan = generator.generate_dataset_plan(max_images=50)
    print(f"   ✅ Plan generado: {plan['total_planned']} imágenes")
    print()
    
    # Exportar config
    print("⚙️  Exportando configuración de entrenamiento...")
    config_file = generator.export_training_config()
    print(f"   ✅ Config guardada: {config_file}")
    print()
    
    # Crear documentación
    print("📚 Creando documentación...")
    doc = generator.create_documentation()
    doc_file = generator.output_dir / "README.md"
    with open(doc_file, 'w') as f:
        f.write(doc)
    print(f"   ✅ Documentación guardada: {doc_file}")
    print()
    
    # Ejemplo de prompt
    print("💡 Ejemplo de prompt generado:")
    print("-" * 60)
    sample_prompt = generator.build_prompt(
        pose="standing straight",
        expression="confident smile",
        background="modern office",
        lighting="soft studio lighting"
    )
    print(sample_prompt)
    print("-" * 60)
    print()
    
    print("=" * 60)
    print("✅ Framework inicializado")
    print(f"📁 Archivos guardados en: {generator.output_dir}")
    print("=" * 60)
