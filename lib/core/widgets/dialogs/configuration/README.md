# Configuration Dialogs

## 📋 Propósito
Diálogos relacionados con la configuración del sistema y dispositivos.

## 📁 Archivos

### `printer_config_dialog.dart`
- **Contexto**: Diálogo para configurar impresora térmica
- **Propósito**: Permite configurar la conexión con impresoras térmicas via HTTP
- **Uso**: Configuración de dispositivos de impresión

### `theme_color_selector_dialog.dart` ⭐ **MEJORADO CON CHIPS**
- **Contexto**: Diálogo premium para personalización completa del tema con diseño moderno
- **Propósito**: Permite al usuario personalizar completamente la apariencia de la aplicación
- **Características mejoradas**: 
  - ✅ **Chips elegantes**: Diseño moderno con nombres artísticos de colores
  - ✅ **Paleta extendida**: 15 colores cuidadosamente seleccionados vs 6 originales
  - ✅ **Animaciones fluidas**: Transiciones suaves al abrir/cerrar el diálogo
  - ✅ **Layout responsivo**: Wrap layout que se adapta automáticamente al contenido
  - ✅ **Feedback visual**: Hover effects, sombras y animaciones de selección
  - ✅ **Vista previa en tiempo real**: Componentes de ejemplo con el tema seleccionado
  - ✅ **Control de brillo mejorado**: Interfaz más intuitiva con gradientes
  - ✅ **Accesibilidad**: Contraste automático de texto y navegación por teclado
  - ✅ **Diseño premium**: Gradientes, sombras y Material Design 3 completo
  - ✅ **UX intuitiva**: Chips con círculo de color y texto descriptivo
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
