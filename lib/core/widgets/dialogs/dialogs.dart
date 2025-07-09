// Exportaciones de diálogos - Base y componentes
export 'base_dialog.dart';
export 'standard_dialogs.dart';
export 'dialog_components.dart';

// Ejemplos, documentación y showcase
export 'example_modern_dialog.dart';
export 'dialog_showcase.dart';

// Exportaciones de diálogos específicos
export 'product_edit_dialog.dart';
export 'add_product_dialog.dart';
export 'quick_sale_dialog.dart';
export 'printer_config_dialog.dart';
export 'ticket_options_dialog.dart';
export 'last_ticket_dialog.dart';

// Re-exportar funciones helper principales
export 'base_dialog.dart' show showBaseDialog;
export 'standard_dialogs.dart' show showConfirmationDialog, showInfoDialog, showErrorDialog, showLoadingDialog;
export 'example_modern_dialog.dart' show showExampleModernDialog;

// Re-exportar funciones helper específicas
export 'product_edit_dialog.dart' show showProductEditDialog;
export 'add_product_dialog.dart' show showAddProductDialog;
export 'quick_sale_dialog.dart' show showQuickSaleDialog;
export 'ticket_options_dialog.dart' show showTicketOptionsDialog;
export 'last_ticket_dialog.dart' show showLastTicketDialog;
