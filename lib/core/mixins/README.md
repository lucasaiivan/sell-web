# Core Mixins

Esta carpeta contiene mixins reutilizables que encapsulan funcionalidades comunes para widgets StatefulWidget, siguiendo los principios de Clean Architecture y DRY.

## 📁 Estructura

```
/core/mixins/
├── README.md                    # Este archivo
├── loading_mixin.dart          # Mixin para estados de loading
├── validation_mixin.dart       # Mixin para validación de formularios
└── responsive_mixin.dart       # Mixin para diseño responsive
```

## 🎯 Propósito

Los mixins proporcionan funcionalidades reutilizables que pueden ser aplicadas a cualquier StatefulWidget, permitiendo:

- **Reutilización de código**: Lógica común compartida entre múltiples widgets
- **Separación de responsabilidades**: Cada mixin maneja una preocupación específica
- **Composición sobre herencia**: Múltiples mixins pueden combinarse en un solo widget
- **Testing simplificado**: Funcionalidades aisladas y testeable por separado
- **Mantenimiento eficiente**: Cambios centralizados que afectan múltiples componentes

## 📚 Mixins Disponibles

### ⏳ Loading Mixin (`loading_mixin.dart`)

Proporciona funcionalidad completa para manejar estados de loading en widgets.

**Características principales:**
- **Control de estado**: Start, stop, toggle loading states
- **Mensajes dinámicos**: Loading messages actualizables
- **Ejecución con loading**: Wrapper automático para funciones async
- **Indicadores de UI**: Widgets predefinidos para mostrar loading
- **Validaciones**: Prevención de acciones múltiples durante loading
- **Acciones secuenciales**: Ejecutar múltiples operaciones con loading
- **Feedback automático**: SnackBars de error/éxito integrados

**Submixins incluidos:**
- `FormLoadingMixin`: Loading específico por campos de formulario
- `DebouncedLoadingMixin`: Loading con debounce para evitar llamadas múltiples

**Ejemplos de uso:**
```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> with LoadingMixin {
  
  Future<void> _saveData() async {
    await executeWithLoading(
      () async {
        // Operación async
        await Future.delayed(Duration(seconds: 2));
      },
      loadingMessage: 'Guardando datos...',
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildConditionalContent(
        content: YourContentWidget(),
        loadingMessage: 'Cargando...',
      ),
    );
  }
}
```

**Widgets disponibles:**
- `buildLoadingIndicator()`: Indicador circular centrado
- `buildInlineLoadingIndicator()`: Loading horizontal inline
- `buildLoadingOverlay()`: Overlay sobre contenido existente
- `buildConditionalContent()`: Muestra loading o contenido según estado

### ✅ Validation Mixin (`validation_mixin.dart`)

Sistema completo de validación para formularios con reglas predefinidas y personalizables.

**Características principales:**
- **Reglas de validación**: Sistema extensible de reglas predefinidas
- **Validación en tiempo real**: Validación mientras el usuario escribe
- **Gestión de errores**: Manejo centralizado de mensajes de error
- **Validación por campos**: Validación individual o de todo el formulario
- **UI helpers**: Decoraciones y widgets para mostrar errores
- **Integración con Material Design**: Estilos consistentes con tema

**Reglas predefinidas:**
- `RequiredRule`: Campo obligatorio
- `MinLengthRule` / `MaxLengthRule`: Longitud de texto
- `EmailRule`: Formato de email válido
- `NumericRule`: Solo números (enteros o decimales)
- `RangeRule`: Rango numérico
- `PatternRule`: Expresiones regulares personalizadas
- `MatchFieldRule`: Comparación entre campos
- `CustomRule`: Reglas completamente personalizadas

**Submixins incluidos:**
- `RealTimeValidationMixin`: Validación con debounce en tiempo real

**Ejemplos de uso:**
```dart
class FormWidget extends StatefulWidget {
  @override
  _FormWidgetState createState() => _FormWidgetState();
}

class _FormWidgetState extends State<FormWidget> with ValidationMixin {
  
  @override
  void initState() {
    super.initState();
    
    // Configurar reglas de validación
    setFormRules({
      'email': [
        RequiredRule(message: 'El email es requerido'),
        EmailRule(),
      ],
      'password': [
        RequiredRule(),
        MinLengthRule(8, message: 'Mínimo 8 caracteres'),
      ],
    });
  }
  
  void _onEmailChanged(String value) {
    updateFieldValue('email', value);
  }
  
  Future<void> _submitForm() async {
    if (await validateFormWithFeedback()) {
      // Procesar formulario válido
      final email = getFieldValue<String>('email');
      await executeIfValid(() async {
        // Lógica de envío
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: getFieldDecoration('email', labelText: 'Email'),
          onChanged: _onEmailChanged,
        ),
        buildErrorSummary(),
      ],
    );
  }
}
```

### 📱 Responsive Mixin (`responsive_mixin.dart`)

Herramientas completas para crear interfaces responsivas y adaptativas.

**Características principales:**
- **Detección de dispositivo**: Mobile, tablet, desktop, large desktop
- **Valores responsivos**: Diferentes valores según tamaño de pantalla
- **Layouts adaptativos**: Widgets que se adaptan automáticamente
- **Breakpoints personalizables**: Configuración flexible de puntos de quiebre
- **Orientación**: Detección y manejo de cambios de orientación
- **Cálculos automáticos**: Columnas, espaciado, tamaños óptimos

**Tipos de dispositivo soportados:**
- **Mobile**: < 600px
- **Tablet**: 600px - 840px
- **Desktop**: 840px - 1600px
- **Large Desktop**: > 1600px

**Submixins incluidos:**
- `OrientationMixin`: Detección de cambios de orientación
- `SizeChangeMixin`: Detección de cambios de tamaño de pantalla

**Ejemplos de uso:**
```dart
class ResponsiveWidget extends StatefulWidget {
  @override
  _ResponsiveWidgetState createState() => _ResponsiveWidgetState();
}

class _ResponsiveWidgetState extends State<ResponsiveWidget> 
    with ResponsiveMixin {
  
  @override
  Widget build(BuildContext context) {
    return responsiveContainer(
      child: responsiveLayout(
        mobile: MobileLayout(),
        tablet: TabletLayout(),
        desktop: DesktopLayout(),
      ),
    );
  }
  
  Widget buildProductGrid() {
    return responsiveGrid(
      children: products.map((p) => ProductCard(p)).toList(),
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 3,
      largeDesktopColumns: 4,
    );
  }
  
  double getCardHeight() {
    return responsive(
      mobile: 200.0,
      tablet: 250.0,
      desktop: 300.0,
    );
  }
}
```

## 🔧 Uso en el Proyecto

### Importación

Los mixins se exportan desde el módulo principal de core:

```dart
import 'package:sell_web/core/core.dart';
// Todos los mixins están disponibles automáticamente
```

### Combinación de Mixins

Los mixins pueden combinarse en un solo widget:

```dart
class ComplexWidget extends StatefulWidget {
  @override
  _ComplexWidgetState createState() => _ComplexWidgetState();
}

class _ComplexWidgetState extends State<ComplexWidget> 
    with LoadingMixin, ValidationMixin, ResponsiveMixin {
  
  Future<void> _submitForm() async {
    // Validar usando ValidationMixin
    if (await validateFormWithFeedback()) {
      // Ejecutar con loading usando LoadingMixin
      await executeWithLoading(
        () async {
          // Lógica de negocio
        },
        loadingMessage: 'Procesando...',
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Usar ResponsiveMixin para layout adaptativo
    return responsiveContainer(
      child: buildConditionalContent(
        content: Form(
          child: Column(
            children: [
              TextField(
                decoration: getFieldDecoration('email'),
                onChanged: (value) => updateFieldValue('email', value),
              ),
              buildErrorSummary(),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Integración con Clean Architecture

Los mixins siguen los principios de Clean Architecture:

- **Independencia**: No dependen de capas superiores o específicas del negocio
- **Reutilización**: Pueden usarse en presentation, widgets, y componentes UI
- **Testabilidad**: Cada mixin puede ser testeado independientemente
- **Composición**: Se combinan para crear funcionalidades complejas

## 📈 Beneficios de Desarrollo

### 1. **Consistencia de UX**
- Loading states uniformes en toda la app
- Validación consistente en formularios
- Comportamiento responsive predecible

### 2. **Desarrollo Acelerado**
- Funcionalidades comunes ya implementadas
- Menos código repetitivo
- API intuitiva y documentada

### 3. **Mantenimiento Simplificado**
- Cambios centralizados
- Testing enfocado
- Debugging más eficiente

### 4. **Escalabilidad**
- Nuevos mixins fáciles de agregar
- Composición flexible
- Extensión sin modificación

## 🧪 Testing y Calidad

### Características de Testing

- **Unit Testing**: Cada mixin es completamente testeable
- **Widget Testing**: Integración con Flutter testing framework
- **Mock Support**: Fácil de mockear para tests unitarios
- **Edge Cases**: Manejo de casos límite (null, empty, error states)

### Consideraciones de Performance

- **Lazy Loading**: Evaluación perezosa donde es apropiado
- **State Management**: Estado mínimo y eficiente
- **Memory Management**: Cleanup automático en dispose()
- **Rebuild Optimization**: Minimiza rebuilds innecesarios

## 🔄 Extensión y Personalización

### Crear Nuevos Mixins

Para agregar nuevos mixins al proyecto:

1. **Crear el archivo**: Siguiendo la convención `nombre_mixin.dart`
2. **Definir el mixin**: Extender `State<T>` donde T es StatefulWidget
3. **Implementar funcionalidad**: Métodos y propiedades específicas
4. **Documentar**: README y comentarios inline
5. **Exportar**: Agregar al archivo `core.dart`
6. **Testing**: Crear tests unitarios

### Ejemplo de Nuevo Mixin

```dart
// audio_mixin.dart
mixin AudioMixin<T extends StatefulWidget> on State<T> {
  
  AudioPlayer? _audioPlayer;
  
  Future<void> playSound(String audioPath) async {
    _audioPlayer ??= AudioPlayer();
    await _audioPlayer!.play(AssetSource(audioPath));
  }
  
  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }
}
```

## 📖 Referencias y Mejores Prácticas

### Referencias

- [Dart Mixins Documentation](https://dart.dev/guides/language/mixins)
- [Flutter State Management](https://flutter.dev/docs/development/data-and-backend/state-mgmt)
- [Material Design Responsive Guidelines](https://material.io/design/layout/responsive-layout-grid.html)

### Mejores Prácticas

1. **Un mixin, una responsabilidad**: Cada mixin debe tener un propósito claro
2. **Composición sobre herencia**: Usar múltiples mixins en lugar de jerarquías complejas
3. **Null safety**: Siempre verificar `mounted` antes de llamar `setState()`
4. **Resource cleanup**: Implementar `dispose()` para limpiar recursos
5. **Documentation**: Documentar todos los métodos públicos
6. **Testing**: Escribir tests para funcionalidades críticas

### Antipatrones a Evitar

- **God mixins**: Mixins que hacen demasiadas cosas
- **Tight coupling**: Dependencias entre mixins
- **Memory leaks**: No limpiar listeners o controllers
- **Over-abstraction**: Abstractar cuando no es necesario
- **State pollution**: Modificar estado global desde mixins
