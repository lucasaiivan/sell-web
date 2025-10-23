## Descripción
Mixins reutilizables que proporcionan funcionalidades compartidas entre diferentes clases.

## Contenido
```
mixins/
└── (vacío actualmente)
```
- **Separación de responsabilidades**: Aislar funcionalidades específicas en componentes modulares
- **Mantenibilidad**: Centralizar lógica común para facilitar actualizaciones

## 📂 Estructura y nomeclatura de ejemplo

```dart
lib/core/mixins/
├── responsive_mixin.dart       # Funcionalidades responsive
├── validation_mixin.dart       # Validaciones de formularios
├── theme_mixin.dart           # Utilidades de tema
├── loading_state_mixin.dart   # Estados de carga
└── mixins.dart               # Exportaciones centralizadas
```

## 🛠️ Uso Típico de ejempo

```dart
// Ejemplo de mixin para funcionalidad responsive
mixin ResponsiveMixin {
    bool isMobile(BuildContext context) {
        return MediaQuery.of(context).size.width < 600;
    }
    
    bool isTablet(BuildContext context) {
        return MediaQuery.of(context).size.width >= 600 &&
                     MediaQuery.of(context).size.width < 840;
    }
}

// Uso en un widget
class ProductCard extends StatelessWidget with ResponsiveMixin {
    @override
    Widget build(BuildContext context) {
        return isMobile(context) 
            ? MobileProductCard()
            : DesktopProductCard();
    }
}
```

## 🎨 Ventajas sobre Herencia

- **Flexibilidad**: Una clase puede usar múltiples mixins
- **Composición**: Permite combinar comportamientos específicos
- **Evita jerarquías complejas**: No requiere herencia profunda
- **Reutilización granular**: Usar solo las funcionalidades necesarias
