/// Claves globales para SharedPreferences
/// Centraliza las keys para acceso en todo el proyecto.
class SharedPrefsKeys {
  static const String selectedAccountId = 'selected_account_id';
  static const String currentTicket = 'current_ticket';
  static const String lastSoldTicket =
      'last_sold_ticket'; // Nuevo: para el último ticket vendido
  static const String shouldPrintTicket = 'should_print_ticket';
  static const String printerName = 'thermal_printer_name';
  static const String printerVendorId = 'thermal_printer_vendor_id';
  static const String printerProductId = 'thermal_printer_product_id';
}
