# Core Mixins


Los **Mixins** son una característica poderosa de Dart que permite compartir código entre múltiples clases sin usar herencia tradicional. En esta carpeta se almacenan mixins reutilizables que proporcionan funcionalidades específicas que pueden ser "mezcladas" en diferentes widgets y clases.

## 🎯 Propósito

Los mixins en este proyecto permiten:
- **Reutilización de código**: Compartir lógica común entre múltiples clases
- **Composición**: Combinar múltiples comportamientos sin herencia compleja
- **Separación de responsabilidades**: Aislar funcionalidades específicas en componentes modulares
- **Mantenibilidad**: Centralizar lógica común para facilitar actualizaciones

## 📂 Estructura

```dart
lib/core/mixins/
├── responsive_mixin.dart       # Funcionalidades responsive
├── validation_mixin.dart       # Validaciones de formularios
├── theme_mixin.dart           # Utilidades de tema
├── loading_state_mixin.dart   # Estados de carga
└── mixins.dart               # Exportaciones centralizadas
```

## 🛠️ Uso Típico

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
