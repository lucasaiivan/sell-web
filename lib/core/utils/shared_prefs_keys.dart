/// Claves globales para SharedPreferences
/// Centraliza las keys para acceso en todo el proyecto.
class SharedPrefsKeys {
  // ==========================================
  // GESTIÓN DE CUENTAS
  // ==========================================
  static const String selectedAccountId = 'selected_account_id';

  // ==========================================
  // GESTIÓN DE CAJAS REGISTRADORAS
  // ==========================================
  static const String selectedCashRegisterId = 'selected_cash_register_id';

  // ==========================================
  // GESTIÓN DE TEMA
  // ==========================================
  static const String themeMode = 'theme_mode';

  // ==========================================
  // GESTIÓN DE TICKETS
  // ==========================================
  static const String currentTicket = 'current_ticket';
  static const String lastSoldTicket = 'last_sold_ticket';

  // ==========================================
  // CONFIGURACIONES DE IMPRESIÓN
  // ==========================================
  static const String shouldPrintTicket = 'should_print_ticket';
  static const String printerName = 'thermal_printer_name';
  static const String printerVendorId = 'thermal_printer_vendor_id';
  static const String printerProductId = 'thermal_printer_product_id';
}
