# 🏗️ Core - Arquitectura Transversal

El directorio `core` contiene toda la **infraestructura transversal** de la aplicación que es **independiente del dominio de negocio**. Esta capa proporciona servicios, utilidades y componentes reutilizables que pueden ser utilizados por todas las demás capas del proyecto.

## 📁 Estructura del Directorio

```
core/
├── config/                    # Configuraciones de la aplicación
│   ├── app_config.dart        # Configuración general de la app
│   ├── firebase_options.dart  # Configuración de Firebase
│   └── oauth_config.dart      # Configuración de OAuth (Google Sign-In)
├── constants/                 # Constantes globales
│   ├── app_constants.dart     # Constantes generales de la aplicación
│   └── shared_prefs_keys.dart # Claves para SharedPreferences
├── mixins/                    # Mixins reutilizables
├── services/                  # Servicios transversales
│   ├── database/              # Servicios de base de datos
│   ├── external/              # Servicios externos (APIs, impresión)
│   ├── storage/               # Servicios de almacenamiento
│   ├── search_catalogue_service.dart # Servicio de búsqueda de catálogo
│   └── theme_service.dart     # Servicio de gestión de temas
├── utils/                     # Utilidades y helpers
│   ├── formaters/             # Formateadores de datos
│   ├── helpers/               # Funciones helper específicas  
└── core.dart                  # Archivo de exportación principal
```

## 🔧 Componentes Principales

### 📋 Config
**Propósito**: Configuraciones centralizadas de la aplicación
- **app_config.dart**: Variables de configuración global, URLs de API, configuraciones de entorno
- **firebase_options.dart**: Configuración de Firebase generada automáticamente
- **oauth_config.dart**: Configuración para autenticación con Google y otros proveedores OAuth

### 🔢 Constants
**Propósito**: Constantes inmutables utilizadas en toda la aplicación
- **app_constants.dart**: Constantes generales como versiones, límites, URLs, etc.
- **shared_prefs_keys.dart**: Claves estandarizadas para SharedPreferences

### 🛠️ Services
**Propósito**: Servicios transversales independientes del dominio de negocio

#### Servicios Principales:
- **theme_service.dart**: Gestión de temas claro/oscuro con persistencia
- **search_catalogue_service.dart**: Lógica de búsqueda y filtrado de productos
- **database/**: Servicios de conexión y operaciones con Firebase Firestore
- **external/**: Servicios para integraciones externas (impresoras térmicas, APIs)
- **storage/**: Servicios de almacenamiento local y en la nube

### 🔧 Utils
**Propósito**: Utilidades y funciones helper reutilizables

#### Utilidades Principales:
- **responsive_breakpoints.dart**: Definición de breakpoints para diseño responsive
- **fuctions.dart**: Funciones utilitarias generales (formateo, validaciones, etc.)
- **formaters/**: Formateadores específicos para moneda, fechas, texto, etc.
- **helpers/**: Funciones helper especializadas para casos de uso específicos
 
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
```dart
// Los servicios core típicamente siguen el patrón singleton
class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();
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
