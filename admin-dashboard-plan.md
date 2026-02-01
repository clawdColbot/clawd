# 📋 Planificación: Panel de Administración (Admin Dashboard)

## 🎯 Objetivo
Crear un panel de administración donde Gloria Carvajal pueda:
- Subir/borrar fotos de propiedades
- Crear/editar/eliminar propiedades
- Gestionar todas las propiedades desde un solo lugar

---

## 🛠️ Tecnología Recomendada: Supabase

### ¿Por qué Supabase?
| Feature | Beneficio |
|---------|-----------|
| **Base de datos PostgreSQL** | Gratuita, escalable, confiable |
| **Storage** | Almacenamiento de imágenes (fotos de propiedades) |
| **Auth** | Autenticación segura para Gloria |
| **API REST auto-generada** | No necesitas backend propio |
| **Real-time** | Cambios en tiempo real |
| **Gratis hasta 500MB** | Suficiente para empezar |

---

## 📁 Estructura del Proyecto Admin

```
propiedades-mvp/
├── index.html              # Sitio público (cliente)
├── propiedad.html          # Detalle propiedad (cliente)
├── admin/                  # NUEVO: Panel de administración
│   ├── index.html          # Login de admin
│   ├── dashboard.html      # Dashboard principal
│   ├── propiedades.html    # Lista de propiedades
│   ├── propiedad-edit.html # Crear/editar propiedad
│   ├── css/
│   │   └── admin.css
│   └── js/
│       ├── supabase.js     # Configuración de Supabase
│       ├── auth.js         # Autenticación
│       └── properties.js   # CRUD de propiedades
```

---

## 🗄️ Esquema de Base de Datos (Supabase)

### Tabla: `propiedades`
```sql
create table propiedades (
  id uuid default gen_random_uuid() primary key,
  titulo text not null,
  precio bigint not null,
  habitaciones integer not null,
  banos integer not null,
  metros integer not null,
  tipo text not null, -- 'casa' | 'apartamento' | 'local' | 'terreno'
  direccion text not null,
  latitud decimal(10,8),
  longitud decimal(11,8),
  descripcion text,
  estado text, -- 'nueva' | 'destacada' | null
  activo boolean default true,
  created_at timestamp default now(),
  updated_at timestamp default now()
);
```

### Tabla: `propiedad_imagenes`
```sql
create table propiedad_imagenes (
  id uuid default gen_random_uuid() primary key,
  propiedad_id uuid references propiedades(id) on delete cascade,
  url text not null,
  orden integer default 0,
  created_at timestamp default now()
);
```

### Storage: `fotos-propiedades`
- Bucket para almacenar imágenes
- Estructura: `propiedades/{propiedad_id}/{imagen_id}.jpg`

---

## 🔐 Autenticación

### Solo un usuario (Gloria):
- Email: `gloria@propiedades.com`
- Password: (configurado por ti)

### Protección de rutas:
```javascript
// Redirigir a login si no está autenticada
if (!user) {
  window.location.href = '/admin/';
}
```

---

## 🎨 Diseño del Admin

### 1. Login (`/admin/index.html`)
- Logo de Propiedades
- Input: Email
- Input: Password
- Botón: Iniciar sesión
- Link: "Volver al sitio público"

### 2. Dashboard (`/admin/dashboard.html`)
- Sidebar navegación:
  - 🏠 Dashboard
  - 🏢 Propiedades
  - ➕ Nueva propiedad
  - ⚙️ Configuración
- Stats cards:
  - Total propiedades
  - Propiedades nuevas (este mes)
  - Propiedades destacadas
- Lista de últimas propiedades editadas

### 3. Lista de Propiedades (`/admin/propiedades.html`)
- Tabla con:
  - Foto principal (thumbnail)
  - Título
  - Precio
  - Tipo
  - Estado (activo/inactivo)
  - Acciones: Ver | Editar | Eliminar
- Filtros:
  - Por tipo (casa/apartamento/local/terreno)
  - Por estado (activo/inactivo)
- Botón: "+ Nueva Propiedad"

### 4. Crear/Editar Propiedad (`/admin/propiedad-edit.html?id=xxx`)
Formulario con:
- **Datos básicos:**
  - Título
  - Precio (COP)
  - Tipo (select)
  - Habitaciones
  - Baños
  - Metros cuadrados
  - Dirección
  
- **Ubicación:**
  - Mapa interactivo para seleccionar ubicación
  - O inputs para latitud/longitud
  
- **Descripción:**
  - Textarea con editor simple
  
- **Fotos:**
  - Drag & drop para subir múltiples fotos
  - Preview de fotos subidas
  - Reordenar fotos (drag)
  - Eliminar fotos individuales
  - Foto principal destacada
  
- **Estado:**
  - Checkbox: Activo/Inactivo
  - Checkbox: Destacada
  - Checkbox: Nueva

- **Botones:**
  - Guardar cambios
  - Vista previa
  - Cancelar

---

## 📸 Gestión de Fotos

### Subida múltiple:
```javascript
// Ejemplo de código
const uploadPhotos = async (files, propiedadId) => {
  for (const file of files) {
    const fileName = `${Date.now()}_${file.name}`;
    const { data, error } = await supabase.storage
      .from('fotos-propiedades')
      .upload(`${propiedadId}/${fileName}`, file);
    
    if (data) {
      // Guardar URL en tabla propiedad_imagenes
      await supabase.from('propiedad_imagenes').insert({
        propiedad_id: propiedadId,
        url: data.path,
        orden: index
      });
    }
  }
};
```

### Features:
- ✅ Subir hasta 10 fotos a la vez
- ✅ Compresión automática de imágenes
- ✅ Preview antes de subir
- ✅ Reordenar con drag & drop
- ✅ Eliminar foto individual
- ✅ Marcar foto principal

---

## 💰 Costos Estimados (Supabase)

| Plan | Precio | Incluye |
|------|--------|---------|
| **Free** | $0/mes | 500MB DB + 1GB Storage + 2M requests/mes |
| **Pro** | $25/mes | 8GB DB + 100GB Storage + Unlimited |

**Para empezar:** El plan Free es suficiente.

---

## 🚀 Plan de Implementación

### Fase 1: Setup Supabase (30 min)
1. Crear cuenta en supabase.com
2. Crear nuevo proyecto
3. Crear tablas (propiedades, propiedad_imagenes)
4. Crear bucket de storage
5. Configurar autenticación
6. Obtener API keys

### Fase 2: Auth & Layout (1 hora)
1. Crear página de login
2. Crear layout del admin (sidebar + header)
3. Implementar protección de rutas
4. Configurar Supabase client

### Fase 3: CRUD Propiedades (2 horas)
1. Listar propiedades
2. Formulario crear/editar
3. Eliminar propiedad
4. Activar/desactivar propiedad

### Fase 4: Gestión de Fotos (2 horas)
1. Subida múltiple de fotos
2. Preview y reordenamiento
3. Eliminar fotos
4. Integrar con Storage

### Fase 5: Testing & Deploy (30 min)
1. Probar todo el flujo
2. Deploy a GitHub Pages
3. Configurar CORS en Supabase

**Tiempo total estimado:** ~6 horas de desarrollo

---

## 🔧 Configuración Inicial Requerida

### 1. Crear proyecto en Supabase:
```bash
# Ir a https://supabase.com
# Crear cuenta
# Nuevo proyecto: "propiedades-medellin"
```

### 2. SQL Inicial:
```sql
-- Crear tabla propiedades
CREATE TABLE propiedades (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  titulo TEXT NOT NULL,
  precio BIGINT NOT NULL,
  habitaciones INTEGER NOT NULL DEFAULT 0,
  banos INTEGER NOT NULL DEFAULT 0,
  metros INTEGER NOT NULL DEFAULT 0,
  tipo TEXT NOT NULL CHECK (tipo IN ('casa', 'apartamento', 'local', 'terreno')),
  direccion TEXT NOT NULL,
  latitud DECIMAL(10,8),
  longitud DECIMAL(11,8),
  descripcion TEXT,
  estado TEXT CHECK (estado IN ('nueva', 'destacada')),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Crear tabla imagenes
CREATE TABLE propiedad_imagenes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  propiedad_id UUID REFERENCES propiedades(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  orden INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Crear bucket storage
-- Ir a Storage > New Bucket: "fotos-propiedades"
-- Policy: public read, authenticated write
```

### 3. Variables de entorno:
```javascript
const SUPABASE_URL = 'https://xxxxx.supabase.co';
const SUPABASE_KEY = 'eyJxxxxx';
```

---

## ✅ Próximos Pasos

1. **¿Creo el proyecto de Supabase?** (necesito que me des permiso para usar tu email)
2. **¿Empezamos con el panel de admin?**
3. **¿Tienes preferencia de colores para el admin?** (o usamos los mismos que el sitio público)

¿Quieres que proceda con la configuración de Supabase? 🦊