# 🔄 Migración de Marcas: /MARCAS → /BRANDS

## 📋 Resumen

Script de migración para refactorizar la colección de marcas en Firestore de `/APP/ARG/MARCAS` a `/APP/ARG/BRANDS` con normalización del campo `description`.

## 🎯 Objetivos

1. **Migrar colección**: Mover todos los documentos de `/MARCAS` a `/BRANDS`
2. **Normalizar datos**: Convertir el campo `description` a minúsculas para mejorar búsquedas compuestas
3. **Mantener integridad**: Preservar todos los datos y timestamps originales
4. **Progreso visual**: Mostrar dialog con barra de progreso y estadísticas en tiempo real

## 📁 Archivos Creados

### Core Services
- `lib/core/services/migration/brand_migration_service.dart`
  - Servicio principal de migración
  - Procesa documentos en batches
  - Normaliza datos automáticamente
  - Validación post-migración

### Core Providers
- `lib/core/presentation/providers/brand_migration_provider.dart`
  - Gestión de estado de la migración
  - Notificación de progreso
  - Manejo de errores

### Core Dialogs
- `lib/core/presentation/dialogs/brand_migration_dialog.dart`
  - UI con progreso visual
  - Estadísticas en tiempo real
  - Lista de errores (si existen)
  - Confirmación para eliminar colección antigua

## 🔧 Cambios en Código Existente

### Actualizaciones de Rutas

#### `firestore_paths.dart`
```dart
// Antes
static String brands({String country = 'ARG'}) => '/APP/$country/MARCAS';

// Después
static String brands({String country = 'ARG'}) => '/APP/$country/BRANDS';
```

#### `storage_paths.dart`
```dart
// Antes
static String publicBrandImage(String brandId, {String country = 'ARG'}) =>
    'APP/$country/MARCAS/$brandId.jpg';

// Después
static String publicBrandImage(String brandId, {String country = 'ARG'}) =>
    'APP/$country/BRANDS/$brandId.jpg';
```

### Botón Temporal

Se agregó un botón temporal en `product_edit_catalogue_view.dart` para iniciar la migración:

```dart
// 🔧 BOTÓN TEMPORAL en AppBar
IconButton(
  icon: const Icon(Icons.sync_alt, color: Colors.orange),
  tooltip: 'Migrar marcas /MARCAS → /BRANDS',
  onPressed: _showBrandMigrationDialog,
)
```

**⚠️ IMPORTANTE**: Este botón debe ser **REMOVIDO** después de completar la migración.

## 🚀 Cómo Ejecutar la Migración

### Paso 1: Preparación
1. **Hacer backup** de la base de datos Firestore (recomendado)
2. Verificar que tienes permisos de escritura en Firestore
3. Asegurarse de tener buena conexión a internet

### Paso 2: Iniciar Migración
1. Navegar a cualquier pantalla de edición de productos
2. Hacer clic en el botón naranja de migración (ícono de sincronización) en el AppBar
3. El dialog se abrirá automáticamente e iniciará la migración

### Paso 3: Monitorear Progreso
El dialog mostrará:
- ✅ Barra de progreso animada
- 📊 Contador de documentos procesados
- ✅ Número de migraciones exitosas
- ❌ Número de fallos (si los hay)
- 🔄 Mapeo de IDs antiguos → nuevos (ver en detalle)
- 📝 Lista detallada de errores

### Paso 4: Validación
Después de completar la migración:
1. Revisar las estadísticas finales
2. Verificar que `success` == `total`
3. Si hay errores, revisar la lista y corregir manualmente

### Paso 5: Eliminar Colección Antigua
**⚠️ SOLO después de validar que todo está correcto:**
1. Hacer clic en "Eliminar colección antigua" en el dialog
2. Confirmar la eliminación en el dialog de confirmación
3. La colección `/MARCAS` será eliminada permanentemente

### Paso 6: Limpieza
1. **Remover el botón temporal** de `product_edit_catalogue_view.dart`
2. Eliminar imports relacionados con la migración
3. Opcionalmente, mover los archivos de migración a un directorio de archive

## 📊 Transformación de Datos

### Antes (Colección /MARCAS)
```json
{
  "id": "1640995200000",
  "name": "Nike",
  "description": "Marca Deportiva Premium",
  "image": "https://...",
  "verified": true,
  "creation": "2024-01-01T00:00:00Z",
  "upgrade": "2024-12-15T00:00:00Z"
}
```

### Después (Colección /BRANDS)
```json
{
  "id": "BRD-ABCDE-20251215-0123",  // ⬅️ Nuevo ID generado con IdGenerator
  "name": "nike",                     // ⬅️ Normalizado a minúsculas
  "description": "marca deportiva premium",  // ⬅️ Normalizado a minúsculas
  "image": "https://...",
  "verified": true,
  "creation": "2024-01-01T00:00:00Z",
  "upgrade": "2024-12-15T00:00:00Z"
}
```

## 🔍 Características de Normalización y Generación de IDs

### Normalización de Campos
Ambos campos `name` y `description` son normalizados para mejorar búsquedas:
- **Convertido a minúsculas**: `"Nike"` → `"nike"`, `"Marca Premium"` → `"marca premium"`
- **Espacios eliminados al inicio/final**: `" Nike "` → `"nike"`
- **Facilita búsquedas case-insensitive** y compuestas

### Generación de Nuevos IDs
Se utiliza `IdGenerator.generateBrandId()` para crear IDs consistentes:
- **Formato**: `BRD-SALT-YYYYMMDD-NNNN`
- **Componentes**:
  - `BRD`: Prefijo de marca
  - `SALT`: Salt aleatorio (3 caracteres)
  - `YYYYMMDD`: Fecha de creación
  - `NNNN`: Secuencia única del día
- **Ejemplo**: `BRD-X8Y-20251215-0001`

### Mapeo de IDs
El servicio mantiene un mapeo de IDs antiguos → nuevos:
```json
{
  "1640995200000": "BRD-A3F9K-20251215-0001",
  "1640995300000": "BRD-A3F9K-20251215-0002",
  ...
}
```

Este mapeo es accesible en el dialog de migración para referencia y auditoría.

## ⚠️ Consideraciones Importantes

### Rendimiento
- La migración procesa en batches de 500 documentos
- Para colecciones grandes (>5000 marcas), puede tomar varios minutos
- No cerrar el dialog durante la migración

### Errores Comunes
1. **Permisos insuficientes**: Verificar reglas de Firestore
2. **Conexión perdida**: Reintentar la migración
3. **Documentos duplicados**: Se sobrescriben automáticamente

### Rollback
Si necesitas revertir la migración:
1. La colección antigua `/MARCAS` permanece intacta hasta que la elimines manualmente
2. Puedes volver a cambiar las rutas en el código
3. No se recomienda hacer doble migración (puede duplicar datos)

## 🧹 Limpieza Post-Migración

### Código para Remover

1. **En `product_edit_catalogue_view.dart`**:
   ```dart
   // REMOVER estos imports:
   import 'package:sellweb/core/presentation/providers/brand_migration_provider.dart';
   import 'package:sellweb/core/presentation/dialogs/brand_migration_dialog.dart';
   
   // REMOVER este botón del AppBar actions:
   if (!_isSaving)
     IconButton(
       icon: const Icon(Icons.sync_alt, color: Colors.orange),
       tooltip: 'Migrar marcas /MARCAS → /BRANDS',
       onPressed: _showBrandMigrationDialog,
     ),
   
   // REMOVER este método:
   Future<void> _showBrandMigrationDialog() async { ... }
   ```

2. **En `firestore_paths.dart`** (opcional):
   ```dart
   // REMOVER el método deprecated:
   @Deprecated('Usar brands() en su lugar. Esta colección será eliminada.')
   static String brandsOld({String country = 'ARG'}) => '/APP/$country/MARCAS';
   ```

### Archivos para Archivar (opcional)

Puedes mover estos archivos a un directorio de archive:
```
lib/core/services/migration/
lib/core/presentation/providers/brand_migration_provider.dart
lib/core/presentation/dialogs/brand_migration_dialog.dart
```

O eliminarlos completamente si ya no necesitas la funcionalidad.
## 📝 Checklist de Migración

- [ ] Hacer backup de Firestore
- [ ] Ejecutar migración desde el botón temporal
- [ ] Verificar estadísticas (success == total)
- [ ] **Exportar/guardar mapeo de IDs antiguos → nuevos** (importante para referencias)
- [ ] Validar que las búsquedas funcionan correctamente con campos normalizados
- [ ] Verificar que nuevas marcas usan `IdGenerator.generateBrandId()`
- [ ] Eliminar colección antigua `/MARCAS`
- [ ] Actualizar referencias a IDs antiguos en otras colecciones (si aplica)
- [ ] Remover botón temporal del código
- [ ] Remover imports de migración
- [ ] Archivar o eliminar archivos de migración
- [ ] Actualizar documentación del proyecto
- [ ] Commit de cambiosntación del proyecto
- [ ] Commit de cambios

## 🐛 Resolución de Problemas

### La migración no inicia
- Verificar conexión a internet
- Revisar permisos de Firestore
- Verificar que el provider está correctamente inyectado

### Errores durante la migración
- Revisar la lista de errores en el dialog
- Verificar logs de consola para más detalles
- Corregir manualmente los documentos problemáticos
- Reintentar la migración

### Búsquedas no funcionan después de migración
- Verificar que todas las referencias usan `/BRANDS`
- Limpiar caché de la aplicación
- Verificar índices de Firestore

## 📞 Soporte

Si encuentras problemas durante la migración:
1. Revisar logs de consola
2. Verificar estadísticas en el dialog
3. Documentar el error específico
4. No eliminar la colección antigua hasta validar

---

**Fecha de creación**: 15 de diciembre de 2025
**Versión**: 1.0.0
**Estado**: ✅ Listo para producción
