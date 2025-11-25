# Feature: Sales

## Propósito
Gestión completa del **proceso de venta** - creación de tickets, cobro, descuentos, métodos de pago, y gestión de transacciones.

## Responsabilidades
- Creación y gestión de tickets de venta
- Agregar/quitar productos del ticket
- Aplicar descuentos
- Gestión de métodos de pago
- Cálculo de totales y vueltos
- Impresión de tickets
- Anulación de ventas
- Historial de transacciones

## Estructura

```
sales/
├── domain/
│   ├── entities/
│   │   ├── ticket.dart
│   │   └── ticket_product.dart
│   ├── repositories/
│   │   └── sales_repository.dart (si aplica)
│   └── usecases/
│       └── sell_usecases.dart
├── data/
│   └── (implementaciones si son necesarias)
└── presentation/
    ├── providers/
    │   └── sales_provider.dart       # Provider principal (1200+ líneas)
    ├── pages/
    │   └── sales_page.dart           # Vista principal (2000+ líneas)
    └── dialogs/
        ├── quick_sale_dialog.dart
        ├── discount_dialog.dart
        ├── discard_ticket_dialog.dart
        ├── last_ticket_dialog.dart
        ├── ticket_options_dialog.dart
        ├── cash_register_open_dialog.dart
        ├── cash_register_close_dialog.dart
        └── cash_register_management_dialog.dart
```

## Provider Principal

### `SalesProvider`
**Responsabilidad:** Gestión completa del proceso de venta

**Inyección de Dependencias:**
```dart
@injectable
class SalesProvider extends ChangeNotifier {
  final SellUseCases _sellUseCases;
  final CashRegisterUseCases _cashRegisterUseCases;
  // ...
}
```

**Estado Gestionado:**
- Ticket actual
- Lista de productos en ticket
- Cuenta seleccionada
- Último ticket vendido
- Configuración de impresión

**Operaciones Principales:**
```dart
// Productos
void addProductToTicket(ProductCatalogue product);
void removeProductFromTicket(String productId);
void addQuickProduct({String description, double salePrice});

// Descuentos y pagos
void setDiscount({double discount, bool isPercentage});
void setPayMode({String payMode});
void setValueReceived(double value);

// Ticket lifecycle
void confirmSale();
void discardTicket();
void annulTicket(String ticketId);
```

## Entities (Domain)

### `Ticket` (Inmutable)
```dart
class Ticket {
  final String id;
  final List<TicketProduct> products;
  final double discount;
  final bool discountIsPercentage;
  final String payMode;
  final double valueReceived;
  final DateTime timestamp;
  // ...
  
  double get getTotalPrice;
  double get getTotalPriceWithoutDiscount;
  int get getProductsQuantity;
}
```

### `TicketProduct`
Producto dentro de un ticket con cantidad y precio

## Página Principal

### `SalesPage`
**Vista completa de ventas** (2000+ líneas) con:
- Buscador de productos (scanner y search)
- Grid de productos del catálogo
- Drawer de ticket
- Gestión de caja registradora
- Impresión

**Secciones:**
1. **Header** - Cuenta, caja, búsqueda
2. **Product Grid** - Catálogo clickeable
3. **Ticket Drawer** - Vista del ticket actual
4. **Dialogs** - Quick sale, descuentos, etc.

## Diálogos Principales

### Ventas
- **QuickSaleDialog** - Venta rápida sin producto del catálogo
- **DiscountDialog** - Aplicar descuento (% o monto fijo)
- **DiscardTicketDialog** - Confirmar descarte de ticket

### Tickets
- **LastTicketDialog** - Ver último ticket vendido
- **TicketOptionsDialog** - Opciones del ticket (imprimir, anular)

### Caja Registradora
- **CashRegisterOpenDialog** - Abrir nueva caja
- **CashRegisterCloseDialog** - Cerrar caja con arqueo
- **CashRegisterManagementDialog** - Gestión completa de caja

## Dependencias

### Internas (Críticas)
- `features/catalogue` - **CatalogueProvider** (productos)
- `features/cash_register` - **CashRegisterProvider** (caja)
- `features/auth` - **AuthProvider** (usuario/cuenta)
- `core/services/printing/` - **PrinterProvider** (impresión)

### Flujo de Dependencias
```
SalesProvider
    ├─→ CatalogueProvider (productos disponibles)
    ├─→ CashRegisterProvider (actualizar caja al vender)
    └─→ AuthProvider (cuenta activa)
```

## Integración con Cash Register

Cada venta actualiza el cash register:
```dart
// Al confirmar venta
await _cashRegisterUseCases.updateSalesAndBilling(
  accountId: accountId,
  cashRegisterId: cashRegisterId,
  billingIncrement: ticket.getTotalPrice,
  discountIncrement: ticket.getDiscountAmount,
);
```

## Use Cases

### `SellUseCases`
Conjunto de casos de uso para ventas:
- Confirmar venta
- Guardar transacción
- Anular ticket
- Imprimir ticket

## Características Especiales

- **Scanner Integration** - Lector de códigos de barras
- **Keyboard Shortcuts** - Atajos para operaciones rápidas
- **Real-time Calculations** - Cálculo instantáneo de totales
- **Multiple Payment Methods** - Efectivo, tarjeta, Mercado Pago
- **Ticket Printing** - Integración con impresoras
- **Drag & Drop** - Organización de productos

## Clean Architecture

✅ **Domain Layer** - Entities inmutables (Ticket, TicketProduct)
✅ **Use Cases** - Lógica de negocio de ventas
✅ **Presentation** - Provider complejo con muchas operaciones
✅ **DI** - Injectable

## Relación con Cash Register

**Sales NO contiene** cash_register porque:
- Son bounded contexts diferentes
- Cash register tiene lógica independiente (arqueos, flujos)
- Sales **usa** cash_register, no lo contiene
- Separación permite testing independiente
