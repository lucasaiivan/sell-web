import 'package:flutter/material.dart';
import 'package:sellweb/core/presentation/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/core/presentation/widgets/dialogs/components/dialog_components.dart';

/// Diálogo que se muestra cuando un producto no es encontrado
class ProductNotFoundDialog extends StatelessWidget {
  final String code;
  final VoidCallback onCreateNew;

  const ProductNotFoundDialog({
    super.key,
    required this.code,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: code,
      icon: Icons.search_off_rounded,
      width: 400,
      headerColor: Theme.of(context).colorScheme.errorContainer,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DialogComponents.infoSection(
            context: context,
            title: 'Producto No Encontrado',
            icon: Icons.inventory_2_outlined,
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            content: Text(
              'No se encontró ningún producto con el código especificado.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DialogComponents.primaryActionButton(
          context: context,
          text: 'Crear Producto',
          icon: Icons.add_circle_outline_rounded,
          onPressed: () {
            Navigator.of(context).pop();
            onCreateNew();
          },
        ),
      ],
    );
  }
}

/// Helper function para mostrar el diálogo de producto no encontrado
Future<void> showProductNotFoundDialog(
  BuildContext context, {
  required String code,
  required VoidCallback onCreateNew,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => ProductNotFoundDialog(
      code: code,
      onCreateNew: onCreateNew,
    ),
  );
}
