import 'package:flutter/material.dart';
import '../../../../../core/core.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';

/// Diálogo modernizado para venta rápida siguiendo Material Design 3
///
/// En pantallas pequeñas (< 600px) con fullView=true, se muestra en pantalla completa.
/// En pantallas grandes, siempre se muestra como diálogo modal.
class QuickSaleDialog extends StatefulWidget {
  const QuickSaleDialog({
    super.key,
    required this.provider,
    this.fullView = false,
  });

  final SalesProvider provider;
  final bool fullView;

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
      headerColor: theme.colorScheme.primaryContainer,
      fullView: widget.fullView,
      content: _buildContent(context),
      actions: _buildActions(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DialogComponents.sectionSpacing,
          DialogComponents.moneyField(
            autofocus: true,
            context: context,
            controller: _priceController,
            focusNode: _priceFocusNode,
            nextFocusNode: _descriptionFocusNode,
            textInputAction: TextInputAction.next,
            label: 'Ingresá el monto',
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
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      DialogComponents.secondaryActionButton(
        context: context,
        text: 'Cancelar',
        onPressed: () => Navigator.of(context).pop(),
      ),
      DialogComponents.primaryActionButton(
        context: context,
        text: 'Agregar',
        onPressed: _processQuickSale,
        isLoading: _isProcessing,
      ),
    ];
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
      widget.provider
          .addQuickProduct(description: description, salePrice: price);

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
///
/// **Parámetros:**
/// - `context`: BuildContext necesario para mostrar el diálogo
/// - `provider`: SalesProvider para agregar el producto de venta rápida
/// - `fullView`: Si es true, se muestra en pantalla completa en dispositivos pequeños (default: true)
///
/// **Ejemplo:**
/// ```dart
/// await showQuickSaleDialog(
///   context,
///   provider: salesProvider,
///   fullView: true,
/// );
/// ```
Future<void> showQuickSaleDialog(
  BuildContext context, {
  required SalesProvider provider,
  bool fullView = true,
}) {
  final isSmallScreen = MediaQuery.of(context).size.width < 600;

  // Si es vista completa Y pantalla pequeña, usar Navigator.push
  if (fullView && isSmallScreen) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => QuickSaleDialog(
          provider: provider,
          fullView: fullView,
        ),
      ),
    );
  }

  // Vista normal como diálogo
  return showDialog(
    context: context,
    builder: (context) => QuickSaleDialog(
      provider: provider,
      fullView: fullView,
    ),
  );
}
