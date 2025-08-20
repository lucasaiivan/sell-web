# 🔧 Services - Servicios de Infraestructura

El directorio `services` contiene todos los **servicios de infraestructura** que proporcionan funcionalidades transversales para la aplicación, siguiendo el patrón de Clean Architecture.

## 🎯 Propósito

Centralizar servicios que:
- **Abstraigan dependencias externas** (Firebase, APIs, hardware)
- **Proporcionen interfaces consistentes** para diferentes capas
- **Manejen configuraciones** y estado global
- **Faciliten testing** mediante abstracciones

## 📁 Estructura y Responsabilidades

```
services/
├── database/           # Servicios de base de datos
├── storage/           # Servicios de persistencia local
├── external/          # Servicios externos (impresoras, APIs)
├── theme_service.dart # Servicio de temas y estilos
└── README.md         # Este archivo
```

## 📖 Servicios por Categoría

### 🗄️ `/database` - Servicios de Base de Datos

#### `database_cloud.dart`
**Servicio para interacciones con Firebase Firestore**
- Operaciones CRUD centralizadas
- Manejo de errores consistente
- Abstracción de consultas complejas
- Cache y sincronización

```dart
class DatabaseCloudService {
  Future<List<T>> getCollection<T>(String path);
  Future<void> create<T>(String path, T data);
  Future<void> update<T>(String path, String id, T data);
  Future<void> delete(String path, String id);
}
```

#### `firestore_service.dart` (Nuevo)
**Abstracción específica de Firestore**
- Wrappers type-safe para operaciones
- Manejo de transacciones
- Subscripciones reactivas
- Manejo de offline/online

### 💾 `/storage` - Servicios de Persistencia Local

#### `storage_service.dart` (Nuevo)
**Abstracción general de storage local**
- Interface común para diferentes backends
- Operaciones async/sync
- Manejo de tipos complejos
- Migración de datos

```dart
abstract class StorageService {
  Future<void> set<T>(String key, T value);
  Future<T?> get<T>(String key);
  Future<void> remove(String key);
  Future<void> clear();
}
```

#### `shared_prefs_service.dart` (Refactorizado)
**Implementación específica con SharedPreferences**
- Migrado desde `app_data_persistence_service.dart`
- Tipado fuerte con genéricos
- Validación de datos
- Cache en memoria

### 🔌 `/external` - Servicios Externos

#### `thermal_printer_service.dart` (Refactorizado)
**Servicio para impresoras térmicas**
- Migrado desde `thermal_printer_http_service.dart`
- Abstracción de diferentes tipos de impresoras
- Cola de impresión
- Manejo de errores de conexión

```dart
class ThermalPrinterService {
  Future<bool> isConnected();
  Future<void> print(String content);
  Future<void> configure(PrinterConfig config);
}
```

#### `auth_service.dart` (Nuevo)
**Servicio de autenticación**
- Abstracción de Firebase Auth
- Manejo de diferentes providers
- State management de sesión
- Renovación automática de tokens

### 🎨 `theme_service.dart`
**Servicio centralizado para gestión de temas**

**Características actuales**:
- Gestión de ThemeMode (claro/oscuro/sistema)
- Material Design 3 con ColorScheme.fromSeed()
- Estilos personalizados para todos los componentes
- Configuración centralizada de colores y tipografía

**Mejoras propuestas**:
```dart
class ThemeService {
  // Gestión dinámica de colores
  static Future<void> updateSeedColor(Color color);
  static Future<void> saveThemePreferences();
  
  // Temas personalizados
  static ThemeData customTheme({required Color seedColor});
  static Map<String, Color> getColorPalette();
  
  // Responsive theming
  static ThemeData getResponsiveTheme(BuildContext context);
}
```

## 🏗️ Patrones de Diseño Aplicados

### Service Locator Pattern
```dart
// core/services/service_locator.dart (Nuevo)
class ServiceLocator {
  static final _instance = ServiceLocator._internal();
  static ServiceLocator get instance => _instance;
  
  final Map<Type, dynamic> _services = {};
  
  void register<T>(T service) => _services[T] = service;
  T get<T>() => _services[T] as T;
}

// Uso
ServiceLocator.instance.register<DatabaseService>(DatabaseCloudService());
final db = ServiceLocator.instance.get<DatabaseService>();
```

### Repository Pattern Integration
```dart
// Los servicios actúan como implementaciones de repositorios
class ProductRepositoryImpl implements ProductRepository {
  final DatabaseService _db;
  final StorageService _cache;
  
  ProductRepositoryImpl(this._db, this._cache);
  
  @override
  Future<List<Product>> getProducts() async {
    // Lógica que usa servicios core
  }
}
```

### Factory Pattern
```dart
class ServiceFactory {
  static DatabaseService createDatabaseService() {
    if (kIsWeb) {
      return FirestoreWebService();
    } else {
      return FirestoreMobileService();
    }
  }
}
```

## ⚡ Inicialización y Lifecycle

### Orden de Inicialización
```dart
class CoreServices {
  static Future<void> initialize() async {
    // 1. Configuraciones básicas
    await _initializeConfig();
    
    // 2. Servicios de storage
    await _initializeStorage();
    
    // 3. Servicios de base de datos
    await _initializeDatabase();
    
    // 4. Servicios externos
    await _initializeExternalServices();
    
    // 5. Registrar en service locator
    _registerServices();
  }
}
```

### Dependency Injection
```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicios core
  await CoreServices.initialize();
  
  runApp(MyApp());
}
```

## 🔧 Convenciones y Estándares

### Naming Conventions
```dart
// ✅ Correcto
class DatabaseCloudService implements DatabaseService
class ThemeService // Singleton service
class PrinterServiceFactory // Factory pattern

// ❌ Evitar
class FirebaseService // Demasiado genérico
class Helper // No específico
class Utils // No específico
```

### Error Handling
```dart
class ServiceException implements Exception {
  final String message;
  final String service;
  final dynamic originalError;
  
  ServiceException(this.message, this.service, [this.originalError]);
}

// En servicios
try {
  // Operación
} catch (e) {
  throw ServiceException('Error en operación', 'DatabaseService', e);
}
```

### Logging
```dart
class ServiceLogger {
  static void logServiceCall(String service, String method, [dynamic params]) {
    if (kDebugMode) {
      print('[$service.$method] ${params?.toString() ?? ''}');
    }
  }
}
```

## ✅ Buenas Prácticas

1. **Single Responsibility**: Cada servicio tiene una responsabilidad específica
2. **Interface Segregation**: Interfaces pequeñas y específicas
3. **Dependency Inversion**: Depender de abstracciones, no de implementaciones
4. **Error Handling**: Manejo consistente de errores en todos los servicios
5. **Testing**: Todos los servicios deben ser testables unitariamente
6. **Documentation**: Documentar interfaces y métodos públicos

## 🚫 Anti-patterns a Evitar

```dart
// ❌ Servicios que hacen demasiado
class MegaService {
  void saveData() {}
  void printTicket() {}
  void sendEmail() {}
  void calculateTax() {} // Demasiadas responsabilidades
}

// ❌ Dependencias directas de Flutter en lógica de negocio
class BadService {
  void saveTheme(BuildContext context) { // No debería necesitar context
    // ...
  }
}

// ❌ Estado mutable global
class BadService {
  static String currentUser = ''; // Estado global mutable
}
```

## 📊 Métricas y Monitoreo

### Performance Tracking
```dart
class ServiceMetrics {
  static final Map<String, Duration> _averageCallTimes = {};
  
  static Future<T> trackCall<T>(
    String serviceName,
    String method,
    Future<T> Function() call,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await call();
    } finally {
      stopwatch.stop();
      _recordCallTime('$serviceName.$method', stopwatch.elapsed);
    }
  }
}
```

### Health Checks
```dart
abstract class HealthCheckable {
  Future<HealthStatus> checkHealth();
}

class HealthStatus {
  final bool isHealthy;
  final String message;
  final DateTime timestamp;
  
  HealthStatus(this.isHealthy, this.message) : timestamp = DateTime.now();
}
```

---

💡 **Tip**: Antes de crear un nuevo servicio, verificar si la funcionalidad puede agregarse a un servicio existente o si realmente justifica un servicio separado.
```dart
final persistenceService = AppDataPersistenceService.instance;

// Gestión de cuentas
await persistenceService.saveSelectedAccountId('account123');
String? accountId = await persistenceService.getSelectedAccountId();

// Gestión de tema
await persistenceService.saveThemeMode('dark');
String? theme = await persistenceService.getThemeMode();

// Gestión de tickets
await persistenceService.saveCurrentTicket(ticketJson);
String? ticket = await persistenceService.getCurrentTicket();

// Limpieza de datos
await persistenceService.clearSessionData(); // Solo datos de sesión
await persistenceService.clearAllData(); // Todos los datos
```

**Beneficios**:
- Centralización de toda la persistencia local
- API consistente para todos los tipos de datos
- Gestión de errores unificada
- Facilita el mantenimiento y testing

### `thermal_printer_http_service.dart`
**Propósito**: Servicio HTTP para comunicación con impresoras térmicas.

**Uso**: Envío de comandos de impresión a través de HTTP a impresoras térmicas en red.

## 🏗️ Patrón de Arquitectura

Los servicios siguen el patrón de **Clean Architecture**:
- **Independientes**: No dependen de frameworks específicos
- **Testables**: Fácil inyección de dependencias para testing
- **Reutilizables**: Pueden ser usados por múltiples capas
- **Centralizados**: Configuración única para toda la aplicación

## 🎨 Personalización de Temas

Para personalizar los temas de la aplicación:

1. **Cambiar color principal**:
```dart
// En ThemeService
static const MaterialColor seedColor = Colors.green; // Cambiar aquí
```

2. **Personalizar botones específicos**:
```dart
// Modificar los métodos _lightElevatedButtonTheme, _darkElevatedButtonTheme, etc.
```

3. **Agregar nuevos componentes**:
```dart
// Agregar nuevas configuraciones en lightTheme y darkTheme
dialogTheme: _lightDialogTheme,
```

## 🔧 Mejores Prácticas

1. **Mantenga las configuraciones centralizadas** en `ThemeService`
2. **Use constantes** para valores que se repiten
3. **Documente cambios** en los estilos personalizados
4. **Teste en ambos modos** (claro y oscuro) al hacer cambios
5. **Siga Material Design 3** guidelines para consistencia

## 🚀 Extensibilidad

Para agregar nuevos servicios:

1. Crear el archivo en esta carpeta
2. Seguir el patrón de singleton o static methods según corresponda
3. Documentar en este README
4. Agregar export en el archivo principal si es necesario
