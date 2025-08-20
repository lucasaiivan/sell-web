# Views

Esta carpeta contiene widgets de vista completa y pantallas especializadas que son reutilizables en diferentes contextos.

## 📁 Contenido

### 📱 Widgets de Vista
- `search_catalogue_full_screen_view.dart` - Vista completa del catálogo de productos

## 🎯 Propósito

Los widgets de vista proporcionan:

- **Pantallas completas**: Vistas que ocupan toda la pantalla
- **Funcionalidad específica**: Lógica de UI encapsulada
- **Reutilización**: Pueden usarse en múltiples contextos
- **Responsive**: Adaptables a diferentes tamaños de pantalla

## 🔧 Uso

### Importación
```dart
import 'package:sell_web/core/widgets/views/search_catalogue_full_screen_view.dart';
```

### Ejemplo de Uso
```dart
ProductCatalogueFullScreenView(
  products: productList,
  onProductSelected: (product) => _handleProductSelection(product),
  searchEnabled: true,
  filterEnabled: true,
)
```

## 📝 Consideraciones

- Las vistas deben ser autocontenidas
- Incluir loading states y error handling
- Optimizar para performance en listas grandes
- Mantener consistencia con el design system
- Soporte para keyboard navigation y accessibility
