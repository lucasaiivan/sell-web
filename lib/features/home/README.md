# Feature: Home

## Propósito
Dashboard principal y **navegación central** para usuarios autenticados. Coordina el acceso a Sales y Catalogue.

## Responsabilidades
- Navegación principal de la app
- Gestión del índice de página actual (Sales/Catalogue)
- Layout principal con drawer
- Orquestación de features

## Estructura

```
home/
└── presentation/
    ├── providers/
    │   └── home_provider.dart     # Navegación simple
    └── pages/
        └── home_page.dart         # Layout principal
```

## Provider Principal

### `HomeProvider`
**Responsabilidad:** Gestionar índice de página actual

```dart
@injectable
class HomeProvider extends ChangeNotifier {
  int _currentPageIndex = 0;
  
  void setPage(int index) {
    _currentPageIndex = index;
    notifyListeners();
  }
}
```

**Uso:**
```dart
final homeProvider = context.watch<HomeProvider>();
homeProvider.setPage(0); // Sales
homeProvider.setPage(1); // Catalogue
```

## Página Principal

### `HomePage`
**Layout principal** que coordina:
- AppDrawer (navegación lateral)
- SalesPage o CataloguePage según índice
- Gestión de diálogos de selección de cuenta

**Dependencias:**
```dart
- SalesProvider (features/sales)
- CatalogueProvider (features/catalogue)
- AuthProvider (features/auth)
- HomeProvider (local)
```

## Navegación

**Entrada:** Login exitoso (AuthProvider) → HomePage
**Salidas:**
- Índice 0 → SalesPage
- Índice 1 → CataloguePage

## Diálogos Gestionados

Muestra `WelcomeSelectedAccountPage` cuando:
- Usuario no tiene cuenta seleccionada
- Primera vez después del login

## Arquitectura

**Nota:** Este feature es principalmente **orquestación**
- ❌ No tiene domain/data (no hay lógica de negocio propia)
- ✅ Simple provider de navegación
- ✅ Layout container para otros features

## Relación con otros Features

```
HomePage (coordinator)
    ├─→ SalesPage (features/sales)
    └─→ CataloguePage (features/catalogue)
```

## Por qué es un Feature Separado

Aunque simple, merece su propio feature porque:
1. **Responsabilidad clara** - Navegación principal
2. **Punto de entrada** - Después de autenticación
3. **Escalabilidad** - Puede crecer con más páginas (dashboard, reports, etc.)
4. **Separación de concerns** - No mezcla lógica de navegación con sales/catalogue
