## Descripción
Sistema de **Inyección de Dependencias** (DI) usando `get_it` + `injectable` para una arquitectura limpia y testeable.

## Contenido
```
di/
├── injection_container.dart # Configuración manual de DI
└── injection_container.config.dart # Código generado por injectable
```

## 🎯 Propósito

Centralizar la creación y gestión de dependencias en la aplicación:
- **Singleton**: Instancias únicas compartidas (servicios, repositorios)
- **Factory**: Instancias nuevas cada vez (providers, usecases)
- **Lazy**: Inicialización diferida hasta primer uso

## 📦 Anotaciones Principales

### `@injectable`
Para clases que se registran automáticamente en el contenedor.

```dart
@injectable
class MyProvider extends ChangeNotifier {
  final MyUseCase _useCase;
  
  MyProvider(this._useCase);
}
```

### `@lazySingleton`
Para servicios que deben ser singleton con inicialización lazy.

```dart
@lazySingleton
class MyService {
  // Implementación
}
```

### `@LazySingleton(as: Interface)`
Para registrar una implementación bajo su contrato/interfaz.

```dart
@LazySingleton(as: MyRepository)
class MyRepositoryImpl implements MyRepository {
  // Implementación
}
```

## 🔄 Flujo de Uso

### 1. Anotar Clases
```dart
// Provider
@injectable
class CatalogueProvider extends ChangeNotifier {
  final GetProductsUseCase _getProducts;
  
  CatalogueProvider(this._getProducts);
}

// UseCase
@lazySingleton
class GetProductsUseCase extends UseCase<List<Product>, NoParams> {
  final CatalogueRepository _repository;
  
  GetProductsUseCase(this._repository);
  
  @override
  Future<Either<Failure, List<Product>>> call(NoParams params) async {
    return await _repository.getProducts();
  }
}

// Repository
@LazySingleton(as: CatalogueRepository)
class CatalogueRepositoryImpl implements CatalogueRepository {
  final CatalogueDataSource _dataSource;
  
  CatalogueRepositoryImpl(this._dataSource);
  
  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    // Implementación
  }
}

// DataSource
@lazySingleton
class CatalogueDataSource {
  final FirebaseFirestore _firestore;
  
  CatalogueDataSource(this._firestore);
}
```

### 2. Regenerar Código
Ejecutar build_runner cada vez que agregues/modifiques anotaciones:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Inicializar en main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar DI
  await configureDependencies();
  
  runApp(MyApp());
}
```

### 4. Usar Dependencias
```dart
// Manual (no recomendado)
final provider = getIt<CatalogueProvider>();

// Con Provider (recomendado)
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => getIt<CatalogueProvider>()),
    // ...
  ],
  child: MyApp(),
)
```

## ⚙️ Configuración de `injection_container.dart`

```dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection_container.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async => getIt.init();
```

## 🔍 Buenas Prácticas

### ✅ DO
- Usar `@injectable` para providers y clases con ciclo de vida corto
- Usar `@lazySingleton` para servicios y repositorios
- Registrar por contrato: `@LazySingleton(as: Interface)`
- Inyectar dependencias por constructor

### ❌ DON'T
- No usar getIt directamente en widgets (usar Provider)
- No crear instancias manualmente si están registradas en DI
- No olvidar regenerar código después de cambios

## 🛠️ Troubleshooting

### Error: "Type X is not registered"
**Solución**: Agregar anotación `@injectable` o `@lazySingleton` y regenerar.

### Error: "Circular dependency"
**Solución**: Revisar dependencias, puede que A dependa de B y B de A.

### Cambios no se reflejan
**Solución**: Ejecutar `flutter pub run build_runner build --delete-conflicting-outputs`

## 📖 Referencias
- [get_it Documentation](https://pub.dev/packages/get_it)
- [injectable Documentation](https://pub.dev/packages/injectable)
- [Clean Architecture + DI](https://resocoder.com/flutter-clean-architecture-tdd/)
