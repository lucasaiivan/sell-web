# Casos de Uso del Dominio

Este directorio contiene los casos de uso que implementan la lógica de negocio de la aplicación.

## Archivos

### `account_usecase.dart`
- **Propósito**: Gestión de cuentas de usuario y operaciones relacionadas
- **Contexto**: Manejo de perfiles de cuenta, validaciones y configuraciones
- **Uso**: Se utiliza en AuthProvider y páginas de configuración de cuenta

### `auth_usecases.dart`
- **Propósito**: Casos de uso para autenticación y gestión de sesiones
- **Contexto**: Login, logout, registro de usuarios con Firebase Auth
- **Uso**: Implementado en AuthProvider para flujos de autenticación

### `catalogue_usecases.dart`
- **Propósito**: Gestión del catálogo de productos
- **Contexto**: CRUD de productos, categorías, precios, inventario
- **Uso**: Utilizado por CatalogueProvider para operaciones del catálogo

### `cash_register_usecases.dart`
- **Propósito**: Sistema completo de caja registradora y transacciones
- **Contexto**: 
  - Apertura/cierre de cajas
  - Flujos de efectivo (ingresos/egresos)
  - **Historial de transacciones (SIEMPRE se guarda)**
  - Reportes y análisis de ventas
- **Uso**: Implementado en CashRegisterProvider
- **Características importantes**:
  - Las transacciones se registran independientemente de si hay caja activa
  - Validaciones automáticas de tickets
  - Asignación inteligente de información de caja

### `sell_usecases.dart`
- **Propósito**: Casos de uso para el proceso de ventas
- **Contexto**: Gestión de tickets, procesamiento de ventas, métodos de pago
- **Uso**: Utilizado por SellProvider para operaciones de venta

## Patrón de Implementación

Todos los casos de uso siguen el patrón:

```dart
class ExampleUsecases {
  final ExampleRepository _repository;

  ExampleUsecases(this._repository);

  // Métodos de negocio con validaciones
  Future<ResultType> performBusinessOperation() async {
    // 1. Validaciones de entrada
    // 2. Lógica de negocio
    // 3. Llamada al repositorio
    // 4. Retorno del resultado
  }
}
```

## Consideraciones Importantes

1. **Separación de responsabilidades**: Cada use case tiene una responsabilidad específica
2. **Validaciones centralizadas**: Todas las validaciones están en los use cases
3. **Independencia de la UI**: Los use cases no dependen de widgets o providers
4. **Testing**: Cada use case es fácilmente testeable de forma unitaria
5. **Transacciones**: Las ventas se registran SIEMPRE en el historial, con o sin caja activa
