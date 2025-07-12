# Base Dialogs

## 📋 Propósito
Contiene los componentes base fundamentales para crear diálogos siguiendo Material Design 3.

## 📁 Archivos

### `base_dialog.dart`
- **Contexto**: Diálogo base que implementa Material Design 3
- **Propósito**: Proporciona estructura estándar para todos los diálogos
- **Uso**: Clase base que extienden todos los diálogos de la aplicación

### `standard_dialogs.dart`
- **Contexto**: Diálogos predefinidos estándar
- **Propósito**: Provee diálogos comunes (confirmación, error, info, carga)
- **Uso**: Funciones helper para mostrar diálogos estándar rápidamente

## 🔧 Uso
```dart
// Diálogo base personalizado
BaseDialog(
  title: 'Mi Diálogo',
  icon: Icons.info_rounded,
  content: Widget(),
  actions: [/* botones */],
)

// Diálogos estándar
StandardDialogs.showConfirmation(context, 'Mensaje');
StandardDialogs.showError(context, 'Error');
```
