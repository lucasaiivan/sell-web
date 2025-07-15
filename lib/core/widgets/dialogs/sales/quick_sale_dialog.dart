import 'package:flutter/material.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/core/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/base/standard_dialogs.dart';
import 'package:sellweb/core/widgets/dialogs/components/dialog_components.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';

/// Diálogo modernizado para venta rápida siguiendo Material Design 3
class QuickSaleDialog extends StatefulWidget {
  const QuickSaleDialog({
    super.key,
    required this.provider,
  });

  final SellProvider provider;

  @override
  State<QuickSaleDialog> createState() => _QuickSaleDialogState();
}

class _QuickSaleDialogState extends State<QuickSaleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = AppMoneyTextEditingController();
  final _descriptionController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseDialog(
      title: 'Venta Rápida',
      icon: Icons.flash_on_rounded,
      width: 450,
      headerColor: theme.colorScheme.tertiaryContainer,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información explicativa
            DialogComponents.infoSection(
              context: context,
              title: 'Venta Rápida',
              icon: Icons.info_outline_rounded,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              content: Text(
                'Agrega un producto por monto específico sin necesidad de tenerlo en el catálogo.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            DialogComponents.sectionSpacing,

            // Campo de precio
            Text(
              'Precio del Producto',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            DialogComponents.itemSpacing,

            DialogComponents.moneyField(
              context: context,
              controller: _priceController,
              label: 'Precio de Venta',
              hint: '\$0.00',
            ),

            DialogComponents.sectionSpacing,

            // Campo de descripción
            Text(
              'Descripción (Opcional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            DialogComponents.itemSpacing,

            DialogComponents.textField(
              context: context,
              controller: _descriptionController,
              label: 'Descripción del Producto',
              hint: 'Ej: Producto especial, servicio, etc.',
              prefixIcon: Icons.label_outline_rounded,
              maxLines: 2,
            ),

            DialogComponents.sectionSpacing,

            // Ejemplo de cómo se verá
            if (_priceController.text.isNotEmpty) ...[
              DialogComponents.summaryContainer(
                context: context,
                label: 'Vista Previa',
                value: '\$${_getFormattedPrice()}',
                icon: Icons.visibility_rounded,
                backgroundColor: theme.colorScheme.tertiaryContainer,
              ),
            ],
          ],
        ),
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DialogComponents.primaryActionButton(
          context: context,
          text: 'Agregar Producto',
          icon: Icons.add_shopping_cart_rounded,
          onPressed: _processQuickSale,
          isLoading: _isProcessing,
        ),
      ],
    );
  }

  String _getFormattedPrice() {
    return _priceController.doubleValue.toStringAsFixed(2);
  }

  Future<void> _processQuickSale() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final price = _priceController.doubleValue;
      final description = _descriptionController.text.trim().isEmpty
          ? 'Venta rápida'
          : _descriptionController.text.trim();

      // Agregar el producto de venta rápida
      widget.provider.addQuickProduct(
        description: description,
        salePrice: price,
      );

      if (mounted) {
        Navigator.of(context).pop();

        // Mostrar confirmación
        showInfoDialog(
          context: context,
          title: 'Producto Agregado',
          message: 'El producto de venta rápida se ha agregado al ticket.',
          icon: Icons.check_circle_outline_rounded,
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudo agregar el producto de venta rápida.',
          details: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

/// Helper function para mostrar el diálogo de venta rápida
Future<void> showQuickSaleDialog(
  BuildContext context, {
  required SellProvider provider,
}) {
  return showDialog(
    context: context,
    builder: (context) => QuickSaleDialog(
      provider: provider,
    ),
  );
}
