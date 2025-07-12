# Dialog Components

## 📋 Propósito
Componentes de UI reutilizables para construir diálogos complejos siguiendo Material Design 3. Esta biblioteca proporciona elementos visuales consistentes y estandarizados que garantizan una experiencia de usuario cohesiva en toda la aplicación.

## 📁 Archivos

### `dialog_components.dart`
- **Contexto**: Biblioteca completa de componentes UI estandarizados para diálogos
- **Propósito**: Proporciona elementos visuales consistentes siguiendo Material Design 3
- **Uso**: Componentes reutilizables para construir diálogos complejos sin duplicar código

## 🔧 Componentes Disponibles

### 📋 **Secciones de Información**
```dart
// Sección de información estilizada con contenedor
DialogComponents.infoSection(
  title: 'Información del Producto',
  content: Text('Descripción detallada...'),
  icon: Icons.info_rounded,
  backgroundColor: Colors.blue.shade50, // Opcional
  context: context,
)
```

### 📝 **Listas y Elementos**
```dart
// Lista de elementos con divisores opcionales
DialogComponents.itemList(
  items: [
    Text('Elemento 1'),
    Text('Elemento 2'),
    Text('Elemento 3'),
  ],
  showDividers: true, // Por defecto: true
  context: context,
)

// Fila de información con label y valor
DialogComponents.infoRow(
  label: 'Precio',
  value: '\$25.00',
  icon: Icons.monetization_on_rounded, // Opcional
  valueStyle: TextStyle(fontWeight: FontWeight.bold), // Opcional
  context: context,
)
```

### 🎨 **Campos de Entrada**
```dart
// Campo de texto estilizado para formularios
DialogComponents.textField(
  controller: _textController,
  label: 'Nombre del Producto',
  hint: 'Ingrese el nombre...',
  prefixIcon: Icons.shopping_bag_rounded, // Opcional
  suffixIcon: Icons.clear_rounded, // Opcional
  onSuffixPressed: () => _textController.clear(), // Opcional
  keyboardType: TextInputType.text,
  validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
  context: context,
)
```

### 🔘 **Botones de Acción**
```dart
// Botón primario con estados de carga
DialogComponents.primaryActionButton(
  text: 'Guardar Cambios',
  onPressed: _handleSave,
  icon: Icons.save_rounded, // Opcional
  isDestructive: false, // Por defecto: false
  isLoading: _isLoading, // Por defecto: false
  context: context,
)

// Botón secundario
DialogComponents.secondaryActionButton(
  text: 'Cancelar',
  onPressed: () => Navigator.of(context).pop(),
  icon: Icons.cancel_outlined, // Opcional
  context: context,
)
```

### 💰 **Contenedores de Resumen**
```dart
// Contenedor destacado para totales o información importante
DialogComponents.summaryContainer(
  label: 'Total a Pagar',
  value: '\$127.50',
  icon: Icons.receipt_rounded, // Opcional
  backgroundColor: Colors.green.shade50, // Opcional
  context: context,
)
```

### 🏷️ **Badges Informativos**
```dart
// Badge/chip para información adicional
DialogComponents.infoBadge(
  text: 'Producto Activo',
  icon: Icons.check_circle_rounded, // Opcional
  backgroundColor: Colors.green.shade100, // Opcional
  textColor: Colors.green.shade800, // Opcional
  context: context,
)
```

### 📏 **Espaciado Estándar**
```dart
// Espaciado consistente entre secciones
DialogComponents.sectionSpacing, // 24px vertical

// Espaciado entre elementos
DialogComponents.itemSpacing, // 12px vertical

// Espaciado mínimo
DialogComponents.minSpacing, // 8px vertical
```

## 🎨 **Características Material Design 3**

- **🎯 Consistencia Visual**: Todos los componentes siguen las especificaciones MD3
- **🌓 Soporte Tema Dinámico**: Adaptación automática a modo claro/oscuro
- **🎨 Colores del Sistema**: Utiliza la paleta de colores del tema actual
- **📱 Responsive**: Adaptación automática a diferentes tamaños de pantalla
- **♿ Accesibilidad**: Cumple con estándares de accesibilidad

## 💡 **Ejemplos de Uso Completo**

### Diálogo de Confirmación de Venta
```dart
BaseDialog(
  title: 'Confirmar Venta',
  icon: Icons.point_of_sale_rounded,
  content: Column(
    children: [
      DialogComponents.infoSection(
        title: 'Resumen de la Venta',
        content: Column(
          children: [
            DialogComponents.infoRow(
              label: 'Productos',
              value: '3 artículos',
              context: context,
            ),
            DialogComponents.itemSpacing,
            DialogComponents.infoRow(
              label: 'Subtotal',
              value: '\$95.50',
              context: context,
            ),
          ],
        ),
        context: context,
      ),
      DialogComponents.sectionSpacing,
      DialogComponents.summaryContainer(
        label: 'Total Final',
        value: '\$95.50',
        icon: Icons.monetization_on_rounded,
        context: context,
      ),
    ],
  ),
  actions: [
    DialogComponents.secondaryActionButton(
      text: 'Cancelar',
      onPressed: () => Navigator.of(context).pop(),
      context: context,
    ),
    DialogComponents.primaryActionButton(
      text: 'Confirmar Venta',
      onPressed: _processSale,
      icon: Icons.check_rounded,
      context: context,
    ),
  ],
)
```

## 🚀 **Buenas Prácticas**

1. **Consistencia**: Usar siempre estos componentes en lugar de crear widgets personalizados
2. **Contextualización**: Siempre pasar el `BuildContext` para acceder al tema
3. **Iconografía**: Usar iconos con sufijo `_rounded` para consistencia MD3
4. **Espaciado**: Utilizar los espaciados predefinidos para mantener uniformidad
5. **Estados**: Manejar estados de carga y error en botones de acción
6. **Validación**: Implementar validadores en campos de texto cuando sea necesario
