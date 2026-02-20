## Descripción
Manejo de errores centralizado usando el patrón **Either** de programación funcional para representar éxito o falla.

## Contenido
```
errors/
├── errors.dart # Barrel file
├── failures.dart # Tipos de errores del dominio
└── exceptions.dart # Excepciones técnicas
```

## 🎯 Filosofía

**Separation of Concerns**:
- `Exception`: Errores técnicos en Data Layer (red, DB, parsing)
- `Failure`: Errores de negocio en Domain Layer (validación, lógica)

## 📦 Failures (Domain Layer)

Representan errores de lógica de negocio. Son inmutables y descriptivos.

```dart
// lib/core/errors/failures.dart
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Error en el servidor']) 
      : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Error de caché']) 
      : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}
```

## ⚠️ Exceptions (Data Layer)

Representan errores técnicos que se convierten en Failures.

```dart
// lib/core/errors/exceptions.dart
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Error del servidor']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Error de caché']);
}

class NetworkException implements Exception {
  const NetworkException();
}
```

## 🔄 Flujo de Uso

### 1. Data Layer → Lanza Exceptions
```dart
@lazySingleton
class ProductDataSource {
  final FirebaseFirestore _firestore;
  
  ProductDataSource(this._firestore);
  
  Future<List<ProductModel>> getProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      return snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw ServerException('No se pudieron obtener productos');
    }
  }
}
```

### 2. Repository → Convierte Exception en Failure
```dart
@LazySingleton(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository {
  final ProductDataSource _dataSource;
  
  ProductRepositoryImpl(this._dataSource);
  
  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final products = await _dataSource.getProducts();
      return Right(products.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return Left(ServerFailure('Sin conexión a internet'));
    } catch (e) {
      return Left(ServerFailure('Error inesperado'));
    }
  }
}
```

### 3. UseCase → Propaga Either
```dart
@lazySingleton
class GetProductsUseCase extends UseCase<List<Product>, NoParams> {
  final ProductRepository _repository;
  
  GetProductsUseCase(this._repository);
  
  @override
  Future<Either<Failure, List<Product>>> call(NoParams params) async {
    return await _repository.getProducts();
  }
}
```

### 4. Presentation → Maneja Either
```dart
@injectable
class ProductProvider extends ChangeNotifier {
  final GetProductsUseCase _getProducts;
  
  List<Product> products = [];
  String? error;
  bool isLoading = false;
  
  ProductProvider(this._getProducts);
  
  Future<void> loadProducts() async {
    isLoading = true;
    error = null;
    notifyListeners();
    
    final result = await _getProducts(NoParams());
    
    result.fold(
      (failure) {
        error = failure.message;
        isLoading = false;
        notifyListeners();
      },
      (productList) {
        products = productList;
        isLoading = false;
        notifyListeners();
      },
    );
  }
}
```

## 📋 Tipos de Failures Comunes

```dart
// Errores de servidor/red
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Error en el servidor']) 
      : super(message);
}

// Errores de caché/storage
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Error de caché']) 
      : super(message);
}

// Errores de validación
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

// No encontrado
class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'No encontrado']) 
      : super(message);
}

// Sin autenticación
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String message = 'No autorizado']) 
      : super(message);
}
```

## 🎨 Patrón Either

El patrón Either viene de `fpdart` y representa un valor que puede ser **Left** (error) o **Right** (éxito).

```dart
import 'package:fpdart/fpdart.dart';

// Retornar éxito
return Right(data);

// Retornar error
return Left(ServerFailure());

// Manejar resultado
result.fold(
  (failure) => print('Error: ${failure.message}'),
  (data) => print('Éxito: $data'),
);
```

## ✅ Buenas Prácticas

### DO
- Usar `Exception` en Data Layer
- Usar `Failure` en Domain y Presentation  
- Convertir exceptions a failures en Repository
- Hacer failures inmutables (const)
- Mensajes de error descriptivos

### DON'T
- No lanzar Failures (solo retornar en Either)
- No usar try-catch en Presentation (usar fold)
- No mezclar Exception con Failure
- No capturar Exception en Domain Layer

## 📖 Referencias
- [fpdart - Either](https://pub.dev/packages/fpdart)
- [Clean Architecture Error Handling](https://resocoder.com/flutter-clean-architecture-tdd/)
