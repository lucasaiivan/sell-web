# Tickets Dialogs

## 📋 Propósito
Diálogos relacionados con la gestión y visualización de tickets de venta.

## 📁 Archivos

### `last_ticket_dialog.dart`
- **Contexto**: Diálogo para mostrar el último ticket generado
- **Propósito**: Permite visualizar y reimprimir el último ticket de venta
- **Uso**: Se abre automáticamente después de una venta o desde el menú

### `ticket_options_dialog.dart`
- **Contexto**: Diálogo de opciones para tickets
- **Propósito**: Permite exportar, imprimir o compartir tickets
- **Uso**: Se abre desde la visualización de tickets para elegir acciones

### `ticket_options_dialog_new.dart`
- **Contexto**: Versión actualizada del diálogo de opciones
- **Propósito**: Implementación mejorada con Material Design 3
- **Uso**: Reemplazo moderno del diálogo de opciones original

### `last_ticket_dialog_new.dart`
- **Contexto**: Versión modernizada del diálogo de último ticket
- **Propósito**: Implementación mejorada con Material Design 3
- **Uso**: Reemplazo moderno del diálogo original

### `discard_ticket_dialog.dart`
- **Contexto**: Diálogo para descartar ticket actual
- **Propósito**: Permite cancelar una venta en progreso
- **Uso**: Se abre al intentar cancelar una venta activa

## 🔧 Uso
```dart
// Mostrar último ticket
showDialog(
  context: context,
  builder: (context) => LastTicketDialog(
    ticket: lastTicket,
    businessName: businessName,
  ),
);

// Opciones de ticket
showDialog(
  context: context,
  builder: (context) => TicketOptionsDialog(ticket: ticket),
);

// Descartar ticket
showDialog(
  context: context,
  builder: (context) => DiscardTicketDialog(),
);
```
