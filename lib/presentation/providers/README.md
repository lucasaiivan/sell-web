# Providers - Gestión de Estado UI

## Descripción
Providers que coordinan la interfaz de usuario con los casos de uso del dominio siguiendo arquitectura limpia.

**Principio fundamental:** Los providers NO contienen lógica de negocio, solo coordinan UI y UseCases.

---

## 🎯 Responsabilidades de un Provider

### ✅ SÍ debe hacer:
- Gestionar estado de UI (loading, error, success)
- Coordinar llamadas a UseCases y servicios
- Manejar controllers de formularios
- Escuchar streams y actualizar UI
- Persistir datos con AppDataPersistenceService
- Notificar cambios a los listeners

### ❌ NO debe hacer:
- Validaciones de negocio (delegar a UseCases)
- Transformaciones de datos (delegar a UseCases)
- Acceso directo a Firebase/bases de datos (delegar a repositorios)
- Cálculos complejos (delegar a UseCases)
- Generación de IDs (delegar a UseCases)

---

## 📁 Contenido

### **auth_provider.dart**
Gestiona autenticación de usuarios y cuentas asociadas
- Delega a: `AuthUseCases`, `AccountsUseCase`
- Estado: usuario actual, cuentas, loading, errores
- Sin lógica de negocio

### **cash_register_provider.dart**
Gestiona cajas registradoras, transacciones y arqueos
- Delega a: `CashRegisterUsecases`, `SellUsecases`
- Estado: cajas activas, historial, tickets, loading
- Streams de Firebase para sincronización en tiempo real
- Arquitectura con estado inmutable

### **catalogue_provider.dart**
Gestiona catálogo de productos y búsquedas
- Delega a: `CatalogueUseCases`, `SearchCatalogueService`
- Estado: productos, búsquedas, loading
- Búsqueda con debouncing para optimización
- Streams de Firebase para actualizaciones automáticas

### **home_provider.dart**
Gestiona navegación entre páginas principales
- Sin casos de uso (solo navegación UI)
- Estado: índice de página actual

### **printer_provider.dart**
Gestiona conexión con impresora térmica
- Delega a: `ThermalPrinterHttpService`
- Estado: conexión, errores

### **sell_provider.dart**
Gestiona proceso de ventas y tickets
- Delega a: `SellUsecases`, `CashRegisterUsecases`, `CatalogueUseCases`
- Estado: ticket actual, cuenta, admin profile, último ticket
- Coordina flujo completo de venta
- Arquitectura con estado inmutable

### **theme_data_app_provider.dart**
Gestiona tema visual de la aplicación
- Delega a: `ThemeService`, `AppDataPersistenceService`
- Estado: modo claro/oscuro, color semilla

---

## 🏗️ Arquitectura de Providers Complejos

Los providers complejos (`CashRegisterProvider`, `SellProvider`, `CatalogueProvider`) usan **estado inmutable** para optimizar notificaciones:

```dart
class _ProviderState {
  final Data data;
  final bool isLoading;
  final String? error;
  
  _ProviderState copyWith({...}) => _ProviderState(...);
}

class MyProvider extends ChangeNotifier {
  _ProviderState _state = _ProviderState(...);
  
  // Getters exponen estado
  Data get data => _state.data;
  
  // Métodos actualizan estado inmutable
  void updateData(Data newData) {
    _state = _state.copyWith(data: newData);
    notifyListeners();
  }
}
```

**Ventajas:**
- Actualizaciones atómicas
- Fácil debugging
- Mejor performance (comparación por referencia)

---

## 🔄 Flujo de Coordinación

```
UI (Widget)
    ↓
Provider (Coordina)
    ↓
UseCase (Lógica de negocio)
    ↓
Repository (Datos)
    ↓
Firebase / SharedPreferences
```

**Ejemplo - Confirmar Venta:**
```dart
// ❌ INCORRECTO - Lógica en Provider
void processSale() {
  final total = ticket.products.fold(0, (sum, p) => sum + p.price);
  if (total > 0) {
    // Validación de negocio en provider
  }
}

// ✅ CORRECTO - Delegar a UseCase
Future<void> processSale() async {
  final preparedTicket = _sellUsecases.prepareSaleTicket(ticket);
  await _cashRegisterUsecases.saveTicket(preparedTicket);
  await _catalogueUseCases.updateProductStats(preparedTicket);
}
```

---

## 🧪 Testing

Los providers deben ser fáciles de testear porque solo coordinan:

```dart
test('Should call usecase when adding product', () {
  final mockUsecase = MockSellUsecases();
  final provider = SellProvider(sellUsecases: mockUsecase);
  
  provider.addProduct(product);
  
  verify(mockUsecase.addProductToTicket(any, product)).called(1);
});
```

### **Métodos Simplificados:**

Todos los métodos siguen este patrón:

```dart
Future<bool> metodoProvider(...) async {
  // 1. Actualizar estado UI (loading)
  _state = _state.copyWith(isProcessing: true, errorMessage: null);
  notifyListeners();

  try {
    // 2. Delegar al UseCase (lógica de negocio)
    final resultado = await _usecases.metodoUseCase(...);
    
    // 3. Actualizar estado UI (success)
    _updateUIState(resultado);
    return true;
    
  } catch (e) {
    // 4. Actualizar estado UI (error)
    _state = _state.copyWith(errorMessage: e.toString());
    return false;
    
  } finally {
    // 5. Siempre limpiar loading
    _state = _state.copyWith(isProcessing: false);
    notifyListeners();
  }
}
```

### **Ejemplo Real:**

```dart
/// Abre una nueva caja registradora
/// 
/// RESPONSABILIDAD: Solo coordinar UI y llamar al UseCase
/// Las validaciones y lógica de negocio están en CashRegisterUsecases
Future<bool> openCashRegister(String accountId, String cashierId) async {
  _state = _state.copyWith(isProcessing: true, errorMessage: null);
  notifyListeners();

  try {
    // UseCase maneja TODAS las validaciones
    final newCashRegister = await _cashRegisterUsecases.openCashRegister(
      accountId: accountId,
      description: openDescriptionController.text,
      initialCash: initialCashController.doubleValue,
      cashierId: cashierId,
    );

    // Solo actualizar UI
    await selectCashRegister(newCashRegister);
    _clearOpenForm();
    
    return true;
  } catch (e) {
    _state = _state.copyWith(errorMessage: e.toString());
    return false;
  } finally {
    _state = _state.copyWith(isProcessing: false);
    notifyListeners();
  }
}
```

## 🔄 Flujo de Datos

```
┌─────────────────────────────────────────────┐
│  UI (Widget)                                │
│  • Muestra estado                           │
│  • Captura eventos del usuario             │
└────────────┬────────────────────────────────┘
             │ 1. Usuario interactúa
             ↓
┌────────────▼────────────────────────────────┐
│  PROVIDER                                   │
│  • Actualiza estado UI (loading)           │
│  • Lee datos de controllers                │
└────────────┬────────────────────────────────┘
             │ 2. Llama al UseCase
             ↓
┌────────────▼────────────────────────────────┐
│  USECASE (Domain)                           │
│  • Valida datos                            │
│  • Transforma datos                        │
│  • Aplica reglas de negocio                │
└────────────┬────────────────────────────────┘
             │ 3. Llama al Repository
             ↓
┌────────────▼────────────────────────────────┐
│  REPOSITORY (Data)                          │
│  • Accede a Firebase                       │
│  • Guarda/recupera datos                   │
└────────────┬────────────────────────────────┘
             │ 4. Retorna resultado
             ↓
┌────────────▼────────────────────────────────┐
│  PROVIDER                                   │
│  • Actualiza estado UI (success/error)    │
│  • notifyListeners()                       │
└────────────┬────────────────────────────────┘
             │ 5. Reconstruye UI
             ↓
┌────────────▼────────────────────────────────┐
│  UI (Widget)                                │
│  • Muestra resultado                       │
│  • Actualiza visualización                 │
└─────────────────────────────────────────────┘
```

## 📝 Controllers de Formularios

Los Providers manejan `TextEditingController` para formularios:

```dart
// Form controllers
final TextEditingController openDescriptionController = TextEditingController();
final AppMoneyTextEditingController initialCashController = AppMoneyTextEditingController();
final AppMoneyTextEditingController finalBalanceController = AppMoneyTextEditingController();
final TextEditingController movementDescriptionController = TextEditingController();
final AppMoneyTextEditingController movementAmountController = AppMoneyTextEditingController();
```

**IMPORTANTE:** Siempre limpiar controllers en `dispose()`:

```dart
@override
void dispose() {
  openDescriptionController.dispose();
  initialCashController.dispose();
  // ... más controllers
  super.dispose();
}
```

## 🎨 Gestión de Estado

### **Estado Inmutable:**
```dart
// ✅ CORRECTO: Crear nuevo estado
_state = _state.copyWith(isProcessing: true);

// ❌ INCORRECTO: Mutar estado directamente
_state.isProcessing = true;
```

### **Notificación de Cambios:**
```dart
// ✅ CORRECTO: Notificar después de cambio completo
_state = _state.copyWith(errorMessage: null);
notifyListeners();

// ❌ INCORRECTO: Notificar antes de cambiar
notifyListeners();
_state = _state.copyWith(errorMessage: null);
```

## 🔍 Manejo de Errores

Todos los métodos capturan y muestran errores de forma consistente:

```dart
try {
  await _usecases.metodo(...);
  return true;
} catch (e) {
  // Guardar error en el estado para mostrarlo en UI
  _state = _state.copyWith(errorMessage: e.toString());
  notifyListeners();
  return false;
}
```

## 📖 Uso desde Widgets

### **Consumer Pattern:**
```dart
Consumer<CashRegisterProvider>(
  builder: (context, provider, child) {
    if (provider.isLoading) {
      return CircularProgressIndicator();
    }
    
    if (provider.errorMessage != null) {
      return Text('Error: ${provider.errorMessage}');
    }
    
    return YourWidget(data: provider.activeCashRegisters);
  },
)
```

### **Provider.of Pattern:**
```dart
final provider = Provider.of<CashRegisterProvider>(context, listen: false);
await provider.openCashRegister(accountId, cashierId);
```

### **context.read / context.watch:**
```dart
// Leer sin escuchar cambios
final provider = context.read<CashRegisterProvider>();

// Leer y escuchar cambios
final provider = context.watch<CashRegisterProvider>();
```

## 🎯 Principios Clave

### **1. Separation of Concerns**
- Provider: UI + Coordinación
- UseCase: Lógica de negocio
- Repository: Acceso a datos

### **2. Single Responsibility**
Cada Provider gestiona un dominio específico de la aplicación.

### **3. Immutability**
El estado siempre es inmutable y se actualiza mediante `copyWith()`.

### **4. Error Handling**
Todos los errores se capturan y se muestran al usuario de forma clara.

## 📚 Referencias

- Ver `REFACTORING_CLEAN_ARCHITECTURE.md` para detalles de la refactorización
- Ver `domain/README.md` para entender los UseCases
- Ver `domain/usecases/cash_register_usecases.dart` para la lógica de negocio

## ⚠️ Reglas de Oro

> **Si es validación o lógica de negocio** → Va en el **UseCase**
>
> **Si es estado de UI o coordinación** → Va en el **Provider**
>
> **Si es acceso a datos** → Va en el **Repository**

---

**Última actualización:** 6 de octubre de 2025  
**Patrón:** Clean Architecture + ChangeNotifier  
**Framework:** Flutter + Provider

