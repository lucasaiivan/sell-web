# Views - Vistas Especializadas

Vistas y páginas completas que implementan funcionalidades específicas siguiendo Material Design 3 y Clean Architecture.

## 📁 Archivos

### `views.dart`
- **Propósito**: Exportaciones centralizadas de todas las vistas
- **Uso**: Importar este archivo para acceder a todas las vistas sin múltiples imports

### `search_catalogue_full_screen_view.dart`
- **Propósito**: Vista de pantalla completa para búsqueda y selección de productos
- **Características**:
  - NestedScrollView optimizado con SliverAppBar
  - Algoritmo de búsqueda inteligente en tiempo real
  - Integración con SellProvider para agregar productos al ticket
  - Manejo eficiente de listas grandes (max 50 resultados)

**Uso**:
```dart
Navigator.push(context, MaterialPageRoute(
  builder: (context) => ProductCatalogueFullScreenView(
    products: catalogueProvider.products,
    sellProvider: sellProvider,
  ),
));
```

### `welcome_selected_account_page.dart`
- **Propósito**: Página de selección de cuenta después del login
- **Características**:
  - Tarjetas de cuenta con avatares y ubicación
  - Soporte para modo demo y usuarios anónimos
  - Toggle de tema integrado
  - Gestión de estados de carga

**Uso**:
```dart
WelcomeSelectedAccountPage(
  onSelectAccount: (account) async {
    await sellProvider.initAccount(account);
  },
)
```

## 🔧 Dependencias

### Providers
- `AuthProvider` - Autenticación
- `CatalogueProvider` - Gestión de productos
- `SellProvider` - Ventas y tickets
- `ThemeDataAppProvider` - Temas

### Services
- `CatalogueSearchService` - Búsqueda avanzada
- `ThemeService` - Persistencia de temas

## 📱 Características Técnicas

- **Material Design 3** con ColorScheme dinámico
- **Provider pattern** para gestión de estado reactiva
- **Responsive design** adaptativo
- **Performance optimizado** con lazy loading y debouncing
- **Error handling** con fallbacks automáticos
