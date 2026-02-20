## Descripción
Contrato base para todos los Casos de Uso (UseCases) de la aplicación siguiendo Clean Architecture.

## Contenido
```
usecases/
└── usecase.dart # Interfaz base UseCase<T, Params>
```

## 🎯 Propósito

Definir un contrato unificado para encapsular la lógica de negocio:
- **Un UseCase = Una acción de usuario**
- **Independiente de UI y Data**
- **Fácilmente testeable**
- **Reutilizable**

## 📦 Definición

```dart
import 'package:fpdart/fpdart.dart';
import 'package:sellweb/core/errors/failures.dart';

/// Interfaz base para todos los casos de uso
/// [T] es el tipo de retorno del caso de uso
/// [Params] es el tipo de parámetro del caso de uso
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Clase para casos de uso sin parámetros
class NoParams {
  const NoParams();
}
```

## 🔄 Ejemplo Completo

### UseCase con parámetros
```dart
@lazySingleton
class GetProductByIdUseCase extends UseCase<Product, GetProductParams> {
  final ProductRepository _repository;
  
  GetProductByIdUseCase(this._repository);
  
  @override
  Future<Either<Failure, Product>> call(GetProductParams params) async {
    // Validaciones de negocio (opcional)
    if (params.productId.isEmpty) {
      return Left(ValidationFailure('ID de producto inválido'));
    }
    
    // Delegar al repository
    return await _repository.getProductById(params.productId);
  }
}

// Parámetros del UseCase
class GetProductParams {
  final String productId;
  
  const GetProductParams(this.productId);
}
```

### UseCase sin parámetros
```dart
@lazySingleton
class GetAllProductsUseCase extends UseCase<List<Product>, NoParams> {
  final ProductRepository _repository;
  
  GetAllProductsUseCase(this._repository);
  
  @override
  Future<Either<Failure, List<Product>>> call(NoParams params) async {
    return await _repository.getAllProducts();
  }
}
```

### UseCase con lógica de negocio
```dart
@lazySingleton
class ApplyDiscountUseCase extends UseCase<double, ApplyDiscountParams> {
  final SalesRepository _repository;
  
  ApplyDiscountUseCase(this._repository);
  
  @override
  Future<Either<Failure, double>> call(ApplyDiscountParams params) async {
    // Validaciones
    if (params.discount < 0 || params.discount > 100) {
      return Left(ValidationFailure('Descuento debe estar entre 0 y 100'));
    }
    
    if (params.totalPrice <= 0) {
      return Left(ValidationFailure('Precio total inválido'));
    }
    
    // Lógica de negocio
    final discountAmount = params.isPercentage
        ? params.totalPrice * (params.discount / 100)
        : params.discount;
        
    final finalPrice = params.totalPrice - discountAmount;
    
    if (finalPrice < 0) {
      return Left(ValidationFailure('El descuento excede el precio total'));
    }
    
    // Persistir (si es necesario)
    return await _repository.saveDiscount(params.orderId, discountAmount);
  }
}

class ApplyDiscountParams {
  final String orderId;
  final double totalPrice;
  final double discount;
  final bool isPercentage;
  
  const ApplyDiscountParams({
    required this.orderId,
    required this.totalPrice,
    required this.discount,
    required this.isPercentage,
  });
}
```

## 🔌 Integración con Provider

```dart
@injectable
class ProductProvider extends ChangeNotifier {
  final GetAllProductsUseCase _getAllProducts;
  final GetProductByIdUseCase _getProductById;
  
  List<Product> products = [];
  Product? selectedProduct;
  String? error;
  bool isLoading = false;
  
  ProductProvider(
    this._getAllProducts,
    this._getProductById,
  );
  
  Future<void> loadProducts() async {
    isLoading = true;
    notifyListeners();
    
    final result = await _getAllProducts(NoParams());
    
    result.fold(
      (failure) => error = failure.message,
      (productList) => products = productList,
    );
    
    isLoading = false;
    notifyListeners();
  }
  
  Future<void> selectProduct(String productId) async {
    final result = await _getProductById(GetProductParams(productId));
    
    result.fold(
      (failure) => error = failure.message,
      (product) => selectedProduct = product,
    );
    
    notifyListeners();
  }
}
```

## 📋 Convenciones de Nombrado

**Patrón**: `<Verbo><Sustantivo>UseCase`

Ejemplos:
- `GetProductsUseCase`
- `CreateOrderUseCase`
- `UpdateUserProfileUseCase`
- `DeleteProductUseCase`
- `ValidateStockUseCase`
- `CalculateTotalPriceUseCase`

## ✅ Buenas Prácticas

### DO
- Un UseCase por acción de usuario
- Validar parámetros antes de delegar
- Mantener lógica de negocio en UseCase
- Usar `@lazySingleton` para registro DI
- Retornar `Either<Failure, T>`

### DON'T
- No poner lógica de UI en UseCase
- No acceder directamente a DataSources
- No tener múltiples responsabilidades
- No hacer UseCases demasiado genéricos

## 🧪 Testing

```dart
void main() {
  late GetProductByIdUseCase useCase;
  late MockProductRepository mockRepository;
  
  setUp(() {
    mockRepository = MockProductRepository();
    useCase = GetProductByIdUseCase(mockRepository);
  });
  
  test('should return Product when repository succeeds', () async {
    // Arrange
    final expectedProduct = Product(id: '1', name: 'Test');
    when(mockRepository.getProductById(any))
        .thenAnswer((_) async => Right(expectedProduct));
    
    // Act
    final result = await useCase(GetProductParams('1'));
    
    // Assert
    expect(result, Right(expectedProduct));
    verify(mockRepository.getProductById('1'));
  });
  
  test('should return ValidationFailure for empty ID', () async {
    // Act
    final result = await useCase(GetProductParams(''));
    
    // Assert
    expect(result, isA<Left>());
    result.fold(
      (failure) => expect(failure, isA<ValidationFailure>()),
      (_) => fail('Should return failure'),
    );
    verifyNever(mockRepository.getProductById(any));
  });
}
```

## 📖 Referencias
- [Clean Architecture - Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Use Case Pattern](https://resocoder.com/flutter-clean-architecture-tdd/)
