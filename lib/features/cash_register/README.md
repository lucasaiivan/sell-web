# Feature: Cash Register

## Propósito
Gestión del **ciclo de vida de cajas registradoras** - apertura, cierre, arqueos, flujos de caja (ingresos/egresos), y reconciliación financiera.

## Responsabilidades
- Abrir/cerrar cajas registradoras
- Gestionar flujos de caja (ingresos/egresos)
- Realizar arqueos de caja
- Mantener histórico de operaciones
- Reconciliación de efectivo
- Gestión de turnos de cajeros
- Descripciones fijas para movimientos

## Estructura

```
cash_register/
├── domain/
│   ├── entities/
│   │   ├── cash_register.dart
│   │   └── cash_flow.dart
│   ├── repositories/
│   │   └── cash_register_repository.dart
│   └── usecases/
│       └── cash_register_usecases.dart
├── data/
│   └── repositories/
│       └── cash_register_repository_impl.dart
└── presentation/
    ├── providers/
    │   └── cash_register_provider.dart
    └── dialogs/
        └── cash_flow_dialog.dart
```

## Entities (Domain)

### `CashRegister` (Inmutable)
```dart
class CashRegister {
  final String id;
  final String description;
  final String idUser;
  final String nameUser;
  final double initialCash;
  final DateTime opening;
  final DateTime closure;
  final int sales;
  final int annulledTickets;
  final double billing;
  final double discount;
  final double cashInFlow;
  final double cashOutFlow;
  final double expectedBalance;
  final double balance;
  final List<dynamic> cashInFlowList;
  final List<dynamic> cashOutFlowList;
  // ...
}
```

### `CashFlow`
```dart
class CashFlow {
  final double amount;
  final String description;
  final DateTime timestamp;
  final String userId;
}
```

## Repository Contract

### `CashRegisterRepository`
Define operaciones abstractas:

**Cajas Activas:**
```dart
Future<List<CashRegister>> getActiveCashRegisters(String accountId);
Stream<List<CashRegister>> getActiveCashRegistersStream(String accountId);
Future<void> setCashRegister(String accountId, CashRegister cashRegister);
Future<void> deleteCashRegister(String accountId, String cashRegisterId);
```

**Historial:**
```dart
Future<List<CashRegister>> getCashRegisterHistory(String accountId);
Future<List<CashRegister>> getCashRegisterByDateRange({...});
Future<List<CashRegister>> getTodayCashRegisters(String accountId);
```

**Operaciones:**
```dart
Future<CashRegister> openCashRegister({...});
Future<CashRegister> closeCashRegister({...});
Future<void> addCashInflow({...});
Future<void> addCashOutflow({...});
Future<void> updateSalesAndBilling({...});
Future<void> updateBillingOnAnnullment({...});
```

**Transacciones:**
```dart
Future<void> saveTicketTransaction({...});
Future<List<Map<String, dynamic>>> getTransactionsByDateRange({...});
```

## Repository Implementation

### `CashRegisterRepositoryImpl`
**Data Source:** Firebase Firestore

**Colecciones:**
- `accounts/{accountId}/cashRegisters` - Cajas activas
- `accounts/{accountId}/cashRegisterHistory` - Historial de arqueos
- `accounts/{accountId}/fixedDescriptions` - Descripciones predefinidas
- `accounts/{accountId}/transactions` - Transacciones de venta

## Use Cases

### `CashRegisterUseCases`
**Inyección de Dependencias:**
```dart
@lazySingleton
class CashRegisterUseCases {
  final CashRegisterRepository _repository;
  
  // Operaciones delegadas al repository
  Future<CashRegister> openCashRegister({...});
  Future<CashRegister> closeCashRegister({...});
  Future<void> addCashInflow({...});
  Future<void> addCashOutflow({...});
  // ...
}
```

## Provider Principal

### `CashRegisterProvider`
**Responsabilidad:** Estado y operaciones de caja

```dart
@injectable
class CashRegisterProvider extends ChangeNotifier {
  final CashRegisterUseCases _useCases;
  
  CashRegister? _activeCashRegister;
  List<CashRegister> _cashRegisterHistory = [];
  
  // Operaciones
  Future<void> openCashRegister({...});
  Future<void> closeCashRegister({...});
  Future<void> addCashInflow({...});
  Future<void> addCashOutflow({...});
}
```

## Diálogos

### `CashFlowDialog`
Gestión de ingresos/egresos de caja:
- Agregar ingreso (entrada de dinero)
- Agregar egreso (salida de dinero)
- Descripción del movimiento
- Validaciones de monto

**Otros Diálogos (en features/sales):**
- `CashRegisterOpenDialog` - Abrir caja
- `CashRegisterCloseDialog` - Cerrar con arqueo
- `CashRegisterManagementDialog` - Vista completa de gestión

## Integración con Sales

Sales actualiza cash register en cada venta:

```dart
// En SalesProvider al confirmar venta
await _cashRegisterUseCases.updateSalesAndBilling(
  accountId: accountId,
  cashRegisterId: currentCashRegisterId,
  billingIncrement: ticket.getTotalPrice,
  discountIncrement: ticket.discount,
);
```

## Características Especiales

### Flujos de Caja
- **Ingresos (cashInFlow)** - Dinero que entra (no ventas)
- **Egresos (cashOutFlow)** - Dinero que sale (gastos)
- **Lista detallada** - Historial de cada movimiento

### Arqueo de Caja
Al cerrar caja:
1. Cálculo de balance esperado
2. Ingreso de balance real
3. Diferencia (faltante/sobrante)
4. Movimiento a historial

### Transacciones
Registro de cada venta para auditoría:
- Ticket ID
- Timestamp
- Monto
- Método de pago
- Productos vendidos

## Clean Architecture

✅ **Domain puro** - Sin dependencias de Flutter/Firebase
✅ **Repository pattern** - Contrato abstracto
✅ **Data layer** - Firebase implementation
✅ **Use Cases** - Lógica de negocio encapsulada
✅ **DI** - @lazySingleton con get_it

## Por qué es Feature Separado

**Cash Register NO pertenece a Sales** porque:

1. **Bounded Context Independiente**
   - Cash register = Gestión financiera, turnos, reconciliación
   - Sales = Creación de tickets, productos, precios

2. **Lógica de Negocio Independiente**
   - No todos los movimientos de caja son ventas
   - Ingresos/egresos externos
   - Arqueos de cierre
   - Múltiples cajeros por turno

3. **Reusabilidad**
   - Puede ser usado por otros módulos (gastos, reembolsos, etc.)
   - Lógica auto-contenida

4. **Testing Independiente**
   - Se puede testear cash register sin sales
   - Facilita unit testing

## Descripiones Fijas

Feature para nombrar cajas:
```dart
Future<void> createCashRegisterFixedDescription(String description);
Future<List<Map<String, dynamic>>> getCashRegisterFixedDescriptions();
Future<void> deleteCashRegisterFixedDescription(String descriptionId);
```

Ejemplos: "Caja Principal", "Caja Turno Mañana", etc.
