# Uso del Registro de Precios de Productos

## Descripción
Se ha agregado la funcionalidad para registrar automáticamente el precio de un producto en la base de datos pública de Firebase cuando se agrega o actualiza un producto en el catálogo.

## Ruta de la Base de Datos
Los precios se registran en la siguiente ruta de Firebase:
```
/APP/ARG/PRODUCTOS/{codigo_producto}/PRICES/{id_cuenta}
```

Por ejemplo:
```
/APP/ARG/PRODUCTOS/0000077915481/PRICES/CW4T9tXSHLSM5hr4XNxLXhKufT12
```

## Cambios Realizados

### 1. Nueva Entidad ProductPrice
Ya existía la entidad `ProductPrice` en `/lib/domain/entities/catalogue.dart` con los siguientes campos:
- `id`: ID del registro
- `idAccount`: ID de la cuenta que registra el precio
- `imageAccount`: Imagen de perfil de la cuenta
- `nameAccount`: Nombre de la cuenta
- `price`: Precio del producto
- `time`: Timestamp de registro
- `currencySign`: Símbolo de la moneda
- `province`: Provincia
- `town`: Ciudad o pueblo

### 2. Nuevo Caso de Uso
Se agregó `RegisterProductPriceUseCase` en `/lib/domain/usecases/catalogue_usecases.dart`:
```dart
class RegisterProductPriceUseCase {
  final CatalogueRepository repository;
  RegisterProductPriceUseCase(this.repository);

  Future<void> call(ProductPrice productPrice, String productCode) {
    return repository.registerProductPrice(productPrice, productCode);
  }
}
```

### 3. Actualización del Repositorio
Se agregó el método `registerProductPrice` en:
- `/lib/domain/repositories/catalogue_repository.dart` (interfaz)
- `/lib/data/catalogue_repository_impl.dart` (implementación)

### 4. Actualización del Provider
Se modificó `CatalogueProvider` para incluir el nuevo caso de uso y se actualizó el método `addAndUpdateProductToCatalogue`.

## Uso del Método Actualizado

### Método Original (sin registro de precio)
```dart
await catalogueProvider.addAndUpdateProductToCatalogue(product, accountId);
```

### Método Actualizado (con registro de precio)
```dart
// Obtener el perfil de la cuenta actual
final accountProfile = authProvider.getProfileAccountById(accountId);

// Agregar producto y registrar precio automáticamente
await catalogueProvider.addAndUpdateProductToCatalogue(
  product, 
  accountId, 
  accountProfile: accountProfile
);
```

## Condiciones para el Registro de Precio

El precio se registra automáticamente cuando:
1. Se proporciona el parámetro `accountProfile`
2. El precio del producto (`product.salePrice`) es mayor a 0
3. El producto tiene un código válido

## Ejemplo Completo

```dart
// En tu widget o página
Future<void> addProductWithPrice() async {
  final catalogueProvider = Provider.of<CatalogueProvider>(context, listen: false);
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  // Crear el producto
  final product = ProductCatalogue(
    id: 'producto_123',
    code: '7794000012345',
    description: 'Producto de ejemplo',
    salePrice: 1500.0,
    // ... otros campos
  );
  
  // Obtener perfil de la cuenta
  final accountId = 'CW4T9tXSHLSM5hr4XNxLXhKufT12';
  final accountProfile = authProvider.getProfileAccountById(accountId);
  
  try {
    // Agregar producto al catálogo y registrar precio en base pública
    await catalogueProvider.addAndUpdateProductToCatalogue(
      product,
      accountId,
      accountProfile: accountProfile,
    );
    
    print('✅ Producto agregado y precio registrado exitosamente');
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

## Características Importantes

1. **Registro Opcional**: El registro de precio es opcional. Si no se proporciona `accountProfile`, el método funciona como antes.

2. **Manejo de Errores**: Si falla el registro del precio, no interrumpe el flujo principal de agregar el producto al catálogo.

3. **Validaciones**: Se valida que:
   - El código del producto no esté vacío
   - El ID de la cuenta no esté vacío
   - El precio sea mayor a 0

4. **Estructura de Datos**: El precio se registra con toda la información de la cuenta (nombre, imagen, ubicación, moneda).

## Beneficios

- **Transparencia de Precios**: Los precios quedan registrados públicamente por producto
- **Historial de Precios**: Se puede crear un historial de precios por cuenta
- **Comparación de Precios**: Permite comparar precios entre diferentes cuentas/negocios
- **Análisis de Mercado**: Facilita análisis de precios por región o ciudad
