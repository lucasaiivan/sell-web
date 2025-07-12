# Configuration Dialogs

## 📋 Propósito
Diálogos relacionados con la configuración del sistema y dispositivos.

## 📁 Archivos

### `printer_config_dialog.dart`
- **Contexto**: Diálogo para configurar impresora térmica
- **Propósito**: Permite configurar la conexión con impresoras térmicas via HTTP
- **Uso**: Se abre desde el menú de configuración para establecer parámetros de impresión

### `printer_config_dialog_new.dart`
- **Contexto**: Versión modernizada del diálogo de configuración de impresora
- **Propósito**: Implementación mejorada con Material Design 3
- **Uso**: Reemplazo moderno del diálogo original

## 🔧 Uso
```dart
// Configuración de impresora
showDialog(
  context: context,
  builder: (context) => PrinterConfigDialog(),
);
```
