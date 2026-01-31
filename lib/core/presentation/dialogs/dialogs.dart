// Dialog System Exports - Material Design 3
// Centraliza todas las exportaciones de diálogos para fácil acceso

// Base Components (from widgets/dialogs/)
export '../widgets/dialogs/base/base_dialog.dart';
export '../widgets/dialogs/base/standard_dialogs.dart';

// UI Components (from widgets/dialogs/)
export '../widgets/dialogs/components/dialog_components.dart';

// Catalogue Dialogs
export 'package:sellweb/features/catalogue/presentation/dialogs/add_product_dialog.dart';
export 'package:sellweb/features/catalogue/presentation/dialogs/product_edit_dialog.dart';
export 'package:sellweb/features/catalogue/presentation/dialogs/product_not_found_dialog.dart';

// Sales Dialogs
export 'package:sellweb/features/sales/presentation/dialogs/quick_sale_dialog.dart';
export 'package:sellweb/features/sales/presentation/dialogs/discount_dialog.dart';

// Tickets Dialogs
export 'views/tickets/ticket_detail_dialog.dart';
export 'package:sellweb/features/sales/presentation/dialogs/ticket_options_dialog.dart';
export 'package:sellweb/features/sales/presentation/dialogs/discard_ticket_dialog.dart';

// Configuration Dialogs
export 'views/configuration/printer_config_dialog.dart';
export 'views/configuration/theme_color_selector_dialog.dart';

// Account Dialogs
export 'package:sellweb/features/auth/presentation/dialogs/admin_profile_info_dialog.dart';
export 'package:sellweb/features/auth/presentation/dialogs/account_selection_dialog.dart';

// Re-exportar funciones helper principales
export '../widgets/dialogs/base/base_dialog.dart' show showBaseDialog;
export '../widgets/dialogs/base/standard_dialogs.dart'
    show
        showConfirmationDialog,
        showInfoDialog,
        showErrorDialog,
        showLoadingDialog;

// Re-exportar funciones helper específicas
export 'package:sellweb/features/catalogue/presentation/dialogs/product_edit_dialog.dart'
    show showProductEditDialog;
export 'package:sellweb/features/catalogue/presentation/dialogs/add_product_dialog.dart'
    show showAddProductDialog;
export 'package:sellweb/features/sales/presentation/dialogs/quick_sale_dialog.dart'
    show showQuickSaleDialog;
export 'package:sellweb/features/sales/presentation/dialogs/ticket_options_dialog.dart'
    show showTicketOptionsDialog;
export 'views/configuration/theme_color_selector_dialog.dart'
    show ThemeColorSelectorDialog;
