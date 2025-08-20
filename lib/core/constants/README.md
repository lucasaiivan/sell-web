# 📐 Constants - Constantes de la Aplicación

Este directorio contiene **todas las constantes** utilizadas en la aplicación, organizadas por categoría para facilitar el mantenimiento y evitar la duplicación.

## 🎯 Propósito

Centralizar todas las constantes de la aplicación siguiendo el principio **DRY (Don't Repeat Yourself)** y facilitando cambios globales desde un punto único.

## 📁 Archivos y Responsabilidades

### `app_constants.dart`
**Constantes generales de la aplicación**
- URLs de APIs y endpoints
- Timeouts y límites
- Valores por defecto
- Configuraciones de paginación
- Límites de archivos y datos

```dart
class AppConstants {
  // API Configuration
  static const String baseApiUrl = 'https://api.example.com';
  static const Duration defaultTimeout = Duration(seconds: 30);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // File Limits
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
}
```

### `shared_prefs_keys.dart`
**Claves para SharedPreferences**
- Keys para persistencia local
- Configuraciones de usuario
- Estado de la aplicación
- Preferencias temporales

```dart
class SharedPrefsKeys {
  // User Preferences
  static const String selectedTheme = 'selected_theme';
  static const String selectedLanguage = 'selected_language';
  
  // App State
  static const String lastSelectedAccount = 'last_selected_account';
  static const String cashRegisterConfig = 'cash_register_config';
}
```

### `responsive_breakpoints.dart`
**Breakpoints para diseño responsive**
- Puntos de quiebre para diferentes dispositivos
- Configuraciones de layout adaptativo
- Tamaños estándar de componentes

```dart
class ResponsiveBreakpoints {
  // Screen Breakpoints (Material Design 3)
  static const double mobile = 600.0;
  static const double tablet = 840.0;
  static const double desktop = 1200.0;
  static const double largeDesktop = 1600.0;
  
  // Component Sizes
  static const double minTouchTarget = 48.0;
  static const double cardElevation = 4.0;
}
```

## 🔧 Convenciones de Uso

### Nomenclatura
```dart
// ✅ Correcto - Nombres descriptivos y agrupados
class ApiConstants {
  static const String userEndpoint = '/api/v1/users';
  static const String productsEndpoint = '/api/v1/products';
}

// ❌ Evitar - Nombres genéricos
class Constants {
  static const String endpoint1 = '/api/v1/users';
  static const String endpoint2 = '/api/v1/products';
}
```

### Organización por Dominio
```dart
class SalesConstants {
  static const double maxDiscount = 0.50; // 50%
  static const int maxItemsPerTicket = 100;
}

class AuthConstants {
  static const Duration sessionTimeout = Duration(hours: 24);
  static const int maxLoginAttempts = 3;
}
```

### Tipos de Datos Inmutables
```dart
// ✅ Usar tipos inmutables
static const List<String> supportedImageFormats = ['jpg', 'png', 'webp'];
static const Map<String, String> errorMessages = {
  'network': 'Error de conexión',
  'timeout': 'Tiempo agotado',
};

// ❌ Evitar referencias mutables
static final List<String> formats = []; // Puede ser modificada
```

## 📚 Importación y Uso

### Import Específico
```dart
// ✅ Recomendado - Import específico
import 'package:sell_web/core/constants/app_constants.dart';
import 'package:sell_web/core/constants/shared_prefs_keys.dart';

class SomeService {
  void fetchData() {
    final url = AppConstants.baseApiUrl;
    final timeout = AppConstants.defaultTimeout;
  }
}
```

### Evitar Magic Numbers
```dart
// ✅ Correcto - Usar constantes
Widget buildPadding() {
  return Padding(
    padding: EdgeInsets.all(ResponsiveBreakpoints.minTouchTarget),
    child: child,
  );
}

// ❌ Evitar - Magic numbers
Widget buildPadding() {
  return Padding(
    padding: EdgeInsets.all(48.0), // ¿De dónde viene este número?
    child: child,
  );
}
```

## ⚡ Performance y Optimización

### Lazy Loading para Constantes Complejas
```dart
class ExpensiveConstants {
  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static RegExp get emailRegex => _emailRegex;
}
```

### Constantes Compiladas
```dart
// Las constantes con 'const' se evalúan en tiempo de compilación
static const String appName = 'Sell Web';
static const double goldenRatio = 1.618033988749;
```

## ✅ Buenas Prácticas

1. **Una responsabilidad por archivo**: Cada archivo debe contener constantes relacionadas
2. **Nombres descriptivos**: Los nombres deben explicar claramente qué representan
3. **Agrupación lógica**: Usar clases para agrupar constantes relacionadas
4. **Documentación**: Comentar constantes no obvias o con lógica específica
5. **Inmutabilidad**: Todas las constantes deben ser inmutables

## 🚫 Anti-patterns a Evitar

```dart
// ❌ Constantes en múltiples lugares
// En widget A
static const double padding = 16.0;
// En widget B  
static const double spacing = 16.0; // Duplicado!

// ❌ Constantes mutables
static List<String> categories = ['A', 'B']; // Puede cambiar

// ❌ Nombres no descriptivos
static const int x = 10;
static const String s = 'Hello';
```

---

💡 **Tip**: Antes de crear una nueva constante, verificar si ya existe algo similar en este directorio.
