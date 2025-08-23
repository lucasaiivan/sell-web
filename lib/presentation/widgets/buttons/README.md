## Descripción
Componentes de botones reutilizables para diferentes acciones y contextos de la aplicación.

## Contenido
```
buttons/
├── buttons.dart - Archivo de barril que exporta todos los botones
├── app_bar_button.dart - Botón para barra de aplicación
├── app_button.dart - Botón principal de la aplicación
├── app_floating_action_button.dart - Botón de acción flotante personalizado
├── app_text_button.dart - Botón de texto
├── search_button.dart - Botón de búsqueda
└── theme_control_buttons.dart - Botones de control de tema
```
  buttonColor: Colors.blue,     // Color personalizado
  mainAxisSize: MainAxisSize.min, // Tamaño del contenedor
)
```

### `ThemeColorButton`
Botón individual para seleccionar el color semilla del tema.

```dart
ThemeColorButton(
  iconColor: Colors.blue,
  iconSize: 24,
  tooltip: 'Cambiar color del tema',
)
```

### `ThemeBrightnessButton`
Botón individual para cambiar entre tema claro y oscuro.

```dart
ThemeBrightnessButton(
  themeProvider: themeProvider,
  iconColor: Colors.blue,
  iconSize: 24,
  tooltip: 'Cambiar brillo',
)
```

### `ThemeColorOnlyButton`
Widget que solo muestra el botón de color (atajo para `ThemeControlButtons` con `showBrightnessButton: false`).

```dart
ThemeColorOnlyButton(
  iconSize: 24,
  buttonColor: Colors.blue,
  tooltip: 'Cambiar color del tema',
)
```

### `ThemeBrightnessOnlyButton`
Widget que solo muestra el botón de brillo (atajo para `ThemeControlButtons` con `showColorButton: false`).

```dart
ThemeBrightnessOnlyButton(
  iconSize: 24,
  buttonColor: Colors.blue,
  tooltip: 'Cambiar brillo',
)
```

## 🎨 Ejemplos de Uso

### Uso Básico (ambos botones)
```dart
// En cualquier parte de la aplicación
Positioned(
  top: 20,
  right: 20,
  child: ThemeControlButtons(),
)
```

### Solo Color
```dart
// Cuando solo necesitas cambio de color
AppBar(
  actions: [
    ThemeColorOnlyButton(),
  ],
)
```

### Solo Brillo
```dart
// Cuando solo necesitas cambio de brillo
Row(
  children: [
    Text('Tema:'),
    ThemeBrightnessOnlyButton(),
  ],
)
```

### Personalizado
```dart
// Con configuración personalizada
ThemeControlButtons(
  spacing: 12,
  iconSize: 28,
  buttonColor: Theme.of(context).colorScheme.secondary,
  showColorButton: true,
  showBrightnessButton: false,
)
```

## 🔧 Características

- **Reutilizable**: Se puede usar en cualquier parte de la aplicación
- **Configurable**: Múltiples opciones de personalización
- **Consistente**: Mantiene el diseño coherente en toda la app
- **Material 3**: Sigue las especificaciones de Material Design 3
- **Provider Integration**: Se integra automáticamente con `ThemeDataAppProvider`
- **Responsive**: Se adapta a diferentes tamaños de pantalla

## 📱 Ubicaciones Actuales

Estos widgets están siendo utilizados en:

1. **LoginPage**: Esquina superior derecha con ambos controles
2. **SellPage**: En el drawer con espaciado compacto
3. **Próximamente**: WelcomePage y otros componentes

## 🎯 Beneficios

- **DRY Principle**: Evita duplicación de código
- **Mantenibilidad**: Cambios centralizados afectan toda la app
- **Consistencia**: Mismo comportamiento y apariencia en toda la app
- **Flexibilidad**: Múltiples variantes para diferentes necesidades
- **Performance**: Optimizado para rebuilds mínimos con Consumer interno
