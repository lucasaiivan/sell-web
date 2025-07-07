// Archivo de migración para facilitar la transición a la nueva estructura
// Este archivo puede ser eliminado una vez completada la migración

export 'dialogs/product_edit_dialog.dart' show showProductEditDialog;
export 'dialogs/add_product_dialog.dart' show showAddProductDialog;
export 'dialogs/quick_sale_dialog.dart' show showQuickSaleDialog;

// Re-exportaciones de funciones de ComponentApp para compatibilidad
export 'component_app_legacy.dart';

// Alias para funciones comunes que ahora están en otras clases
import 'feedback/app_feedback.dart';

/// Función helper para mostrar mensajes - usa AppFeedback internamente
void showMessageAlertApp({
  required context,
  required String title,
  required String message,
}) {
  AppFeedback.showMessage(context, title: title, message: message);
}
