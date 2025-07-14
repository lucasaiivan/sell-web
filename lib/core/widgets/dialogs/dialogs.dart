// Dialog System Exports - Material Design 3
// Centraliza todas las exportaciones de diálogos para fácil acceso

// Base Components
export 'base/base_dialog.dart';
export 'base/standard_dialogs.dart';

// UI Components
export 'components/dialog_components.dart';

// Catalogue Dialogs
export 'catalogue/add_product_dialog.dart';
export 'catalogue/product_edit_dialog.dart';
export 'catalogue/product_not_found_dialog.dart';
// export 'catalogue/add_product_dialog_new.dart'; // Conflicto de nombres - usar alias si necesario
// export 'catalogue/product_edit_dialog_new.dart'; // Conflicto de nombres - usar alias si necesario

// Sales Dialogs
export 'sales/quick_sale_dialog.dart';
export 'sales/cash_register_dialog.dart';
// export 'sales/cash_register_management_dialog.dart'; // Conflicto de nombres - contenido en cash_register_dialog
// export 'sales/cash_register_open_dialog.dart'; // Conflicto de nombres - contenido en cash_register_dialog
// export 'sales/cash_register_close_dialog.dart'; // Conflicto de nombres - contenido en cash_register_dialog
// export 'sales/cash_flow_dialog.dart'; // Conflicto de nombres - contenido en cash_register_dialog
// export 'sales/quick_sale_dialog_new.dart'; // Conflicto de nombres

// Tickets Dialogs
export 'tickets/last_ticket_dialog.dart';
export 'tickets/ticket_options_dialog.dart';
export 'tickets/discard_ticket_dialog.dart';
// export 'tickets/ticket_options_dialog_new.dart'; // Conflicto de nombres - usar alias si necesario
// export 'tickets/last_ticket_dialog_new.dart'; // Conflicto de nombres

// Configuration Dialogs
export 'configuration/printer_config_dialog.dart';
// export 'configuration/printer_config_dialog_new.dart'; // Conflicto de nombres

// Examples (for development/testing)
export 'examples/example_modern_dialog.dart';
export 'examples/dialog_showcase.dart';

// Re-exportar funciones helper principales
export 'base/base_dialog.dart' show showBaseDialog;
export 'base/standard_dialogs.dart'
    show
        showConfirmationDialog,
        showInfoDialog,
        showErrorDialog,
        showLoadingDialog;
export 'examples/example_modern_dialog.dart' show showExampleModernDialog;

// Re-exportar funciones helper específicas
export 'catalogue/product_edit_dialog.dart' show showProductEditDialog;
export 'catalogue/add_product_dialog.dart' show showAddProductDialog;
export 'sales/quick_sale_dialog.dart' show showQuickSaleDialog;
export 'tickets/ticket_options_dialog.dart' show showTicketOptionsDialog;
export 'tickets/last_ticket_dialog.dart' show showLastTicketDialog;

// Nota: Archivos legacy eliminados - migración completada el 2025-07-12
