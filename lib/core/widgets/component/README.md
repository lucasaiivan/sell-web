# Responsive Helper

## 📋 Propósito
Clase de utilidad para manejo de diseño responsivo que implementa breakpoints estándar y helpers para adaptación de UI en diferentes tamaños de pantalla.

## 🎯 Características

### Breakpoints Estándar
```dart
static const double mobile = 600;   // < 600px
static const double tablet = 1024;  // 600px - 1024px  
static const double desktop = 1440; // > 1024px
```

### Métodos de Detección
- `isMobile(context)` - Detecta dispositivos móviles
- `isTablet(context)` - Detecta tablets
- `isDesktop(context)` - Detecta dispositivos desktop
- `getScreenSize(context)` - Retorna enum ScreenSize

### Helpers de Adaptación
- `responsive<T>()` - Proporciona valores diferentes según pantalla
- `getDialogPadding(context)` - Padding responsivo para diálogos
- `getSpacing(context, scale)` - Espaciado escalable responsivo
- `getMaxContentWidth(context)` - Ancho máximo adaptativo

## 🔧 Uso

### Detección Básica
```dart
final isMobile = ResponsiveHelper.isMobile(context);
final isDesktop = ResponsiveHelper.isDesktop(context);
```

### Valores Responsivos
```dart
final padding = ResponsiveHelper.responsive<double>(
  context: context,
  mobile: 8.0,
  tablet: 12.0,
  desktop: 16.0,
);
```

### Widget Responsivo
```dart
ResponsiveBuilder(
  mobile: MobileWidget(),
  tablet: TabletWidget(),
  desktop: DesktopWidget(),
)
```

### Helpers de Layout
```dart
// Padding automático para diálogos
padding: ResponsiveHelper.getDialogPadding(context)

// Espaciado escalable
SizedBox(height: ResponsiveHelper.getSpacing(context, scale: 2.0))

// Ancho máximo de contenido
width: ResponsiveHelper.getMaxContentWidth(context)
```

## 🎨 Casos de Uso

### Layouts Adaptativos
```dart
Widget build(BuildContext context) {
  return ResponsiveHelper.responsive(
    context: context,
    mobile: Column(children: widgets),
    desktop: Row(children: widgets),
  );
}
```

### Tamaños de Componentes
```dart
Container(
  padding: ResponsiveHelper.responsive(
    context: context,
    mobile: EdgeInsets.all(8),
    tablet: EdgeInsets.all(12),
    desktop: EdgeInsets.all(16),
  ),
)
```

### Tipografía Responsiva
```dart
Text(
  'Título',
  style: ResponsiveHelper.responsive(
    context: context,
    mobile: theme.textTheme.titleSmall,
    tablet: theme.textTheme.titleMedium,
    desktop: theme.textTheme.titleLarge,
  ),
)
```

## ⚡ Beneficios

### Para Desarrolladores
- ✅ Código más limpio y mantenible
- ✅ Reutilización de lógica responsiva
- ✅ Breakpoints consistentes en toda la app
- ✅ Fácil extensión y modificación

### Para Usuarios
- ✅ Experiencia optimizada en cada dispositivo
- ✅ Interfaz adaptada al tamaño de pantalla
- ✅ Mejor legibilidad y usabilidad
- ✅ Transiciones suaves entre breakpoints

## 🛠️ Extensibilidad

### Nuevos Breakpoints
```dart
// Agregar breakpoints personalizados
static const double ultrawide = 1920;

static bool isUltrawide(BuildContext context) {
  return MediaQuery.of(context).size.width >= ultrawide;
}
```

### Helpers Personalizados
```dart
// Ejemplo: Border radius responsivo
static BorderRadius getResponsiveBorderRadius(BuildContext context) {
  return BorderRadius.circular(
    responsive(
      context: context,
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
    ),
  );
}
```

## 🎯 Integración con Material Design 3

- Compatible con todas las especificaciones MD3
- Mantiene consistencia visual en diferentes tamaños
- Optimizado para tokens de diseño estándar
- Soporte completo para temas claro/oscuro

## 📱 Mejores Prácticas

### Uso Eficiente
```dart
// ✅ Bueno - Cachear el resultado cuando sea posible
final isMobile = ResponsiveHelper.isMobile(context);
if (isMobile) {
  // lógica móvil
}

// ❌ Evitar - Múltiples llamadas innecesarias
if (ResponsiveHelper.isMobile(context)) {
  // Si necesitas el valor varias veces, guárdalo
}
```

### Orden de Prioridad
```dart
// Siempre definir móvil, tablet y desktop son opcionales
ResponsiveHelper.responsive(
  context: context,
  mobile: mobileValue,     // ✅ Obligatorio
  tablet: tabletValue,     // ⚡ Opcional (usa mobile si no se define)
  desktop: desktopValue,   // ⚡ Opcional (usa tablet o mobile)
)
```
