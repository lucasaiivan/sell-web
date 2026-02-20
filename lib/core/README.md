# 🏗️ Core - Infraestructura Transversal

Funcionalidades compartidas del núcleo de la aplicación incluyendo configuraciones, constantes, servicios y utilidades comunes.

## Contenido
```
core/
├── core.dart - Archivo de barril que exporta todas las funcionalidades del núcleo
├── config/ - Configuraciones de la aplicación (Firebase, OAuth)
├── constants/ - Constantes globales de la aplicación
├── di/ - Inyección de dependencias (get_it + injectable)
├── errors/ - Manejo de errores (Failures y Exceptions)
├── mixins/ - Mixins reutilizables
├── presentation/ - Capa de presentación compartida
│   ├── theme/ - Sistema de temas Material 3
│   ├── widgets/ - Widgets reutilizables organizados por categoría
│   ├── helpers/ - Helpers de UI (responsive, snackbar, etc.)
│   └── providers/ - Providers globales (ThemeProvider)
├── services/ - Servicios de infraestructura
│   ├── database/ - Servicios de Firestore
│   ├── storage/ - Persistencia local
│   ├── printing/ - Impresión de tickets
│   └── external/ - APIs externas
├── usecases/ - Contrato base UseCase<T, Params>
└── utils/ - Utilidades y helpers
    ├── formatters/ - Formateadores (moneda, fecha, texto)
    └── helpers/ - Helpers especializados
```

### 🔧 Utils
**Propósito**: Utilidades y funciones helper reutilizables

#### Utilidades Principales:
- **responsive_breakpoints.dart**: Definición de breakpoints para diseño responsive
- **fuctions.dart**: Funciones utilitarias generales (formateo, validaciones, etc.)
- **formatters/**: Formateadores específicos para moneda, fechas, texto, etc.
- **helpers/**: Funciones helper especializadas
  - `uid_helper.dart` - Generación de UIDs únicos
  - `date_formatter.dart` - Formateo de fechas

### 🎨 Presentation
**Propósito**: Componentes UI compartidos y sistema de diseño

#### Subdirectorios:
- **theme/**: Material 3 theme configuration
  - `app_theme.dart` - Tema claro y oscuro
  - `theme_data_app_provider.dart` - Provider de tema
- **widgets/**: Sistema completo de widgets reutilizables
  - `buttons/` - Botones estandarizados (AppButton, AppTextButton, etc.)
  - `inputs/` - Campos de entrada (InputTextField, MoneyInputTextField, etc.)
  - `ui/` - Componentes UI básicos (AvatarProduct, UserAvatar, etc.)
  - `feedback/` - Loading, Error states
  - `graphics/` - Componentes gráficos
  - `navigation/` - Widgets de navegación
- **dialogs/**: Sistema modular de diálogos
  - `base/` - Componentes base reutilizables
  - Organizados por dominio (catalogue, sales, configuration, etc.)
- **modals/**: Bottom sheets y overlays
- **helpers/**: Helpers de UI (responsive, snackbar, etc.)
- **views/**: Vistas compartidas (welcome pages, etc.)
 
## 🎯 Principios de Diseño

### ✅ Responsabilidades del Core
- **Configuración**: Manejo centralizado de configuraciones
- **Servicios transversales**: Servicios que no pertenecen a un dominio específico
- **Utilidades**: Funciones helper y utilidades generales
- **Constantes**: Valores inmutables utilizados globalmente
- **Infraestructura**: Clases base y mixins reutilizables

### ❌ Lo que NO pertenece al Core
- **Lógica de negocio**: Debe estar en el domain layer
- **Modelos de dominio**: Pertenecen a domain/entities
- **UI específica**: Los widgets específicos van en presentation/widgets
- **Casos de uso**: Deben estar en domain/usecases

## 📚 Patrones de Uso

### Importación desde Core
```dart
// ✅ Forma correcta - usar el archivo principal
import 'package:sell_web/core/core.dart';

// ❌ Evitar importaciones directas
import 'package:sell_web/core/utils/functions.dart';
```

### Servicios Singleton
Utilizamos el paquete `injectable` para generar singletons automáticamente.

```dart
// ✅ Forma correcta con Injectable
@lazySingleton
class ThemeService {
  final AppDataPersistenceService _persistence;
  
  ThemeService(this._persistence);
}
```

❌ **Evitar Singletons Manuales:**
```dart
// Evitar este patrón antiguo
class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
}
```

### Utilidades Estáticas
```dart
// Las utilidades se implementan como clases con métodos estáticos
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 840;
  static const double desktop = 1200;
  
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }
}
```

## 🔄 Integración con Otras Capas

### Con Presentation
- Provee servicios de tema y configuración
- Suministra utilidades para responsive design
- Ofrece constantes para la UI

### Con Domain
- Proporciona servicios de infraestructura
- Suministra utilidades para validaciones
- No debe contener lógica de negocio

### Con Data
- Ofrece servicios de base de datos y almacenamiento
- Provee configuraciones para APIs externas
- Suministra utilidades para transformación de datos

## 🚀 Mejores Prácticas

### Desarrollo
1. **Inmutabilidad**: Usar `const` para constantes y valores inmutables
2. **Singleton responsable**: Aplicar singleton solo cuando sea necesario
3. **Documentación**: Documentar servicios y utilidades complejas
4. **Testing**: Crear tests unitarios para utilidades críticas

### Organización
1. **Separación clara**: Mantener separación entre configuración, servicios y utilidades
2. **Naming consistente**: Usar convenciones de nomenclatura consistentes
3. **Exportaciones centralizadas**: Usar `core.dart` como punto único de exportación
4. **README por subdirectorio**: Mantener documentación actualizada en cada subdirectorio

### Performance
1. **Lazy loading**: Inicializar servicios solo cuando se necesiten
2. **Cache inteligente**: Implementar cache en servicios que lo requieran
3. **Optimización de imports**: Evitar importaciones circulares y excesivas

## 📖 Documentación Adicional

Para más información sobre cada subdirectorio, consulta:
- [📋 Config README](./config/README.md)
- [🔢 Constants README](./constants/README.md)
- [🛠️ Services README](./services/README.md)
- [🔧 Utils README](./utils/README.md)
- [🎭 Mixins README](./mixins/README.md)

---

> **Nota**: Esta capa es fundamental para mantener la **separación de responsabilidades** y la **reutilización de código** en toda la aplicación. Cualquier funcionalidad que sea utilizada por múltiples capas debe considerarse para inclusión en `core`.
