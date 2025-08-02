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

  // FocusNodes para navegación por teclado
  final _priceFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  bool _isProcessing = false;
  bool _showPriceError = false;

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
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
              autofocus: true,
              context: context,
              controller: _priceController,
              focusNode: _priceFocusNode,
              nextFocusNode: _descriptionFocusNode,
              textInputAction: TextInputAction.next,
              label: 'Precio de Venta',
              hint: '\$0.0',
              errorText: _showPriceError &&
                      (_priceController.text.isEmpty ||
                          _priceController.doubleValue <= 0)
                  ? 'El precio es obligatorio y debe ser mayor a 0'
                  : null,
              onChanged: (value) {
                // Quitar el error cuando el usuario escribe un valor válido
                if (_showPriceError && value > 0) {
                  setState(() {
                    _showPriceError = false;
                  });
                }
              },
            ),

            DialogComponents.sectionSpacing,

            // Campo de descripción
            Text(
              'Descripción',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            DialogComponents.itemSpacing,

            DialogComponents.textField(
              context: context,
              controller: _descriptionController,
              focusNode: _descriptionFocusNode,
              textInputAction: TextInputAction.done,
              label: 'Descripción (Opcional)',
              hint: 'Ej: bebida, snack, etc.',
              onEditingComplete: () {
                // Al presionar Enter en el campo de descripción, procesar la venta
                _processQuickSale();
              },
              onSuffixPressed: () => _showPriceError = false,
            ),

            DialogComponents.sectionSpacing,
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
          onPressed: _processQuickSale,
          isLoading: _isProcessing,
        ),
      ],
    );
  }

  Future<void> _processQuickSale() async {
    // Validar que el precio no esté vacío y sea mayor a 0
    if (_priceController.text.isEmpty || _priceController.doubleValue <= 0) {
      setState(() {
        _showPriceError = true;
      });
      return;
    }

    // Validar formulario antes de proceder
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final price = _priceController.doubleValue;
      final description = _descriptionController.text.trim().isEmpty
          ? ''
          : _descriptionController.text.trim();

      // Agregar el producto de venta rápida
      widget.provider.addQuickProduct(
        description: description,
        salePrice: price,
      );

      if (mounted) {
        Navigator.of(context).pop();
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
