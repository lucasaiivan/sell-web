# Testing Guide

Guía completa para escribir y ejecutar tests en Flutter Web Sell App.

## Estructura de Testing

```
test/
├── helpers/
│   ├── mock_annotations.dart          # Anotaciones de Mockito
│   ├── mock_annotations.mocks.dart    # Mocks generados (auto)
│   └── test_helpers.dart              # Fixtures y builders
├── test_config.dart                   # Configuración global
└── features/
    └── [feature_name]/
        ├── domain/
        │   ├── entities/              # Tests de entidades
        │   └── usecases/              # Tests de casos de uso
        ├── data/
        │   ├── models/                # Tests de serialización
        │   ├── datasources/           # Tests de datasources
        │   └── repositories/          # Tests de repositories
        └── presentation/
            └── providers/             # Tests de providers
```

## Escribiendo Tests

### 1. Tests de UseCases (Domain Layer)

**Patrón:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sellweb/features/[feature]/domain/usecases/[usecase].dart';

import '../../../../helpers/test_helpers.dart';
import '../../../../test_config.dart';

void main() {
  late [UseCaseName] useCase;

  setUp(() {
    TestConfig.setUp();
    useCase = [UseCaseName]();
  });

  tearDown(() {
    TestConfig.tearDown();
  });

  group('[UseCaseName]', () {
    test('debe [comportamiento esperado]', () async {
      // Arrange
      final params = ...;

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('No debería retornar un Failure'),
        (success) {
          // Verificaciones
        },
      );
    });
  });
}
```

**Qué testear:**

- ✅ Casos exitosos (happy path)
- ✅ Validaciones de parámetros
- ✅ Manejo de errores
- ✅ Edge cases (valores límite, null, vacío)

### 2. Tests de Providers (Presentation Layer)

**Patrón:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sellweb/features/[feature]/presentation/providers/[provider].dart';

import '../../../../helpers/mock_annotations.mocks.dart';
import '../../../../test_config.dart';

void main() {
  late [ProviderName] provider;
  late Mock[UseCase] mockUseCase;

  setUp(() {
    TestConfig.setUp();
    mockUseCase = Mock[UseCase]();
    provider = [ProviderName](useCase: mockUseCase);
  });

  tearDown(() {
    TestConfig.tearDown();
  });

  group('[ProviderName]', () {
    test('debe inicializar con estado vacío', () {
      expect(provider.state, isNotNull);
    });

    test('debe notificar listeners al cambiar estado', () async {
      // Arrange
      var notified = false;
      provider.addListener(() => notified = true);

      // Act
      await provider.someMethod();

      // Assert
      expect(notified, true);
    });
  });
}
```

**Qué testear:**

- ✅ Estado inicial
- ✅ Notificaciones de listeners
- ✅ Llamadas a UseCases
- ✅ Manejo de estados de carga/error
- ✅ Persistencia (si aplica)

### 3. Tests de Repositories (Data Layer)

**Patrón:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sellweb/features/[feature]/data/repositories/[repository]_impl.dart';

import '../../../../../helpers/mock_annotations.mocks.dart';
import '../../../../../test_config.dart';

void main() {
  late [RepositoryName]Impl repository;
  late Mock[DataSource] mockDataSource;

  setUp(() {
    TestConfig.setUp();
    mockDataSource = Mock[DataSource]();
    repository = [RepositoryName]Impl(dataSource: mockDataSource);
  });

  tearDown(() {
    TestConfig.tearDown();
  });

  group('[RepositoryName]Impl', () {
    test('debe retornar Right cuando datasource tiene éxito', () async {
      // Arrange
      when(mockDataSource.someMethod()).thenAnswer((_) async => mockData);

      // Act
      final result = await repository.someMethod();

      // Assert
      expect(result.isRight(), true);
      verify(mockDataSource.someMethod()).called(1);
    });

    test('debe retornar Left cuando datasource falla', () async {
      // Arrange
      when(mockDataSource.someMethod()).thenThrow(Exception());

      // Act
      final result = await repository.someMethod();

      // Assert
      expect(result.isLeft(), true);
    });
  });
}
```

**Qué testear:**

- ✅ Delegación correcta a DataSource
- ✅ Conversión de excepciones a Failures
- ✅ Transformación de modelos a entidades

## Usando Test Helpers

### Fixtures Predefinidos

```dart
// Tickets
final emptyTicket = TestHelpers.emptyTicket;
final ticketWithProducts = TestHelpers.ticketWithProducts;

// Productos
final product1 = TestHelpers.testProduct1;
final product2 = TestHelpers.testProduct2;
final productNoStock = TestHelpers.productOutOfStock;
```

### Builders Personalizados

```dart
// Ticket custom
final customTicket = TestHelpers.buildTicket(
  id: 'custom-id',
  discount: 10.0,
  payMode: 'card',
);

// Producto custom
final customProduct = TestHelpers.buildProduct(
  code: 'CUSTOM001',
  salePrice: 99.99,
  stock: true,
  quantityStock: 50,
);
```

### Utilities

```dart
// Convertir producto a JSON para ticket
final productJson = TestHelpers.productToTicketJson(product, quantity: 5);

// Calcular total de ticket
final total = TestHelpers.calculateTicketTotal(products, discount: 10.0);
```

## Generando Mocks

### 1. Añadir clase a mock_annotations.dart

```dart
@GenerateMocks([
  // ... existing mocks
  YourNewRepository,
  YourNewDataSource,
])
void main() {}
```

### 2. Regenerar mocks

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Importar mocks generados

```dart
import '../../../helpers/mock_annotations.mocks.dart';
```

## Ejecutando Tests

### Todos los tests

```bash
flutter test
```

### Feature específico

```bash
flutter test test/features/sales/
```

### Archivo específico

```bash
flutter test test/features/sales/domain/usecases/add_product_to_ticket_usecase_test.dart
```

### Con cobertura

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Mejores Prácticas

### ✅ DO

- **Usar nombres descriptivos:** `test('debe agregar producto al ticket vacío')`
- **Seguir patrón AAA:** Arrange, Act, Assert
- **Un concepto por test:** Cada test verifica una sola cosa
- **Tests independientes:** No depender del orden de ejecución
- **Usar fixtures:** Reutilizar `TestHelpers` en lugar de crear datos inline
- **Verificar tanto success como failure:** Testear ambos caminos de `Either`

### ❌ DON'T

- **Tests dependientes:** No asumir estado de tests anteriores
- **Datos hardcodeados:** Usar builders en lugar de valores mágicos
- **Tests genéricos:** Evitar `test('funciona correctamente')`
- **Múltiples asserts no relacionados:** Dividir en tests separados
- **Ignorar edge cases:** Testear valores límite, null, vacío

## Convenciones de Nombres

### Archivos

```
[usecase_name]_test.dart
[provider_name]_test.dart
[repository_name]_impl_test.dart
```

### Tests

```dart
test('debe [acción] cuando [condición]', () async {
  // ...
});

test('debe retornar [Failure] si [condición inválida]', () async {
  // ...
});
```

### Groups

```dart
group('[ClassName]', () {
  group('[methodName]', () {
    test('...', () {});
  });
});
```

## Troubleshooting

### Error: "Undefined class 'Mock...'"

**Solución:** Regenerar mocks con build_runner

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Error: "The argument type 'X' can't be assigned to 'Y'"

**Solución:** Verificar que los fixtures en `TestHelpers` coincidan con la estructura actual de las entidades

### Tests fallan aleatoriamente

**Solución:** Verificar que `TestConfig.setUp()` y `tearDown()` se llamen correctamente para limpiar estado entre tests

### Mock no funciona

**Solución:** Verificar que:
1. La clase esté en `@GenerateMocks`
2. Se haya regenerado con build_runner
3. Se esté usando el mock correcto (`Mock[ClassName]`)

## Recursos

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Mockito Package](https://pub.dev/packages/mockito)
- [FpDart (Either)](https://pub.dev/packages/fpdart)
- [Clean Architecture Testing](https://resocoder.com/flutter-clean-architecture-tdd/)

## Contacto

Para preguntas sobre testing, consultar:
- `implementation_plan.md` - Plan completo de testing
- `walkthrough.md` - Walkthrough de implementación
- Tests existentes en `test/features/sales/domain/usecases/` - Ejemplos de referencia
