# 📱 Views - Widgets de Vista

Esta carpeta contiene widgets de vista especializados que representan pantallas completas o componentes de vista complejos reutilizables en la aplicación.

## 🎯 Propósito

Los widgets de vista son componentes que:
- Representan pantallas completas o secciones principales de la UI
- Implementan layouts complejos con múltiples componentes
- Son reutilizables a través de diferentes páginas
- Siguen patrones de Material Design 3 y responsive design
- Mantienen la separación de responsabilidades de Clean Architecture

## 📋 Archivos Contenidos

### `presentation_page.dart`
- **Propósito**: Página de presentación principal de la aplicación
- **Contexto**: Vista completa con animaciones usando flutter_animate
- **Uso**: Pantalla de bienvenida/landing page para usuarios
- **Características**: 
  - Responsive design para mobile/tablet/desktop
  - Animaciones fluidas y transiciones
  - Integración con AuthProvider y ThemeProvider
  - Helper class para optimización de colores del AppBar

### `search_catalogue_full_screen_view.dart`
- **Propósito**: Vista de pantalla completa para búsqueda avanzada del catálogo
- **Contexto**: Implementa NestedScrollView con SliverAppBar optimizado
- **Uso**: Búsqueda y selección de productos del catálogo
- **Características**:
  - Búsqueda en tiempo real con filtros avanzados
  - Lista optimizada con lazy loading
  - Integración con CatalogueProvider y SellProvider
  - UI responsive siguiendo Material Design 3

### `views.dart`
- **Propósito**: Archivo de exportaciones centralizadas
- **Contexto**: Facilita imports y mantiene organización
- **Uso**: `import 'package:sellweb/core/widgets/views/views.dart';`

## 🏗️ Patrones de Arquitectura

### Clean Architecture
```dart
// ✅ Separación de responsabilidades
class SearchCatalogueView extends StatefulWidget {
  // Vista se enfoca solo en UI/UX
  // Lógica de negocio delegada a Providers
  // Datos obtenidos a través de Use Cases
}
```

### Provider Pattern
```dart
// ✅ Gestión de estado con Provider
Consumer<CatalogueProvider>(
  builder: (context, provider, child) {
    return CustomScrollView(/* ... */);
  },
)
```

### Responsive Design
```dart
// ✅ Implementación responsive
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < ResponsiveBreakpoints.mobile) {
      return MobileLayout();
    }
    return DesktopLayout();
  },
)
```

## 📱 Consideraciones de UX

### Performance
- **Lazy Loading**: Carga diferida de elementos pesados
- **Optimización de Widgets**: Uso de const constructors y shouldRebuild
- **Memory Management**: Disposal correcto de controllers y listeners

### Accesibilidad
- **Semantic Labels**: Etiquetas semánticas para lectores de pantalla
- **Focus Management**: Navegación por teclado optimizada
- **Color Contrast**: Cumplimiento de estándares WCAG

### Material Design 3
- **ColorScheme**: Uso de colores adaptativos del tema
- **Typography**: Escalas tipográficas consistentes
- **Motion**: Animaciones siguiendo las guías de Material You

## 🔧 Mejores Prácticas

### Nomenclatura
```dart
// ✅ Nombres descriptivos
class SearchCatalogueFullScreenView extends StatefulWidget {}

// ❌ Evitar nombres genéricos
class CatalogueView extends StatefulWidget {}
```

### Documentación
```dart
/// Vista de pantalla completa para [propósito específico].
///
/// Implementa [patrón técnico] siguiendo las mejores prácticas:
/// - [Característica 1]
/// - [Característica 2]
class CustomView extends StatefulWidget {}
```

### Optimización
```dart
// ✅ Widgets constantes cuando sea posible
const CustomView({
  super.key,
  required this.data,
});

// ✅ Builders eficientes
Widget build(BuildContext context) {
  return Selector<Provider, SpecificData>(
    selector: (context, provider) => provider.specificData,
    builder: (context, data, child) => /* ... */,
  );
}
```

**Nota**: Al agregar nuevas vistas, asegúrate de exportarlas en `views.dart` y seguir los patrones establecidos en el proyecto.
