# Core Widgets - Estructura Reorganizada

Esta carpeta contiene todos los widgets reutilizables de la aplicación, organizados siguiendo los principios de Clean Architecture y las mejores prácticas de Flutter/Material Design 3.

## 📁 Estructura Reorganizada

```
/core/widgets/
├── README.md                    # Este archivo - Documentación principal
├── core_widgets.dart           # Exportaciones centralizadas
├── buttons/                    # Botones y controles de acción
│   ├── README.md               # Documentación de botones
│   ├── buttons.dart            # Exportaciones de botones
│   ├── app_button.dart         # Botón principal unificado
│   ├── app_bar_button.dart     # Botón para AppBar
│   ├── app_floating_action_button.dart # FAB personalizado
│   ├── app_text_button.dart    # Botón de texto
│   ├── search_button.dart      # Botón de búsqueda
│   └── theme_control_buttons.dart # Controles de tema
├── inputs/                     # Campos de entrada y formularios
│   ├── README.md               # Documentación de inputs
│   ├── inputs.dart             # Exportaciones de inputs
│   ├── input_text_field.dart   # Campo de texto base
│   └── money_input_text_field.dart # Campo para montos
├── dialogs/                    # Sistema completo de diálogos
│   ├── README.md               # Documentación de diálogos
│   ├── dialogs.dart            # Exportaciones principales
│   ├── base/                   # Componentes base para diálogos
│   ├── catalogue/              # Diálogos del catálogo
│   ├── components/             # Componentes reutilizables
│   ├── configuration/          # Diálogos de configuración
│   ├── examples/               # Ejemplos y plantillas
│   ├── feedback/               # Diálogos de feedback
│   ├── sales/                  # Diálogos de ventas
│   └── tickets/                # Diálogos de tickets
├── component/                  # Componentes básicos de UI
│   ├── README.md               # Documentación de componentes
│   ├── ui.dart                 # Exportaciones de UI
│   ├── user_avatar.dart        # Avatar de usuario
│   ├── avatar_product.dart     # Avatar de producto
│   ├── image.dart              # Widgets de imagen
│   ├── dividers.dart           # Divisores y separadores
│   └── progress_indicators.dart # Indicadores de progreso
├── feedback/                   # Sistema de feedback
│   ├── README.md               # Documentación de feedback
│   └── feedback.dart           # Widgets de feedback
├── media/                      # Widgets multimedia
│   ├── README.md               # Documentación de media
│   └── media_widgets.dart      # Reexportaciones
├── responsive/                 # Widgets responsive (legacy - migrar)
│   └── responsive_widgets.dart
└── drawer/                     # Navegación lateral (legacy - migrar)
    └── drawer_widgets.dart
```
## 🎯 Propósito y Filosofía

### Clean Architecture Compliance
Los widgets siguen estrictamente los principios de Clean Architecture:

- **Independencia**: No dependen de lógica de negocio específica
- **Reutilización**: Pueden usarse en cualquier parte de la aplicación
- **Responsabilidad única**: Cada widget tiene un propósito claro
- **Extensibilidad**: Fáciles de extender sin modificar código existente
- **Testabilidad**: Completamente testeable de forma unitaria

### Material Design 3
Todos los widgets implementan las especificaciones de Material Design 3:

- **Color schemes**: Uso del theme system de Material 3
- **Typography**: Escalas de texto consistentes
- **Components**: Componentes modernos y accesibles
- **Interactions**: Estados hover, focus, pressed
- **Accessibility**: Soporte completo para lectores de pantalla

## � Categorías de Widgets

### 🔘 Buttons (`/buttons/`)

Botones especializados para diferentes contextos de la aplicación.

**Widgets principales:**
- `AppButton`: Botón principal unificado con todas las funcionalidades
- `AppBarButton`: Botón optimizado para barras de aplicación
- `AppFloatingActionButton`: FAB con animaciones y estados
- `AppTextButton`: Botón de texto con estilos consistentes
- `SearchButton`: Botón especializado para búsquedas

**Características:**
- Estados de loading integrados
- Soporte para iconos
- Animaciones suaves
- Responsive design
- Accesibilidad completa

### 📝 Inputs (`/inputs/`)

Campos de entrada optimizados para formularios y captura de datos.

**Widgets principales:**
- `InputTextField`: Campo de texto base con validación
- `MoneyInputTextField`: Campo especializado para montos y precios

**Características:**
- Validación integrada
- Formateo automático
- Estados de error claros
- Teclados específicos
- Compatibilidad con forms

### 💬 Dialogs (`/dialogs/`)

Sistema completo y modular de diálogos organizados por dominio.

**Estructura modular:**
- **Base**: Componentes fundamentales reutilizables
- **Catalogue**: Diálogos específicos del catálogo
- **Sales**: Diálogos relacionados con ventas
- **Tickets**: Diálogos de tickets y recibos
- **Configuration**: Diálogos de configuración
- **Feedback**: Diálogos de confirmación y notificación

**Características:**
- Design system consistente
- Responsive y adaptativo
- Navegación intuitiva
- Estados de loading integrados
- Validación automática

### 🎨 Component (`/component/`)

Componentes básicos de interfaz de usuario reutilizables.

**Widgets principales:**
- `UserAvatar`: Avatar circular de usuario con estados
- `AvatarProduct`: Avatar para productos del catálogo
- `ImageWidget`: Widget de imagen con fallbacks y loading
- `Dividers`: Separadores y divisores con estilos
- `ProgressIndicators`: Indicadores de progreso personalizados

**Características:**
- Estados de loading/error
- Fallbacks inteligentes
- Responsive sizing
- Animaciones suaves
- Optimización de rendimiento

### 📢 Feedback (`/feedback/`)

Sistema de notificaciones y feedback al usuario.

**Funcionalidades:**
- SnackBars personalizados
- Mensajes de estado
- Confirmaciones
- Alertas y warnings
- Feedback de éxito/error

### 🖼️ Media (`/media/`)

Widgets especializados en manejo de contenido multimedia.

**Características:**
- Optimización de imágenes
- Lazy loading
- Gestión de memoria
- Formatos múltiples
- Responsive images

## � Uso y Integración

### Importación Recomendada

#### Importación completa (recomendada para desarrollo)
```dart
import 'package:sell_web/core/core.dart';
// Incluye todos los widgets, extensions, mixins, etc.
```

#### Importación por categoría (recomendada para producción)
```dart
// Botones específicos
import 'package:sell_web/core/widgets/buttons/buttons.dart';

// Campos de entrada
import 'package:sell_web/core/widgets/inputs/inputs.dart';

// Componentes UI básicos
import 'package:sell_web/core/widgets/component/ui.dart';
```

#### Importación específica
```dart
// Widget individual
import 'package:sell_web/core/widgets/buttons/app_button.dart';
import 'package:sell_web/core/widgets/component/user_avatar.dart';
```

### Ejemplos Prácticos

#### Botón Principal
```dart
AppButton(
  text: 'Guardar Producto',
  onPressed: () => _saveProduct(),
  isLoading: _isSaving,
  icon: const Icon(Icons.save),
  backgroundColor: context.primaryColor,
)
```

#### Campo de Entrada con Validación
```dart
InputTextField(
  controller: _nameController,
  labelText: 'Nombre del Producto',
  hintText: 'Ingrese el nombre',
  validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
  prefixIcon: const Icon(Icons.shopping_bag),
)
```

#### Avatar con Estados
```dart
UserAvatar(
  imageUrl: user.profileImage,
  name: user.displayName,
  radius: 24,
  showOnlineStatus: true,
  onTap: () => _showUserProfile(),
)
```

#### Feedback al Usuario
```dart
// Usando extensions
context.showSuccessSnackBar('Producto guardado exitosamente');

// Usando widget específico
AppFeedback.showSuccess(
  context,
  title: 'Éxito',
  message: 'Operación completada',
)
```

## 🚀 Beneficios de la Arquitectura

### 1. **Mantenibilidad**
- Código organizado por responsabilidades
- Fácil localización de componentes
- Modificaciones centralizadas

### 2. **Reutilización**
- Widgets independientes del contexto
- API consistente entre componentes
- Composición flexible

### 3. **Escalabilidad**
- Estructura modular extensible
- Nuevos widgets fáciles de agregar
- Sin dependencias circulares

### 4. **Performance**
- Tree-shaking automático
- Imports específicos reducen bundle
- Widgets optimizados

### 5. **Desarrollo**
- IntelliSense mejorado
- Auto-complete preciso
- Documentación integrada

## 🔄 Migración y Compatibilidad

### Estado Actual
- ✅ Estructura base reorganizada
- ✅ Exports configurados correctamente
- ✅ Documentación actualizada
- ✅ Compatibilidad mantenida
- 🔄 Widgets legacy en proceso de migración

### Plan de Migración
1. **Fase 1**: Reorganización de estructura ✅
2. **Fase 2**: Actualización de widgets existentes
3. **Fase 3**: Migración de código legacy
4. **Fase 4**: Optimización y cleanup

### Widgets a Migrar
- `/responsive/` → Integrar con `/component/`
- `/drawer/` → Crear nueva categoría `/navigation/`
- `/ui/` → Reorganizar en categorías específicas

## � Convenciones y Estándares

### Nomenclatura
- **Archivos**: `snake_case.dart`
- **Clases**: `PascalCase` con prefijo `App` para widgets principales
- **Parámetros**: `camelCase`
- **Constantes**: `UPPER_SNAKE_CASE`

### Estructura de Widget
```dart
import 'package:flutter/material.dart';

/// Descripción del widget y su propósito
/// 
/// Ejemplo de uso:
/// ```dart
/// AppWidget(
///   title: 'Mi Título',
///   onTap: () => print('Tapped'),
/// )
/// ```
class AppWidget extends StatelessWidget {
  /// Título del widget
  final String title;
  
  /// Callback cuando se toca el widget
  final VoidCallback? onTap;
  
  /// Crea una instancia de [AppWidget]
  const AppWidget({
    super.key,
    required this.title,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      // Implementación
    );
  }
}
```

### Material 3 Guidelines
- Usar `context.colorScheme` en lugar de colores hardcoded
- Implementar estados interactivos cuando corresponda
- Seguir guías de spacing y typography
- Soporte para temas claro/oscuro

## 🧪 Testing y Calidad

### Estrategia de Testing
- **Unit Tests**: Cada widget individualmente
- **Widget Tests**: Interacciones y estados
- **Integration Tests**: Flujos completos
- **Golden Tests**: Regresión visual

### Quality Assurance
- Linting automático con reglas estrictas
- Code coverage > 90%
- Performance benchmarks
- Accessibility compliance

## � Métricas y Optimización

### Performance
- Widget rebuilds minimizados
- Memory leaks prevenidos
- Efficient asset loading
- Smooth animations (60fps)

### Bundle Size
- Tree-shaking efectivo
- Imports optimizados
- Unused code elimination
- Asset optimization

## 🔮 Roadmap Futuro

### Próximas Mejoras
1. **Animated Widgets**: Sistema de animaciones consistente
2. **Theme Widgets**: Componentes específicos de theming
3. **Accessibility**: Mejoras adicionales de accesibilidad
4. **Performance**: Optimizaciones específicas por plataforma
5. **Customization**: Sistema de personalización avanzado

### Tecnologías Futuras
- **Flutter 3.x**: Nuevas funcionalidades
- **Material Design Updates**: Versiones futuras
- **Web/Desktop**: Optimizaciones específicas
- **Performance**: Impeller engine optimizations

## 📖 Referencias

- [Flutter Widget Catalog](https://docs.flutter.dev/ui/widgets)
- [Material Design 3](https://m3.material.io/)
- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Clean Architecture Flutter](https://resocoder.com/flutter-clean-architecture/)
- [Widget Testing](https://docs.flutter.dev/testing/widget-tests)
