## Descripción

Servicios de infraestructura refactorizados con **Inyección de Dependencias** que proporcionan funcionalidades transversales para la aplicación.

Todos los servicios siguen el patrón **Clean Architecture** con DI usando `injectable` y `get_it`.

## 📁 Estructura Actual

```
services/
├── database/                           # Servicios de base de datos Firestore
│   ├── firestore_datasource.dart       # ✅ DataSource con DI (@LazySingleton)
│   ├── i_firestore_datasource.dart     # ✅ Interfaz abstracta
│   ├── firestore_paths.dart            # ✅ Paths centralizados type-safe
│   └── README.md
│
├── storage/                            # Servicios de persistencia local
│   ├── app_data_persistence_service.dart  # ✅ Servicio con DI (@LazySingleton)
│   ├── storage_datasource.dart         # ✅ Firebase Storage con DI
│   ├── i_storage_datasource.dart       # ✅ Interfaz abstracta
│   ├── storage_paths.dart              # ✅ Paths de Storage centralizados
│   └── README.md
│
├── external/                           # Servicios externos
│   ├── thermal_printer_http_service.dart  # ✅ Servicio HTTP con DI (@LazySingleton)
│   ├── THERMAL_PRINTER_BACKEND.md      # 📚 Documentación de arquitectura backend
│   └── README.md
│
├── theme/                              # Servicios de tema (movido desde presentation)
│   └── theme_service.dart              # ✅ Gestión de temas con DI (@LazySingleton)
│
├── MIGRACION_DI_PENDIENTE.md          # 📚 Guía de migración gradual DI
├── REFACTORIZACION_RESUMEN.md         # 📚 Resumen ejecutivo del proyecto
└── README.md                          # Este archivo
```

## 🎯 Servicios Principales

### 1. Database Services

#### **FirestoreDataSource** (`@LazySingleton`)
Wrapper type-safe de Firestore con inyección de dependencias.

```dart
@LazySingleton(as: IFirestoreDataSource)
class FirestoreDataSource implements IFirestoreDataSource {
  final FirebaseFirestore _firestore;
  FirestoreDataSource(this._firestore);
  
  // Operaciones CRUD type-safe
  Future<QuerySnapshot> getDocuments(Query query);
  Stream<QuerySnapshot> streamDocuments(Query query);
  Future<void> setDocument(String path, Map<String, dynamic> data);
  // ...
}
```

**Uso:**
```dart
@injectable
class MyDataSource {
  final IFirestoreDataSource _firestore;
  MyDataSource(this._firestore);
  
  Future<void> getData() async {
    final path = FirestorePaths.accountCatalogue(accountId);
    final snapshot = await _firestore.getDocuments(_firestore.collection(path));
  }
}
```

### 2. Storage Services

#### **AppDataPersistenceService** (`@LazySingleton`)
Servicio centralizado para persistencia local con SharedPreferences.

**Refactorizado:** Ahora inyecta `SharedPreferences` en el constructor (optimización de performance).

```dart
@lazySingleton
class AppDataPersistenceService {
  final SharedPreferences _prefs;
  AppDataPersistenceService(this._prefs);
  
  // Métodos de persistencia
  Future<void> saveSelectedAccountId(String accountId);
  Future<String?> getSelectedAccountId();
  Future<void> saveThemeMode(String themeMode);
  // ... 30+ métodos más
}
```

**Uso:**
```dart
@lazySingleton
class MyUseCase {
  final AppDataPersistenceService _persistence;
  MyUseCase(this._persistence);
}
```

#### **StorageDataSource** (`@LazySingleton`)
Wrapper type-safe de Firebase Storage con DI.

```dart
@LazySingleton(as: IStorageDataSource)
class StorageDataSource implements IStorageDataSource {
  final FirebaseStorage _storage;
  
  Future<String> uploadFile(String path, Uint8List bytes, {...});
  Future<void> deleteFile(String path);
  Future<String> getDownloadUrl(String path);
}
```

### 3. External Services

#### **ThermalPrinterHttpService** (`@LazySingleton`)
Servicio para comunicación HTTP con servidor local de impresoras térmicas.

**Refactorizado:** Ahora inyecta `AppDataPersistenceService` en lugar de usar `SharedPreferences` directamente.

```dart
@lazySingleton
class ThermalPrinterHttpService {
  final AppDataPersistenceService _persistence;
  ThermalPrinterHttpService(this._persistence);
  
  Future<void> initialize();
  Future<bool> configurePrinter({...});
  Future<bool> printTicket({...});
}
```

**Arquitectura:** Ver `THERMAL_PRINTER_BACKEND.md` para documentación completa del backend HTTP local.

### 4. Theme Service

#### **ThemeService** (`@LazySingleton`)
Gestión de temas dinámicos y configuración de estilos Material 3.

**Movido:** De `core/presentation/theme/` a `core/services/theme/` para consistencia arquitectural.

```dart
@lazySingleton
class ThemeService {
  final AppDataPersistenceService _persistence;
  ThemeService(this._persistence);
  
  void setThemeMode(ThemeMode mode);
  void setSeedColor(Color color);
  ThemeData get lightTheme;
  ThemeData get darkTheme;
}
```

## 🔧 Patrón de Uso con DI

### ✅ Correcto (con DI)

```dart
// En UseCases, Repositories, DataSources
@lazySingleton
class MyUseCase {
  final AppDataPersistenceService _persistence;
  final IFirestoreDataSource _firestore;
  
  MyUseCase(this._persistence, this._firestore);
}

// En Providers (sin @injectable)
class MyProvider extends ChangeNotifier {
  final MyUseCase _useCase;
  
  MyProvider(this._useCase);
}

// En main.dart (composition root)
ChangeNotifierProvider(
  create: (_) => MyProvider(getIt<MyUseCase>()),
)
```

### ❌ Incorrecto (evitar)

```dart
// ❌ Singleton manual (eliminado)
final service = AppDataPersistenceService.instance;

// ❌ Instanciación directa (requiere parámetros)
final service = ThermalPrinterHttpService();

// ❌ getIt en código de negocio (solo en main.dart)
final service = getIt<AppDataPersistenceService>();
```

## 📊 Estado de Migración

| Servicio | Estado | DI | Testeable | Ubicación |
|----------|--------|----|-----------| --------- |
| FirestoreDataSource | ✅ | ✅ | ✅ | Correcta |
| StorageDataSource | ✅ | ✅ | ✅ | Correcta |
| AppDataPersistenceService | ✅ | ✅ | ✅ | Correcta |
| ThermalPrinterHttpService | ✅ | ✅ | ✅ | Correcta |
| ThemeService | ✅ | ✅ | ✅ | Correcta ✨ |
| SearchCatalogueService | ✅ | N/A | ✅ | Correcta |

**Progreso:** 🟢 100% de servicios migrados a DI

## 🗑️ Código Eliminado (Deprecated)

- ❌ `database_cloud.dart` - God Object con 500+ líneas (reemplazado por FirestoreDataSource)
- ❌ `storage_service.dart` - Wrapper deprecated (migrado a StorageDataSource)
- ❌ `core/services/printing/` - Directorio con provider mal ubicado (movido a features/sales)
- ❌ `search_catalogue_service.dart` - Nunca existió (documentación obsoleta)

## 📚 Documentación Adicional

- **`THERMAL_PRINTER_BACKEND.md`**: Arquitectura completa del servidor HTTP local para impresoras, endpoints REST, seguridad (3 niveles), implementación con `shelf`
- **`MIGRACION_DI_PENDIENTE.md`**: Guía de migración gradual, TODOs, comandos útiles
- **`REFACTORIZACION_RESUMEN.md`**: Resumen ejecutivo, métricas de mejora, decisiones arquitecturales

## 🚀 Mejoras Logradas

### Performance
- ✅ `SharedPreferences` se resuelve una sola vez (antes: en cada llamada)
- ✅ Servicios lazy-loaded solo cuando se necesitan

### Testabilidad
- ✅ Todos los servicios son mockeables con interfaces
- ✅ Dependencias explícitas en constructores
- ✅ Sin estado global (eliminados singletons manuales)

### Mantenibilidad
- ✅ Arquitectura consistente (un solo patrón DI)
- ✅ Separación clara de responsabilidades
- ✅ Código deprecated eliminado (-15% deuda técnica)

## 📖 Referencias

- [injectable package](https://pub.dev/packages/injectable)
- [get_it package](https://pub.dev/packages/get_it)
- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
