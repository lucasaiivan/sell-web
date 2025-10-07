# Providers (Presentation Layer)

## Descripción
Proveedores de estado usando `ChangeNotifier` que gestionan la interfaz de usuario y coordinan llamadas a los casos de uso del dominio.

## 🎯 Responsabilidades

### ✅ **Lo que DEBE hacer un Provider:**
- Gestionar estado de la UI (loading, error, success)
- Manejar controllers de formularios
- Coordinar llamadas a UseCases
- Mostrar mensajes de error al usuario
- Navegar entre pantallas
- Actualizar la UI cuando cambia el estado
- Escuchar streams de datos

### ❌ **Lo que NO debe hacer un Provider:**
- Implementar validaciones de negocio
- Transformar datos según reglas de negocio
- Acceder directamente a Firebase o bases de datos
- Contener lógica de negocio compleja
- Generar IDs únicos (delegar al UseCase)
- Calcular totales o aplicar reglas (delegar al UseCase)

## 📁 Contenido

```
providers/
├── auth_provider.dart                 # Autenticación y usuario actual
├── cash_register_provider.dart        # Caja registradora ⭐ Refactorizado
├── catalogue_provider.dart            # Catálogo de productos
├── printer_provider.dart              # Configuración de impresora
├── sell_provider.dart                 # Proceso de venta ⭐ Actualizado
└── theme_data_app_provider.dart       # Tema de la aplicación
```

## ⭐ CashRegisterProvider (Refactorizado)

### **Estructura del Estado Inmutable:**

```dart
class _CashRegisterState {
  final List<CashRegister> activeCashRegisters;
  final CashRegister? selectedCashRegister;
  final bool isLoadingActive;
  final bool isProcessing;
  final String? errorMessage;
  // ... más propiedades
}
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

