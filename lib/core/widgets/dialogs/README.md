# Diálogos - Widgets de Interfaz de Usuario

## 📋 Propósito
Este directorio contiene todos los diálogos y modales reutilizables de la aplicación, implementando Material Design 3 y siguiendo las convenciones de Clean Architecture.

## 🏗️ Estructura

### **Diálogos Principales**
- `add_product_dialog.dart` - Diálogo para agregar/crear productos al catálogo
- `product_edit_dialog.dart` - Diálogo de edición de productos existentes
- `quick_sale_dialog.dart` - Diálogo de venta rápida por monto fijo
- `ticket_options_dialog.dart` - Opciones de ticket (PDF, impresión, compartir)
- `printer_config_dialog.dart` - Configuración de impresora térmica
- `last_ticket_dialog.dart` - **NUEVO** - Visualización y reimpresión del último ticket

### **Archivo de Exports**
- `dialogs.dart` - Centraliza todas las exportaciones de diálogos y funciones helper

## 🎯 Funcionalidades por Diálogo

### **LastTicketDialog** (Nuevo)
- **Contexto**: Muestra el último ticket vendido con acceso a opciones completas
- **Propósito**: Acceso rápido al último ticket desde el AppBar
- **Uso**: Llamado desde el IconButton del último ticket en sell_page.dart

**Características principales:**
- Visualización completa de datos del ticket
- Lista detallada de productos con precios
- Información de método de pago y totales
- Botón "Imprimir" que abre el diálogo de opciones de ticket
- Integración completa con el flujo de opciones existente
- Formateo de fecha sin dependencias de localización

### **AddProductDialog**
- **Contexto**: Agregar nuevos productos al catálogo
- **Propósito**: Captura de datos de productos (código, nombre, precio, etc.)
- **Uso**: Desde scanner de códigos de barras y botón de agregar producto

### **ProductEditDialog**
- **Contexto**: Edición de productos existentes
- **Propósito**: Modificar información de productos del catálogo
- **Uso**: Desde la vista de productos en el catálogo

### **QuickSaleDialog**
- **Contexto**: Ventas rápidas por monto específico
- **Propósito**: Agilizar ventas sin seleccionar productos específicos
- **Uso**: Desde floating action button en la pantalla principal

### **TicketOptionsDialog**
- **Contexto**: Opciones posteriores a la venta
- **Propósito**: Generar PDF, imprimir o compartir ticket
- **Uso**: Después de confirmar una venta cuando no hay impresora

### **PrinterConfigDialog**
- **Contexto**: Configuración de impresora térmica
- **Propósito**: Configurar conexión USB con impresora
- **Uso**: Desde el botón de impresora en el AppBar

## 🎨 Estándares de Diseño

### **Material Design 3**
- Uso consistente del tema dinámico de la aplicación
- Componentes con esquemas de color adaptativos
- Tipografía y espaciado según especificaciones MD3
- Soporte completo para modo claro/oscuro

### **Responsive Design**
- Adaptación automática a diferentes tamaños de pantalla
- Ancho máximo definido para escritorio
- Comportamiento apropiado en móvil y tablet

### **Accesibilidad**
- Tooltips informativos en botones
- Estados visuales claros (habilitado/deshabilitado)
- Textos legibles con contraste apropiado

## 🔧 Implementación Técnica

### **Arquitectura**
- Cada diálogo es un StatefulWidget independiente
- Funciones helper `showXXXDialog()` para facilitar el uso
- Separación clara de lógica de UI y lógica de negocio

### **State Management**
- Uso de Provider cuando se requiere acceso a estado global
- Estado local para UI específica del diálogo
- Notificaciones mediante callbacks para comunicación con parent

### **Error Handling**
- Validación de datos en tiempo real
- Manejo de errores asíncronos (impresión, guardado)
- Feedback visual mediante SnackBars

### **Performance**
- Constructores const donde es posible
- Lazy loading de recursos pesados
- Minimización de rebuilds innecesarios

## 📱 Patrones de Uso

### **Patrón Estándar**
```dart
// 1. Import del diálogo específico
import 'package:sellweb/core/widgets/dialogs/last_ticket_dialog.dart';

// 2. Uso de la función helper
await showLastTicketDialog(
  context: context,
  ticket: lastTicket,
  businessName: businessName,
);
```

### **Patrón con Callback**
```dart
await showTicketOptionsDialog(
  context: context,
  ticket: ticket,
  businessName: businessName,
  onComplete: () {
    // Acción posterior al completar
  },
);
```

## 🚀 Nuevas Implementaciones

### **Consideraciones para Nuevos Diálogos**
1. **Nomenclatura**: Seguir patrón `{proposito}_dialog.dart`
2. **Exports**: Agregar al archivo `dialogs.dart`
3. **Función Helper**: Implementar `show{Dialogo}Dialog()`
4. **Material 3**: Usar componentes y tema consistente
5. **Responsive**: Considerar diferentes tamaños de pantalla
6. **Localización**: Evitar dependencias de locale específico cuando sea posible

### **Template Base**
```dart
class CustomDialog extends StatefulWidget {
  const CustomDialog({super.key, required this.data});
  
  final DataType data;
  
  @override
  State<CustomDialog> createState() => _CustomDialogState();
}

// Función helper
Future<void> showCustomDialog({
  required BuildContext context,
  required DataType data,
}) async {
  await showDialog(
    context: context,
    builder: (context) => CustomDialog(data: data),
  );
}
```

## 🔍 Debugging y Testing

### **Testing de Diálogos**
- Verificar apertura y cierre correcto
- Validar datos de entrada y salida
- Probar en diferentes tamaños de pantalla
- Verificar accesibilidad y navegación por teclado

### **Common Issues**
- **LocaleDataException**: Usar formateo de fecha simple sin localización específica
- **BuildContext across gaps**: Verificar `mounted` antes de operaciones asíncronas
- **Overflow**: Usar `SingleChildScrollView` en contenido largo

---

**Última actualización**: Julio 2025 - Implementación de LastTicketDialog
**Mantenido por**: Equipo de desarrollo siguiendo Clean Architecture y Material Design 3
