# Widgets de Ticket

Esta carpeta contiene todos los componentes relacionados con la visualización y manejo de tickets de venta.

## Estructura de archivos

### Widgets principales
- **`ticket_drawer_widget.dart`** - Contenedor principal que decide entre mostrar el ticket normal o la confirmación de compra
- **`ticket_content_widget.dart`** - Contenido principal del ticket con todos los detalles
- **`ticket_confirmed_purchase_widget.dart`** - Widget de confirmación de venta exitosa

### Componentes específicos
- **`ticket_header_widget.dart`** - Encabezado con nombre del negocio y fecha
- **`ticket_product_list_widget.dart`** - Lista scrolleable de productos con indicador
- **`ticket_total_widget.dart`** - Widget animado que muestra el total con efecto rebote
- **`ticket_payment_methods_widget.dart`** - Chips para selección de métodos de pago
- **`ticket_print_checkbox_widget.dart`** - Checkbox para habilitar/deshabilitar impresión
- **`ticket_action_buttons_widget.dart`** - Botones de confirmar venta y cerrar ticket

### Utilidades
- **`ticket_utils.dart`** - Funciones auxiliares para formateo y conversiones
- **`ticket_dashed_line_painter.dart`** - CustomPainter para líneas punteadas del ticket

## Propósito y uso

Estos widgets fueron extraídos de `sell_page.dart` para mejorar la organización del código siguiendo los principios de Clean Architecture. Cada componente tiene una responsabilidad específica y puede ser reutilizado en otras partes de la aplicación.

### Características principales

- **Modular**: Cada widget tiene una responsabilidad específica
- **Reutilizable**: Los componentes pueden usarse en otras páginas
- **Responsive**: Se adaptan a móviles, tablets y desktop
- **Material 3**: Siguen las guías de diseño de Material Design 3
- **Animado**: Incluyen animaciones suaves y feedback visual

### Dependencias principales

- Provider para manejo de estado
- flutter_animate para animaciones
- Material Design 3 para componentes de UI

### Uso típico

```dart
// En la página principal
TicketDrawerWidget(
  showConfirmedPurchase: _showConfirmedPurchase,
  onEditCashAmount: () => dialogSelectedIncomeCash(),
  onConfirmSale: () => confirmSale(),
  onCloseTicket: () => provider.setTicketView(false),
)
```

## Contexto del proyecto

Estos componentes forman parte del sistema de punto de venta y se integran con:
- `SellProvider` para manejo de estado del ticket
- `CashRegisterProvider` para registro de ventas
- `PrinterProvider` para impresión de tickets
- Servicios de impresión térmica HTTP
