# Catalogue Dialogs

## 📋 Propósito
Diálogos relacionados con la gestión del catálogo de productos.

## 📁 Archivos

### `add_product_dialog.dart`
- **Contexto**: Diálogo para agregar productos al catálogo
- **Propósito**: Permite crear nuevos productos con información completa
- **Uso**: Se abre desde la página de catálogo para añadir productos

### `add_product_dialog_new.dart`
- **Contexto**: Versión actualizada del diálogo de agregar producto
- **Propósito**: Implementación mejorada con Material Design 3
- **Uso**: Reemplazo moderno del diálogo original

### `product_edit_dialog.dart`
- **Contexto**: Diálogo para editar productos existentes
- **Propósito**: Permite modificar información de productos del catálogo
- **Uso**: Se abre al seleccionar "Editar" en un producto del catálogo

### `product_edit_dialog_new.dart`
- **Contexto**: Versión actualizada del diálogo de edición
- **Propósito**: Implementación mejorada con Material Design 3
- **Uso**: Reemplazo moderno del diálogo de edición original

### `product_not_found_dialog.dart`
- **Contexto**: Diálogo cuando no se encuentra un producto
- **Propósito**: Informa al usuario que el producto buscado no existe
- **Uso**: Se muestra al buscar productos inexistentes en el catálogo

### `create_product_dialog.dart`
- **Contexto**: Diálogo para crear productos nuevos desde código de barras
- **Propósito**: Permite crear productos rápidamente con precio y descripción obligatorios
- **Uso**: Se abre desde el diálogo de "producto no encontrado" para crear productos nuevos

## 🔧 Uso
```dart
// Agregar producto
showDialog(
  context: context,
  builder: (context) => AddProductDialog(product: newProduct),
);

// Editar producto
showDialog(
  context: context,
  builder: (context) => ProductEditDialog(product: existingProduct),
);

// Producto no encontrado
showDialog(
  context: context,
  builder: (context) => ProductNotFoundDialog(searchTerm: searchText),
);

// Crear producto nuevo
showCreateProductDialog(
  context,
  code: scannedCode,
  onCreateProduct: (description, price) async {
    // Lógica para crear el producto
  },
);
```
