# Implementación de Incremento de Ventas en Productos del Catálogo

## 📋 Descripción

Esta implementación agrega la funcionalidad para incrementar automáticamente el contador de ventas (`sales`) de los productos en el catálogo cuando se confirma una venta. Esta funcionalidad está basada en el repositorio de referencia [sell.git](https://github.com/lucasaiivan/sell.git) y sigue las mejores prácticas de arquitectura limpia.

## 🚀 Funcionalidades Implementadas

### 1. **Incremento Automático de Ventas**
- ✅ Se incrementa el contador `sales` de cada producto vendido
- ✅ La cantidad vendida se suma al contador total
- ✅ Actualización del timestamp de modificación del producto

### 2. **Decremento de Stock (Preparado)**
- ✅ Funcionalidad lista para decrementar stock cuando está habilitado
- ✅ Solo aplica a productos con control de stock activo
- ✅ Validación de stock disponible

### 3. **Manejo de Errores Robusto**
- ✅ Continuación del proceso de venta aunque falle la actualización
- ✅ Logs detallados para seguimiento
- ✅ Notificaciones al usuario sobre problemas menores

## 🏗️ Arquitectura

### **Capas Implementadas**

#### **1. Domain Layer**
```dart
// Repositorio abstracto
abstract class CatalogueRepository {
  Future<void> incrementSales(String accountId, String productId, int quantity);
  Future<void> decrementStock(String accountId, String productId, int quantity);
}

// Casos de uso
class IncrementProductSalesUseCase {
  Future<void> call(String accountId, String productId, {int quantity = 1});
}

class DecrementProductStockUseCase {
  Future<void> call(String accountId, String productId, int quantity);
}
```

#### **2. Data Layer**
```dart
// Implementación del repositorio
class CatalogueRepositoryImpl implements CatalogueRepository {
  @override
  Future<void> incrementSales(String accountId, String productId, int quantity) async {
    await FirebaseFirestore.instance
        .collection('/ACCOUNTS/$accountId/CATALOGUE')
        .doc(productId)
        .update({
          'sales': FieldValue.increment(quantity),
          'upgrade': Timestamp.now(),
        });
  }
}
```

#### **3. Presentation Layer**
```dart
// Provider con métodos públicos
class CatalogueProvider extends ChangeNotifier {
  Future<void> incrementProductSales(String accountId, String productId, {int quantity = 1});
  Future<void> decrementProductStock(String accountId, String productId, int quantity);
}
```

## 📁 Archivos Modificados

### **1. Capa de Dominio**
- **`lib/domain/repositories/catalogue_repository.dart`**
  - ➕ Agregado método `incrementSales()`
  - ➕ Agregado método `decrementStock()`

- **`lib/domain/usecases/catalogue_usecases.dart`**
  - ➕ Agregado `IncrementProductSalesUseCase`
  - ➕ Agregado `DecrementProductStockUseCase`

### **2. Capa de Datos**
- **`lib/data/catalogue_repository_impl.dart`**
  - ➕ Implementado `incrementSales()` con Firebase
  - ➕ Implementado `decrementStock()` con Firebase
  - ✅ Validaciones de parámetros
  - ✅ Manejo de errores

### **3. Capa de Presentación**
- **`lib/presentation/providers/catalogue_provider.dart`**
  - ➕ Agregado `incrementProductSales()`
  - ➕ Agregado `decrementProductStock()`
  - ✅ Logs de depuración
  - ✅ Validaciones

- **`lib/presentation/pages/sell_page.dart`**
  - ➕ Agregado método `_updateProductSalesAndStock()`
  - ✅ Integración en flujo de confirmación de venta
  - ✅ Manejo de errores sin interrumpir venta
  - ✅ Notificaciones al usuario

## 🔄 Flujo de Ejecución

### **Cuando se Confirma una Venta:**

1. **Registro de Transacción** 📊
   - Se guarda el ticket en el historial
   - Se actualiza la caja registradora (si existe)

2. **Actualización de Productos** 🔄
   ```dart
   await _updateProductSalesAndStock(provider);
   ```

3. **Por Cada Producto del Ticket:** 
   - ✅ Se valida que tenga código válido
   - ✅ Se incrementa el contador `sales`
   - ✅ Se decrementa stock (si aplica)
   - ✅ Se actualiza timestamp de modificación

4. **Finalización** ✨
   - Se limpia el ticket
   - Se notifica al usuario

## 🛡️ Validaciones y Seguridad

### **Validaciones Implementadas:**
- ✅ AccountId y ProductId no vacíos
- ✅ Cantidad mayor a 0
- ✅ Producto con código válido
- ✅ Stock disponible (para decremento)

### **Manejo de Errores:**
- 🔧 **Por Producto**: Si falla un producto, continúa con los demás
- 🔧 **General**: Si falla la actualización completa, no interrumpe la venta
- 🔧 **Usuario**: Notificación discreta sobre problemas menores

## 💾 Estructura de Datos en Firebase

### **Campos Actualizados en el Catálogo:**
```json
{
  "id": "product_123",
  "description": "Producto de ejemplo",
  "code": "7890123456789",
  "sales": 15,           // ← Se incrementa automáticamente
  "quantityStock": 85,   // ← Se decrementa si aplica
  "upgrade": "timestamp" // ← Se actualiza siempre
}
```

## 🚀 Próximas Mejoras

### **Funcionalidades Futuras:**
- 📈 **Analytics**: Reportes de productos más vendidos
- 📦 **Stock Avanzado**: Alertas de stock bajo
- 🔄 **Sincronización**: Actualización en tiempo real en múltiples dispositivos
- 📊 **Dashboards**: Gráficos de ventas por producto

### **Optimizaciones:**
- ⚡ **Batch Updates**: Actualización masiva en una sola operación
- 🔄 **Retry Logic**: Reintento automático en caso de fallo
- 📱 **Offline Support**: Actualización cuando se recupere conexión

## 🧪 Testing

### **Para Probar la Funcionalidad:**

1. **Agregar un producto al catálogo** con código de barras
2. **Crear una venta** con ese producto
3. **Confirmar la venta** 
4. **Verificar en Firebase** que el campo `sales` se incrementó
5. **Revisar logs** en la consola de desarrollo

### **Logs de Ejemplo:**
```
✅ Ventas incrementadas: Producto abc123, Cantidad: 2
✅ Stock decrementado: Producto abc123, Cantidad: 2
✅ Actualizado producto: Coca Cola 1L (Ventas: +2, Stock: -2)
🎉 Actualización de ventas y stock completada para 3 productos
```

## 📞 Soporte

Si encuentras algún problema o necesitas modificaciones adicionales, revisa:

1. **Logs de la consola** para errores específicos
2. **Firebase Console** para verificar las actualizaciones
3. **Flutter Analyze** para problemas de código

---

**📝 Nota**: Esta implementación está diseñada para ser robusta y no interrumpir el flujo de ventas, incluso si ocurren errores en la actualización de estadísticas.
