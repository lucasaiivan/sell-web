# Refactorización de Sales UseCases

## 📋 Resumen

Se dividió `SellUsecases` (467 líneas, ~20 métodos) en **15 UseCases atómicos** siguiendo Clean Architecture.

---

## 📦 UseCases Creados

### 1. Creación de Tickets (2)

#### CreateEmptyTicketUseCase
- **Responsabilidad:** Crear ticket temporal vacío en memoria
- **Params:** NoParams
- **Retorno:** TicketModel
- **Validaciones:** Ninguna (siempre exitoso)

#### UpdateTicketFieldsUseCase
- **Responsabilidad:** Modificar metadatos del ticket sin alterar productos
- **Params:** UpdateTicketFieldsParams (ticket actual + campos opcionales)
- **Retorno:** TicketModel
- **Validaciones:**
  - Descuento no negativo
  - Valor recibido no negativo
  - Precio total no negativo

### 2. Gestión de Productos (3)

#### AddProductToTicketUseCase
- **Responsabilidad:** Agregar producto al ticket (incrementa cantidad si existe)
- **Params:** AddProductToTicketParams (ticket, producto, replaceQuantity)
- **Retorno:** TicketModel
- **Validaciones:**
  - Producto con ID válido
  - Precio de venta no negativo

#### RemoveProductFromTicketUseCase
- **Responsabilidad:** Remover producto del ticket
- **Params:** RemoveProductFromTicketParams (ticket, producto)
- **Retorno:** TicketModel
- **Validaciones:**
  - Producto con ID válido

#### CreateQuickProductUseCase
- **Responsabilidad:** Crear producto temporal sin código de barras
- **Params:** CreateQuickProductParams (descripción, precio)
- **Retorno:** ProductCatalogue
- **Validaciones:**
  - Precio no negativo
  - Descripción no vacía

### 3. Configuración de Pago y Descuento (3)

#### SetTicketPaymentModeUseCase
- **Responsabilidad:** Establecer forma de pago del ticket
- **Params:** SetTicketPaymentModeParams (ticket, payMode)
- **Retorno:** TicketModel
- **Validaciones:**
  - PayMode válido (effective, card, mercadopago, '')
  - Resetea valueReceived si no es efectivo

#### SetTicketDiscountUseCase
- **Responsabilidad:** Configurar descuento (absoluto o porcentaje)
- **Params:** SetTicketDiscountParams (ticket, discount, isPercentage)
- **Retorno:** TicketModel
- **Validaciones:**
  - Descuento no negativo

#### SetTicketReceivedCashUseCase
- **Responsabilidad:** Establecer monto recibido en efectivo
- **Params:** SetTicketReceivedCashParams (ticket, value)
- **Retorno:** TicketModel
- **Validaciones:**
  - Valor no negativo

### 4. Asociaciones (2)

#### AssociateTicketWithCashRegisterUseCase
- **Responsabilidad:** Vincular ticket con caja registradora activa
- **Params:** AssociateTicketWithCashRegisterParams (ticket, cashRegister)
- **Retorno:** TicketModel
- **Validaciones:**
  - Caja con ID válido
  - Caja con descripción no vacía

#### AssignSellerToTicketUseCase
- **Responsabilidad:** Asignar vendedor al ticket
- **Params:** AssignSellerToTicketParams (ticket, sellerId, sellerName)
- **Retorno:** TicketModel
- **Validaciones:**
  - SellerId no vacío
  - SellerName no vacío

### 5. Preparación para Venta (2)

#### PrepareSaleTicketUseCase
- **Responsabilidad:** Validar y finalizar ticket antes de venta
- **Params:** PrepareSaleTicketParams (ticket, sellerId, sellerName, cashRegister?)
- **Retorno:** TicketModel
- **Validaciones:**
  - Vendedor válido
  - Caja válida (si se proporciona)
  - Productos no vacíos
  - Precio total > 0
- **Lógica:**
  - Asigna vendedor
  - Asocia caja si existe
  - Calcula precio total con descuento
  - Genera ID si no existe

#### PrepareTicketForTransactionUseCase
- **Responsabilidad:** Preparar ticket para historial de transacciones
- **Params:** PrepareTicketForTransactionParams (ticket)
- **Retorno:** TicketModel
- **Validaciones:**
  - Productos no vacíos
  - Precio total > 0
  - SellerId existe
- **Lógica:**
  - Genera ID si no existe
  - Normaliza nombre de caja (o 'Sin caja asignada')
  - Usa getTotalPrice (incluye descuento)

### 6. Persistencia Local (4)

#### SaveLastSoldTicketUseCase
- **Responsabilidad:** Guardar último ticket en SharedPreferences
- **Params:** SaveLastSoldTicketParams (ticket)
- **Retorno:** void
- **Validaciones:**
  - Ticket con ID válido
  - Productos no vacíos
  - Precio total > 0
- **Error:** CacheFailure

#### GetLastSoldTicketUseCase
- **Responsabilidad:** Recuperar último ticket de SharedPreferences
- **Params:** NoParams
- **Retorno:** TicketModel? (null si no existe)
- **Lógica:**
  - Maneja ticket corrupto (deserialización fallida)
  - Auto-limpia si hay error
- **Error:** CacheFailure

#### ClearLastSoldTicketUseCase
- **Responsabilidad:** Eliminar último ticket de SharedPreferences
- **Params:** NoParams
- **Retorno:** void
- **Error:** CacheFailure

#### HasLastSoldTicketUseCase
- **Responsabilidad:** Verificar existencia de ticket guardado
- **Params:** NoParams
- **Retorno:** bool
- **Error:** CacheFailure

---

## 🔄 Patrón Aplicado

Todos los UseCases siguen:

```dart
@lazySingleton
class MyUseCase implements UseCase<ReturnType, Params> {
  // Inyección de dependencias (si necesita)
  final AppDataPersistenceService _service;
  
  MyUseCase(this._service);

  @override
  Future<Either<Failure, ReturnType>> call(Params params) async {
    try {
      // Validaciones de negocio
      if (invalid) {
        return Left(ValidationFailure('mensaje'));
      }

      // Lógica de negocio
      final result = businessLogic();

      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Error: $e'));
    }
  }
}
```

---

## 🎯 Características Clave

### ✅ Ventajas

1. **Separación de responsabilidades:** Cada UseCase tiene una única responsabilidad
2. **Testeable:** Fácil crear tests unitarios con mocks
3. **Validaciones centralizadas:** Todas las validaciones están en los UseCases
4. **Error handling consistente:** Siempre retorna `Either<Failure, T>`
5. **Independiente de UI:** No conoce providers ni widgets
6. **Reutilizable:** Cualquier capa puede usar los UseCases

### 🔧 Tipos de Failure Usados

- **ValidationFailure:** Errores de validación de negocio (descuentos negativos, IDs vacíos, etc.)
- **ServerFailure:** Errores inesperados (catch general)
- **CacheFailure:** Errores de persistencia local (SharedPreferences)

### 📝 Convenciones

- Todos los UseCases terminan en `UseCase`
- Los parámetros se encapsulan en clases `*Params`
- Si no hay parámetros, se usa `NoParams`
- Los UseCases nunca lanzan excepciones, siempre retornan Either
- Las validaciones se hacen ANTES de la lógica de negocio

---

## 📦 Dependencias

Los UseCases de Sales dependen de:

- `AppDataPersistenceService` (4 UseCases de persistencia)
- No tienen repositorios (lógica en memoria)
- Entidades: `TicketModel`, `ProductCatalogue`, `CashRegister`

---

## ✅ SalesProvider Actualizado

El `SalesProvider` ha sido completamente refactorizado para usar los nuevos UseCases con pattern `Either<Failure, T>`:

### Métodos actualizados (12):

1. **addProductsticket** → AddProductToTicketUseCase
2. **removeProduct** → RemoveProductFromTicketUseCase
3. **addQuickProduct** → CreateQuickProductUseCase
4. **setPayMode** → SetTicketPaymentModeUseCase
5. **setDiscount** → SetTicketDiscountUseCase
6. **setReceivedCash** → SetTicketReceivedCashUseCase
7. **saveLastSoldTicket** → SaveLastSoldTicketUseCase
8. **_loadLastSoldTicket** → GetLastSoldTicketUseCase
9. **_reloadLastSoldTicketFromPersistence** → GetLastSoldTicketUseCase
10. **updateTicketWithCashRegister** → AssociateTicketWithCashRegisterUseCase
11. **_prepareTicketForSale** → PrepareSaleTicketUseCase
12. **_saveToTransactionHistory** → PrepareTicketForTransactionUseCase

### Patrón aplicado:

```dart
final result = await _addProductToTicketUseCase(
  AddProductToTicketParams(
    currentTicket: _state.ticket,
    product: product,
    replaceQuantity: replaceQuantity,
  ),
);

result.fold(
  (failure) {
    if (kDebugMode) {
      print('❌ Error: ${failure.message}');
    }
  },
  (updatedTicket) {
    _state = _state.copyWith(ticket: updatedTicket);
    notifyListeners();
  },
);
```

### Cambios importantes:

- **Métodos ahora son async:** Todos los métodos que usan UseCases ahora son `Future<void>`
- **Manejo de errores consistente:** Uso de `.fold()` en lugar de `try-catch`
- **No se lanzan excepciones:** Errores se manejan con Either, se loguean pero no se propagan
- **Constructor actualizado:** 14 UseCases inyectados vía constructor

---

**Completado:** 25 de noviembre de 2025
**Archivos creados:** 15 UseCases + SalesProvider refactorizado
**Líneas refactorizadas:** ~467 líneas divididas + ~1300 líneas del provider actualizadas
**Build status:** ✅ Sin errores de compilación
**Estado:** 🟢 Completamente funcional
