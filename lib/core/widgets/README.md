# Core Widgets - Arquitectura Reorganizada

Esta carpeta contiene todos los widgets reutilizables de la aplicación, organizados por categorías según las mejores prácticas de Flutter y Material 3.

## ✅ **MIGRACIÓN COMPLETADA** 

Todos los widgets de `ComponentApp` legacy han sido migrados exitosamente a la nueva estructura organizada. El archivo legacy ha sido eliminado y todas las referencias actualizadas.

**📋 Estado de Migración:**
- ✅ 10/10 widgets migrados y mejorados
- ✅ Material Design 3 implementado
- ✅ Clean Architecture aplicada
- ✅ Documentación completa de migración disponible
- ✅ Archivo legacy eliminado completamente
- ✅ Referencias actualizadas en todos los archivos

**🔗 Ver guía completa:** `component_app_migration_guide.dart`

## 📁 Estructura de Carpetasuitectura Reorganizada

Esta carpeta contiene todos los widgets reutilizables de la aplicación, organizados por categorías según las mejores prácticas de Flutter y Material 3.

## ✅ **MIGRACIÓN COMPLETADA** 

Todos los widgets de `ComponentApp` legacy han sido migrados exitosamente a la nueva estructura organizada. 

**📋 Estado de Migración:**
- ✅ 10/10 widgets migrados y mejorados
- ✅ Material Design 3 implementado
- ✅ Clean Architecture aplicada
- ✅ Documentación completa de migración disponible
- ✅ Archivo legacy marcado como deprecado

**🔗 Ver guía completa:** `component_app_migration_guide.dart`

## 📁 Estructura de Carpetas

### 🔘 `buttons/`
Contiene todos los botones y controles de acción:
- `app_button.dart` - Botón principal de la aplicación
- `app_bar_button.dart` - Botón especializado para AppBar
- `search_button.dart` - Botón de búsqueda con diseño adaptativo
- `app_floating_action_button.dart` - FloatingActionButton personalizado

### 📝 `inputs/`
Campos de entrada y formularios:
- `input_text_field.dart` - TextField base con Material 3
- `money_input_text_field.dart` - Campo especializado para montos

### 💬 `dialogs/`
Diálogos y modales especializados:
- `product_edit_dialog.dart` - Editar productos en el ticket
- `add_product_dialog.dart` - Agregar productos al catálogo
- `quick_sale_dialog.dart` - Diálogo de venta rápida
- `printer_config_dialog.dart` - Configuración de impresora
- `ticket_options_dialog.dart` - Opciones del ticket

### 🎨 `ui/`
Componentes básicos de interfaz:
- `dividers.dart` - Divisores y separadores
- `user_avatar.dart` - Avatar circular de usuario
- `image_widget.dart` - Componente de imagen de producto
- `progress_indicators.dart` - Indicadores de progreso

### 🖼️ `media/`
Componentes multimedia (reexporta UI relacionados):
- `media_widgets.dart` - Exportaciones de widgets multimedia

### 📢 `feedback/`
Sistema de feedback y notificaciones:
- `app_feedback.dart` - SnackBars y mensajes del sistema

## 🚀 Uso Recomendado

### Importación por Categoría
```dart
// Importar una categoría completa
import 'package:sellweb/core/widgets/buttons/buttons.dart';
import 'package:sellweb/core/widgets/inputs/inputs.dart';

// Importar widget específico
import 'package:sellweb/core/widgets/buttons/app_button.dart';
import 'package:sellweb/core/widgets/ui/user_avatar.dart';
```

### Importación Completa
```dart
// Importar todos los widgets core
import 'package:sellweb/core/widgets/core_widgets.dart';
```

### Ejemplos de Uso

#### Botón Principal (Unificado)
```dart
// Botón básico
AppButton(
  text: 'Guardar',
  onPressed: () => _save(),
  backgroundColor: Colors.blue,
  icon: Icon(Icons.save),
)

// Botón con estado de carga
AppButton(
  text: 'Procesar',
  onPressed: () => _process(),
  isLoading: isProcessing,
  backgroundColor: Colors.green,
)

// Botón primario (factory constructor)
AppButton.primary(
  text: 'Confirmar',
  onPressed: () => _confirm(),
  isLoading: isConfirming,
  backgroundColor: Colors.blue,
)
```

#### Campo de Texto
```dart
InputTextField(
  controller: _controller,
  labelText: 'Nombre',
  hintText: 'Ingrese su nombre',
)
```

#### Avatar de Usuario
```dart
UserAvatar(
  imageUrl: user.profilePicture,
  text: user.name,
  radius: 24,
)
```

#### Mostrar Diálogo
```dart
showProductEditDialog(
  context,
  producto: selectedProduct,
  onProductUpdated: () => _refreshList(),
)
```

#### Feedback al Usuario
```dart
AppFeedback.showSuccess(
  context,
  title: 'Éxito',
  message: 'Producto guardado correctamente',
)
```

## 🔄 Compatibilidad

### Archivo Legacy
Se mantiene `component_app_legacy.dart` para compatibilidad hacia atrás con código existente, pero se recomienda migrar a los nuevos widgets específicos.

### Migración Gradual
1. Usar `core_widgets.dart` para importar todo
2. Gradualmente reemplazar `ComponentApp()` con widgets específicos
3. Actualizar imports para usar categorías específicas

## ✅ Beneficios de la Nueva Estructura

- **Mejor organización**: Widgets agrupados por funcionalidad
- **Imports más limpios**: Solo importar lo necesario
- **Mantenibilidad**: Easier to find and update widgets
- **Escalabilidad**: Fácil agregar nuevos widgets en categorías
- **Tree-shaking**: Mejor optimización del bundle
- **Clean Architecture**: Separación clara de responsabilidades

## 📋 Checklist de Migración

- [x] Crear estructura de carpetas por categorías
- [x] Separar widgets por responsabilidad
- [x] Mantener compatibilidad legacy
- [x] Crear archivos de exportación
- [x] Documentar nueva estructura
- [ ] Actualizar imports en archivos existentes
- [ ] Migrar ComponentApp() calls gradualmente
- [ ] Agregar tests unitarios por categoría

## 🛠️ Convenciones

### Nomenclatura
- Archivos: `snake_case.dart`
- Clases: `PascalCase`
- Widgets: Prefijo `App` para widgets principales

### Estructura de Archivo
```dart
// Imports de Flutter primero
import 'package:flutter/material.dart';

// Imports de paquetes externos
import 'package:provider/provider.dart';

// Imports internos (relativos)
import '../ui/user_avatar.dart';

// Imports del dominio/presentación
import 'package:sellweb/domain/entities/user.dart';

/// Documentación del widget
class AppWidget extends StatelessWidget {
  // Constructor y parámetros
  // Build method
  // Helper methods privados
}
```

### Material 3
- Usar `ColorScheme` del theme
- Preferir `withValues(alpha:)` sobre `withOpacity()`
- Implementar estados interactivos con `WidgetStateProperty`
- Seguir guías de espaciado y tipografía de Material 3

## 🔄 **BOTÓN UNIFICADO** - Nueva Funcionalidad

### ✅ Unificación de AppButton y PrimaryButton

Se ha realizado una unificación completa de los componentes de botón para simplificar el uso y mantener consistencia:

#### 📋 **Antes** (Múltiples componentes)
```dart
// Tres componentes separados
AppButton(text: 'Botón básico', onPressed: () {});
PrimaryButton(text: 'Botón primario', onPressed: () {}, isLoading: true);
```

#### ✅ **Ahora** (Componente unificado)
```dart
// Un solo componente con todas las funcionalidades
AppButton(
  text: 'Botón completo',
  onPressed: () {},
  isLoading: true,
  icon: Icon(Icons.save),
  backgroundColor: Colors.blue,
);

// Constructor factory para compatibilidad
AppButton.primary(
  text: 'Botón primario',
  onPressed: () {},
  isLoading: true,
);
```

#### 🎯 **Características del Botón Unificado**
- ✅ **Estado de carga** con indicador visual
- ✅ **Soporte para iconos** con tamaño personalizable
- ✅ **Material Design 3** completo
- ✅ **Animaciones suaves** entre estados
- ✅ **Compatibilidad total** con el código existente
- ✅ **Factory constructor** para migración sin breaking changes

#### 🔧 **Migración Automática**
- El código existente funciona sin cambios
- `PrimaryButton` está marcado como `@Deprecated`
- Se recomienda migrar a `AppButton.primary()` gradualmente
