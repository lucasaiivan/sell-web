# Feature: Catalogue

## Propósito
Gestión completa del **catálogo de productos** - CRUD, búsqueda, categorización, y edición de stock.

## Responsabilidades
- Crear, leer, actualizar, eliminar productos
- Búsqueda y filtrado de productos
- Gestión de categorías y marcas
- Control de stock e inventario
- Precios y descuentos
- Productos favoritos

## Estructura

```
catalogue/
├── domain/
│   ├── entities/
│   │   ├── product_catalogue.dart
│   │   ├── category.dart
│   │   └── mark.dart
│   ├── repositories/
│   │   └── catalogue_repository.dart
│   └── usecases/
│       ├── get_products_usecase.dart
│       ├── add_product_usecase.dart
│       ├── update_product_usecase.dart
│       ├── delete_product_usecase.dart
│       ├── search_products_usecase.dart
│       └── manage_categories_usecase.dart
├── data/
│   ├── models/
│   │   └── product_catalogue_model.dart
│   ├── datasources/
│   │   └── catalogue_firebase_datasource.dart
│   └── repositories/
│       └── catalogue_repository_impl.dart
└── presentation/
    ├── providers/
    │   └── catalogue_provider.dart
    ├── pages/
    │   └── catalogue_page.dart
    ├── widgets/
    │   ├── product_catalogue_view.dart
    │   ├── product_edit_catalogue_view.dart
    │   └── product_card.dart
    ├── dialogs/
    │   ├── add_product_dialog.dart
    │   ├── product_edit_dialog.dart
    │   ├── product_not_found_dialog.dart
    │   └── product_price_edit_dialog.dart
    └── views/
        └── search_catalogue_full_screen_view.dart
```

## Provider Principal

### `CatalogueProvider`
**Responsabilidad:** Estado y operaciones del catálogo

**Inyección de Dependencias:**
```dart
@injectable
class CatalogueProvider extends ChangeNotifier {
  final GetProductsUseCase _getProductsUseCase;
  final AddProductUseCase _addProductUseCase;
  final UpdateProductUseCase _updateProductUseCase;
  final DeleteProductUseCase _deleteProductUseCase;
  final SearchProductsUseCase _searchProductsUseCase;
  // ...
}
```

**Estado Gestionado:**
- Lista de productos
- Productos favoritos
- Categorías y marcas
- Filtros activos
- Estado de carga

## Entities (Domain)

### `ProductCatalogue` (Inmutable)
```dart
class ProductCatalogue {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final Category category;
  final Mark? mark;
  final bool favorite;
  final String? imageUrl;
  // ...
}
```

### `Category` & `Mark`
Entidades para categorización de productos

## Use Cases Principales

1. **GetProductsUseCase** - Obtener lista de productos
2. **AddProductUseCase** - Agregar nuevo producto
3. **UpdateProductUseCase** - Actualizar producto existente
4. **DeleteProductUseCase** - Eliminar producto
5. **SearchProductsUseCase** - Búsqueda con filtros

## Páginas y Vistas

### `CataloguePage`
Vista principal con grid de productos

### Widgets Específicos
- **ProductCatalogueView** - Tarjeta de producto
- **ProductEditCatalogueView** - Formulario de edición completo

### Diálogos
- **AddProductDialog** - Agregar producto rápido
- **ProductEditDialog** - Edición detallada
- **ProductNotFoundDialog** - Cuando producto no existe
- **ProductPriceEditDialog** - Edición de precio específica

## Dependencias

### Externas
- Cloud Firestore (persistencia)
- Firebase Storage (imágenes)

### Internas
- `core/presentation/widgets/` - Componentes compartidos
- `features/sales` - Uso de productos en tickets

## Integración con Sales

```dart
// Sales consume productos del catálogo
final product = catalogueProvider.getProductById(id);
salesProvider.addProductToTicket(product);
```

## Clean Architecture

✅ **Domain Layer** - Entities inmutables, contratos puros
✅ **Data Layer** - Firebase implementation
✅ **Presentation** - Provider pattern con use cases
✅ **Dependency Injection** - Injectable

## Características Especiales

- **Real-time updates** - Stream de Firestore
- **Búsqueda optimizada** - Índices y filtros
- **Favoritos** - Marcado rápido de productos
- **Gestión de stock** - Control de inventario
- **Imágenes** - Upload y gestión de fotos de productos
