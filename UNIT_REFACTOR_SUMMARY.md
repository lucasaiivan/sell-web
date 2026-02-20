
# 📏 Refactorización del Sistema de Unidades

Se ha completado la refactorización para estandarizar el manejo de unidades de medida en toda la aplicación.

## 📋 Resumen de Cambios

1.  **Definición Centralizada (`UnitConstants`)**
    *   Ubicación: `lib/core/constants/unit_constants.dart`
    *   Se definieron constantes para los IDs en inglés (Base de Datos): `unit`, `kilogram`, `liter`, `meter`, `box`, `package`.
    *   Se implementaron mapas de traducción y símbolos para la UI.
    *   Se agregó lógica de mapeo "Legacy" para soportar datos antiguos (ej: 'gramo' -> 'kilogram').

2.  **Lógica de Negocio (`ProductCatalogue`)**
    *   Los productos ahora normalizan la unidad al crearse/cargarse desde la DB.
    *   Getters como `unitSymbol`, `formattedQuantity` y `formattedQuantityCompact` ahora usan `UnitConstants` para decidir cómo mostrar la información (ej: mostrar 'g' si es 'kilogram' < 1 kg).

3.  **Utilidades (`UnitHelper`)**
    *   Reescrito para usar `UnitConstants` como fuente de verdad.
    *   Métodos como `validateQuantity`, `formatQuantity`, y `convertToDisplayUnit` actualizados para trabajar con los nuevos IDs.
    *   Soporte robusto para visualización de sub-unidades (gramos, mililitros) en la interfaz sin guardar esos IDs en la base de datos.

4.  **Interfaz de Usuario Update**
    *   **Edición de Producto (`ProductEditCatalogueView`)**: Selector de unidades actualizado para usar las nuevas constantes.
    *   **Venta Rápida (`QuickSaleDialog`)**: Selector y validación de cantidad actualizados.
    *   **Provider de Ventas (`SalesProvider`)**: Valor por defecto para productos rápidos actualizado a `UnitConstants.unit`.

## 🛠️ Cómo Usar

### Obtener Nombre para Mostrar
```dart
// Antes (Hardcoded)
text: 'Kilogramo'

// Ahora
text: UnitHelper.getUnitDisplayName(product.unit) // "Kilogramo"
```

### Obtener Símbolo
```dart
// Antes
text: 'kg'

// Ahora
text: UnitHelper.getUnitSymbol(product.unit) // "kg"
```

### Validar Cantidad
```dart
String? error = UnitHelper.validateQuantity(quantity, product.unit);
```

### Crear Nuevo Producto
```dart
// La unidad debe ser un ID en inglés de UnitConstants
final product = ProductCatalogue(
  // ...
  unit: UnitConstants.kilogram, // 'kilogram'
);
```
