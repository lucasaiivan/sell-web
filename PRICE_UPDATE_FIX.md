# Corrección de Actualización de Precios en Lista de Productos Seleccionados

## Problema Identificado
Cuando se actualizaban los precios de un producto desde el diálogo `ProductPriceEditDialog`, los cambios no se reflejaban correctamente en la lista de productos seleccionados del ticket. Esto ocurría por dos problemas principales:

### 1. Parámetro `replaceQuantity` No Especificado
En el método `_saveChanges()` del diálogo, se llamaba a:
```dart
sellProvider.addProductsticket(updatedProduct); // ❌ Sin replaceQuantity
```

Esto hacía que solo se actualizara la cantidad, no el producto completo.

### 2. Lógica Incorrecta en `addProductsticket()`
El método solo actualizaba la cantidad cuando `replaceQuantity = true`, pero no reemplazaba el producto completo con los nuevos precios:

```dart
// ❌ Código anterior - Solo actualizaba cantidad
if (replaceQuantity) {
  updatedProducts[i].quantity = product.quantity;
}
```

## Solución Implementada

### 1. Corrección en ProductPriceEditDialog
**Archivo**: `/lib/core/widgets/dialogs/catalogue/product_price_edit_dialog.dart`

- **Línea 267**: Agregado `replaceQuantity: true`
- **Líneas 249-253**: Preservación de la cantidad actual del ticket al crear el producto actualizado

```dart
// ✅ Obtener cantidad actual del ticket
final currentQuantity = sellProvider.ticket.products
    .firstWhere((p) => p.id == widget.product.id, orElse: () => widget.product)
    .quantity;

// ✅ Crear producto con cantidad preservada
final updatedProduct = widget.product.copyWith(
  salePrice: _newSalePrice,
  purchasePrice: _newPurchasePrice,
  quantity: currentQuantity, // Preservar cantidad del ticket
  upgrade: Utils().getTimestampNow(),
  documentIdUpgrade: accountId,
);

// ✅ Actualizar con reemplazo completo
sellProvider.addProductsticket(updatedProduct, replaceQuantity: true);
```

### 2. Mejora en SellProvider
**Archivo**: `/lib/presentation/providers/sell_provider.dart`

**Líneas 254-260**: Modificación del método `addProductsticket()` para reemplazar el producto completo cuando `replaceQuantity = true`:

```dart
// ✅ Código corregido - Reemplaza producto completo
if (replaceQuantity) {
  // Reemplazar el producto completo pero preservar la cantidad original si el producto nuevo tiene cantidad 0
  final quantityToUse = product.quantity > 0 ? product.quantity : updatedProducts[i].quantity;
  updatedProducts[i] = product.copyWith(quantity: quantityToUse);
} else {
  updatedProducts[i].quantity +=
      (product.quantity > 0 ? product.quantity : 1);
}
```

## Resultado

Ahora cuando se actualizan los precios de un producto:

1. ✅ **Los nuevos precios se reflejan inmediatamente** en la lista de productos seleccionados
2. ✅ **Se preserva la cantidad original** del producto en el ticket
3. ✅ **Se actualiza el catálogo** en la base de datos
4. ✅ **Se registra el precio público** usando `RegisterProductPriceUseCase`
5. ✅ **Se mantiene la consistencia** entre el catálogo y el ticket actual

## Flujo Completo de Actualización

1. Usuario edita precios en `ProductPriceEditDialog`
2. Se crea `updatedProduct` con nueva información de precios y cantidad preservada del ticket
3. Se actualiza el catálogo en Firestore usando `CatalogueProvider`
4. Se registra el precio en la base de datos pública
5. Se reemplaza el producto completo en el ticket usando `addProductsticket(replaceQuantity: true)`
6. La UI se actualiza automáticamente reflejando los nuevos precios

La corrección asegura que tanto el catálogo como la lista de productos seleccionados se mantengan sincronizados con los precios actualizados.
