# Feature: Landing

## Propósito
Página de **presentación y marketing** para usuarios no autenticados. Showcases del producto, features, y enlace al login.

## Responsabilidades
- Presentación visual del producto
- Marketing y branding
- Información de features
- Llamado a la acción (CTA) para login
- Toggle de theme (claro/oscuro)

## Estructura

```
landing/
└── presentation/
    └── pages/
        └── landing_page.dart  # AppPresentationPage (2700+ líneas)
```

## Características

- **Diseño Responsive** - Mobile, tablet, desktop
- **Animaciones** - Flutter Animate para transiciones suaves
- **Lazy Loading** - Optimización de performance
- **Theme Switching** - Modo claro/oscuro

## Dependencias

### Externas
- `flutter_animate` - Animaciones declarativas
- `url_launcher` - Enlaces externos

### Internas
- `features/auth` - LoginPage (navegación)
- `core/services/theme/` - ThemeDataAppProvider
- `core/presentation/widgets/buttons/` - Botones compartidos
- `core/utils/helpers/` - ResponsiveHelper

## Componentes Principales

### `AppPresentationPage`
Landing page completa con:
- Hero section con animaciones
- Feature highlights
- Pricing/plans (si aplica)
- Footer con links
- Botón de "Iniciar sesión"

## Navegación

**Entrada:** App inicio (unauthenticated)
**Salida:** Click "Login" → LoginPage (feature auth)

## Notas de Implementación

- **Sin Domain/Data layers** - Solo presentación (no hay lógica de negocio)
- **Stateful Widget** - Maneja scroll y animaciones
- **Performance optimizada** - Const constructors, cached widgets

## Relación con Auth

Landing **no pertenece** a Auth porque:
- Dominio diferente (marketing vs seguridad)
- Responsabilidad única
- Landing puede crecer con más páginas de marketing
- Auth se enfoca solo en autenticación

## Futuras Expansiones

Potenciales páginas adicionales en este feature:
- `/about` - Sobre nosotros
- `/pricing` - Planes y precios
- `/features` - Detalles de características
- `/contact` - Contacto
