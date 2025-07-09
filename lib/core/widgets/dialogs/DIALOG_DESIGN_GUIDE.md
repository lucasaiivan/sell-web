# Guía de Diseño de Diálogos - Material Design 3

## 🎯 Objetivo
Esta guía establece los estándares de diseño para todos los diálogos de la aplicación, asegurando consistencia visual y coherencia con Material Design 3.

## 🏗️ Componentes Base

### **BaseDialog**
Diálogo base que proporciona la estructura estándar para todos los diálogos de la aplicación.

**Características principales:**
- Header con título, icono opcional y botón de cierre
- Contenido scrollable automático
- Área de acciones en la parte inferior
- Sombras y bordes redondeados según MD3
- Soporte completo para temas claro/oscuro

**Uso básico:**
```dart
BaseDialog(
  title: 'Título del Diálogo',
  icon: Icons.info_outline_rounded,
  content: Text('Contenido del diálogo'),
  actions: [
    TextButton(onPressed: () {}, child: Text('Cancelar')),
    FilledButton(onPressed: () {}, child: Text('Confirmar')),
  ],
)
```

### **Diálogos Estándar Predefinidos**

#### **ConfirmationDialog**
Para confirmaciones de acciones importantes.
```dart
showConfirmationDialog(
  context: context,
  title: 'Confirmar Acción',
  message: '¿Estás seguro de que deseas continuar?',
  isDestructive: true, // Para acciones destructivas
);
```

#### **InfoDialog**
Para mostrar información simple al usuario.
```dart
showInfoDialog(
  context: context,
  title: 'Información',
  message: 'Operación completada exitosamente.',
);
```

#### **ErrorDialog**
Para mostrar errores con detalles técnicos opcionales.
```dart
showErrorDialog(
  context: context,
  title: 'Error de Conexión',
  message: 'No se pudo conectar con el servidor.',
  details: 'HTTP 500 - Internal Server Error',
);
```

#### **LoadingDialog**
Para operaciones de carga con progreso opcional.
```dart
showLoadingDialog(
  context: context,
  message: 'Guardando cambios...',
  progress: 0.7, // Opcional
);
```

## 🎨 Estándares Visuales

### **Colores y Temas**
- **Header**: `primaryContainer` por defecto
- **Superficie**: `surface` con sombras estándar
- **Errores**: `errorContainer` para diálogos destructivos
- **Texto**: Colores apropiados según el contenedor (`onPrimaryContainer`, `onSurface`, etc.)

### **Tipografía**
- **Título**: `headlineSmall` con `fontWeight.w600`
- **Contenido**: `bodyLarge` para texto principal
- **Labels**: `titleSmall` para etiquetas de sección
- **Detalles**: `bodySmall` para información secundaria

### **Espaciado**
- **Padding Header**: `20px` vertical, `24px` horizontal
- **Padding Contenido**: `16px` vertical, `24px` horizontal
- **Padding Acciones**: `8px` arriba, `24px` horizontal y abajo
- **Separación Botones**: `12px` entre botones de acción

### **Dimensiones**
- **Ancho máximo**: `600px` (responsivo)
- **Alto máximo**: `600px` antes de scroll
- **Border radius**: `24px` para el contenedor principal
- **Border radius interno**: `12px` para secciones

## 🧱 Componentes de UI

### **DialogComponents**
Conjunto de widgets reutilizables para construir diálogos complejos.

#### **Sección de Información**
```dart
DialogComponents.infoSection(
  context: context,
  title: 'Información del Producto',
  icon: Icons.inventory_2_outlined,
  content: Column(
    children: [
      DialogComponents.infoRow(
        context: context,
        label: 'Código',
        value: 'PRD001',
      ),
    ],
  ),
);
```

#### **Lista de Elementos**
```dart
DialogComponents.itemList(
  context: context,
  items: [
    ProductTile(product: product1),
    ProductTile(product: product2),
  ],
  showDividers: true,
);
```

#### **Botones de Acción**
```dart
DialogComponents.primaryActionButton(
  context: context,
  text: 'Guardar',
  icon: Icons.save_rounded,
  onPressed: () {},
  isLoading: isProcessing,
);

DialogComponents.secondaryActionButton(
  context: context,
  text: 'Cancelar',
  icon: Icons.cancel_outlined,
  onPressed: () {},
);
```

#### **Campos de Texto**
```dart
DialogComponents.textField(
  context: context,
  controller: nameController,
  label: 'Nombre del Producto',
  prefixIcon: Icons.label_outline,
  validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
);
```

#### **Contenedor de Resumen**
```dart
DialogComponents.summaryContainer(
  context: context,
  label: 'Total a Pagar',
  value: '\$150.00',
  icon: Icons.monetization_on_outlined,
);
```

## 📱 Responsividad

### **Breakpoints**
- **Móvil**: Padding reducido, botones stack vertical si es necesario
- **Tablet**: Ancho fijo de `400-500px`
- **Desktop**: Ancho máximo de `600px`, centrado

### **Adaptaciones Móvil**
- Header más compacto en pantallas pequeñas
- Botones de ancho completo en móvil
- Reducir padding interno en pantallas < 400px

## ✅ Buenas Prácticas

### **Estructura Recomendada**
1. **Header** con título descriptivo e icono apropiado
2. **Contenido principal** organizado en secciones lógicas
3. **Acciones** alineadas a la derecha, acción primaria al final

### **Iconografía**
- Usar iconos de Material Design con sufijo `_rounded`
- Tamaño estándar de `24-28px` para headers
- Tamaño de `20px` para secciones
- Tamaño de `18px` para elementos de lista

### **Estados de Carga**
- Deshabilitar botones durante operaciones asíncronas
- Mostrar indicadores de progreso cuando sea posible
- Usar `LoadingDialog` para operaciones largas

### **Manejo de Errores**
- Validación en tiempo real en formularios
- Mensajes de error claros y accionables
- Detalles técnicos colapsables cuando sea apropiado

## 🚀 Ejemplos de Implementación

### **Diálogo de Producto Simple**
```dart
Future<void> showProductDialog(BuildContext context, Product product) {
  return showBaseDialog(
    context: context,
    title: 'Detalles del Producto',
    icon: Icons.inventory_2_outlined,
    width: 450,
    content: Column(
      children: [
        DialogComponents.infoSection(
          context: context,
          title: 'Información General',
          content: Column(
            children: [
              DialogComponents.infoRow(
                context: context,
                label: 'Código',
                value: product.code,
              ),
              DialogComponents.itemSpacing,
              DialogComponents.infoRow(
                context: context,
                label: 'Nombre',
                value: product.name,
              ),
            ],
          ),
        ),
        DialogComponents.summaryContainer(
          context: context,
          label: 'Precio',
          value: '\$${product.price.toStringAsFixed(2)}',
          icon: Icons.monetization_on_outlined,
        ),
      ],
    ),
    actions: [
      DialogComponents.secondaryActionButton(
        context: context,
        text: 'Cerrar',
        onPressed: () => Navigator.of(context).pop(),
      ),
    ],
  );
}
```

### **Diálogo de Formulario Complejo**
```dart
class ProductFormDialog extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: 'Agregar Producto',
      icon: Icons.add_box_outlined,
      width: 500,
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            DialogComponents.textField(
              context: context,
              controller: _nameController,
              label: 'Nombre del Producto',
              prefixIcon: Icons.label_outline,
              validator: _validateName,
            ),
            DialogComponents.itemSpacing,
            DialogComponents.textField(
              context: context,
              controller: _priceController,
              label: 'Precio',
              prefixIcon: Icons.monetization_on_outlined,
              keyboardType: TextInputType.number,
              validator: _validatePrice,
            ),
          ],
        ),
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DialogComponents.primaryActionButton(
          context: context,
          text: 'Guardar',
          icon: Icons.save_rounded,
          onPressed: _saveProduct,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}
```

## 🔍 Testing y Calidad

### **Checklist de Revisión**
- [ ] Usa `BaseDialog` como base
- [ ] Header con título descriptivo e icono apropiado
- [ ] Colores consistentes con el tema
- [ ] Responsive en diferentes tamaños
- [ ] Estados de carga manejados correctamente
- [ ] Validación de formularios en tiempo real
- [ ] Accesibilidad (tooltips, navegación por teclado)
- [ ] Manejo correcto de errores

### **Pruebas Recomendadas**
- Modo claro y oscuro
- Diferentes tamaños de pantalla
- Estados de carga y error
- Navegación por teclado
- Acciones destructivas con confirmación

---

**Última actualización**: Julio 2025 - Implementación de guía Material Design 3
**Mantenido por**: Equipo de desarrollo siguiendo Clean Architecture
