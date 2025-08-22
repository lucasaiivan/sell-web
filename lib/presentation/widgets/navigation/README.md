# Navigation

Esta carpeta contiene widgets relacionados con la navegación de la aplicación.

## 📁 Contenido

### 🧭 Widgets de Navegación
- Widgets de drawer y navegación lateral
- Componentes de navegación reutilizables
- Barras de navegación personalizadas

## 🎯 Propósito

Los widgets de navegación proporcionan:

- **Navegación lateral**: Drawers y side panels
- **Navegación inferior**: Bottom navigation bars
- **Breadcrumbs**: Navegación jerárquica
- **Tabs**: Navegación por pestañas
- **Consistencia**: Patrones de navegación uniformes

## 🔧 Uso

### Importación
```dart
import 'package:sell_web/core/widgets/navigation/navigation.dart';
```

### Ejemplo de Uso
```dart
AppDrawer(
  currentRoute: '/products',
  onNavigate: (route) => _navigate(route),
  userInfo: currentUser,
)
```

## 📝 Consideraciones

- Mantener consistencia en patrones de navegación
- Soporte para keyboard navigation
- Accessibility compliance
- State management para navegación
- Deep linking support
- Responsive behavior
