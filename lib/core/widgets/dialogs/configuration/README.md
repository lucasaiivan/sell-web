# Configuration Dialogs

## 📋 Propósito
Diálogos relacionados con la configuración del sistema y dispositivos.

## 📁 Archivos

### `printer_config_dialog.dart`
- **Contexto**: Diálogo para configurar impresora térmica
- **Propósito**: Permite configurar la conexión con impresoras térmicas via HTTP
- **Uso**: Configuración de dispositivos de impresión

### `theme_color_selector_dialog.dart` ⭐ **ACTUALIZADO**
- **Contexto**: Diálogo para seleccionar color semilla del tema dinámico
- **Propósito**: Permite al usuario cambiar el color base de la aplicación
- **Características**: 
  - ✅ Paleta unificada de 6 colores (blue, teal, deepPurple, indigo, green, orange)
  - ✅ Grid layout 3x2 para mejor organización visual
  - ✅ Funciona tanto para tema claro como oscuro
  - ✅ UI simplificada con un solo título
  - ✅ Vista previa del color actual seleccionado
  - ✅ Indicadores visuales mejorados (check circle + border grueso)

## 🎨 **Actualización Theme Color Selector**

### **Cambios Implementados:**
- **Unificación**: Una sola paleta vs dos secciones separadas (claro/oscuro)
- **Grid Layout**: Cambió de filas horizontales a grid 3x2
- **Más Colores**: Expandido de 4 a 6 opciones de color
- **UI Mejorada**: Bordes redondeados (16px), indicadores más visibles
- **Código Simplificado**: Lógica unificada más fácil de mantener

### **Beneficios:**
- ✅ **Simplicidad**: Interfaz más limpia e intuitiva
- ✅ **Consistencia**: Mismos colores funcionan en ambos temas  
- ✅ **Escalabilidad**: Fácil agregar más colores
- ✅ **Usabilidad**: Grid más organizado que filas
- ✅ **Mantenimiento**: Código más limpio
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
