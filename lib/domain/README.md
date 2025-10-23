# Domain Layer

## Descripción
Capa de dominio que contiene la lógica de negocio pura, entidades, repositorios abstractos y casos de uso. Esta es la capa central de Clean Architecture donde reside toda la lógica de negocio.

## 🎯 Responsabilidades

### ✅ **Lo que DEBE hacer esta capa:**
- Definir entidades y modelos de negocio
- Implementar casos de uso (UseCases)
- Contener toda la lógica de negocio
- Realizar validaciones de datos
- Transformar datos según reglas de negocio
- Definir contratos de repositorios (interfaces)
- Ser independiente de frameworks y librerías externas

### ❌ **Lo que NO debe hacer esta capa:**
- Acceder directamente a bases de datos
- Importar Flutter (excepto `foundation`)
- Manejar estado de UI
- Conocer detalles de implementación de datos
- Realizar navegación o mostrar diálogos

## 📁 Contenido

```
domain/
├── entities/              # Modelos de dominio y entidades de negocio
│   ├── cash_register_model.dart
│   ├── catalogue.dart
│   ├── ticket_model.dart
│   └── user.dart
│
├── repositories/          # Interfaces abstractas de repositorios
│   ├── account_repository.dart
│   ├── auth_repository.dart
│   ├── cash_register_repository.dart
│   └── catalogue_repository.dart
│
└── usecases/             # Casos de uso con lógica de negocio
    ├── account_usecase.dart
    ├── auth_usecases.dart
    ├── cash_register_usecases.dart  # ⭐ Refactorizado (ver abajo)
    ├── catalogue_usecases.dart
    └── sell_usecases.dart
```

## ⭐ CashRegisterUsecases (Refactorizado)

### **Nuevos Métodos de Validación y Transformación:**

```dart
/// Prepara un ticket para transacción (validaciones + transformaciones)
TicketModel prepareTicketForTransaction(TicketModel ticket)

/// Procesa anulación de ticket (lógica de negocio completa)
Future<TicketModel> processTicketAnnullment({...})

/// Valida movimientos de caja
void validateCashMovement({...})

/// Valida y prepara datos de apertura
Map<String, dynamic> validateAndPrepareOpeningData({...})

/// Valida datos de cierre
void validateClosingData({...})
```

### **Métodos Existentes Mejorados:**

```dart
/// Apertura de caja con validaciones completas
Future<CashRegister> openCashRegister({...})

/// Cierre de caja con validaciones completas
Future<CashRegister> closeCashRegister({...})

/// Ingresos de caja con validaciones
Future<void> addCashInflow({...})

/// Egresos de caja con validaciones
Future<void> addCashOutflow({...})
```

## 🎯 Patrón de Validación

Todos los UseCases siguen este patrón:

```dart
Future<ReturnType> metodoCasoDeUso({...}) async {
  // 1. VALIDACIONES DE NEGOCIO
  if (campo.isEmpty) {
    throw Exception('El campo es obligatorio');
  }
  
  // 2. TRANSFORMACIONES DE DATOS
  final datoTransformado = transformar(dato);
  
  // 3. APLICAR REGLAS DE NEGOCIO
  final resultado = aplicarReglas(datoTransformado);
  
  // 4. DELEGAR AL REPOSITORY
  return await _repository.metodo(resultado);
}
```

## 📚 Ejemplos de Uso

### **Desde un Provider (Presentation Layer):**

```dart
class CashRegisterProvider extends ChangeNotifier {
  final CashRegisterUsecases _usecases;
  
  Future<bool> openCashRegister(...) async {
    try {
      // UseCase maneja TODAS las validaciones
      final newCashRegister = await _usecases.openCashRegister(
        accountId: accountId,
        description: descriptionController.text,
        initialCash: amountController.doubleValue,
        cashierId: cashierId,
      );
      
      // Solo actualizar UI
      _updateState(newCashRegister);
      return true;
    } catch (e) {
      // Mostrar error en UI
      _showError(e.toString());
      return false;
    }
  }
}
```

## 🔑 Principios Clave

### **1. Dependency Inversion**
```
Provider → depende de → UseCase
UseCase → depende de → Repository (interface)
Repository → implementado en → Data Layer
```

### **2. Single Responsibility**
Cada UseCase tiene una responsabilidad específica y bien definida.

### **3. Separation of Concerns**
- **Entities:** Modelos puros sin lógica
- **Repositories:** Contratos (interfaces)
- **UseCases:** Lógica de negocio

## 📖 Referencias

- Ver `REFACTORING_CLEAN_ARCHITECTURE.md` para detalles de la refactorización
- Ver `presentation/providers/README.md` para uso desde la UI
- Ver `data/README.md` para implementación de repositorios

---

**Última actualización:** 6 de octubre de 2025  
**Patrón:** Clean Architecture  
**Principio:** Domain-Driven Design

