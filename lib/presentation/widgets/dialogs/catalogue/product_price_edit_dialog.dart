import 'package:sellweb/core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sellweb/presentation/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/presentation/widgets/dialogs/components/dialog_components.dart';
import 'package:sellweb/presentation/widgets/inputs/money_input_text_field.dart';
import 'package:sellweb/domain/entities/catalogue.dart';
import 'package:sellweb/presentation/providers/catalogue_provider.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';
import 'package:provider/provider.dart' as provider_package;

/// Diálogo para editar precios de producto (precio de venta y precio de compra)
class ProductPriceEditDialog extends StatefulWidget {
  const ProductPriceEditDialog({
    super.key,
    required this.product,
    required this.catalogueProvider,
    this.onProductUpdated,
  });

  final ProductCatalogue product;
  final CatalogueProvider catalogueProvider;
  final VoidCallback? onProductUpdated;

  @override
  State<ProductPriceEditDialog> createState() => _ProductPriceEditDialogState();
}

class _ProductPriceEditDialogState extends State<ProductPriceEditDialog> {
  late final AppMoneyTextEditingController _salePriceController;
  late final AppMoneyTextEditingController _purchasePriceController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _salePriceController = AppMoneyTextEditingController();
    _salePriceController.updateValue(widget.product.salePrice);

    _purchasePriceController = AppMoneyTextEditingController();
    _purchasePriceController.updateValue(widget.product.purchasePrice);
  }

  @override
  void dispose() {
    _salePriceController.dispose();
    _purchasePriceController.dispose();
    super.dispose();
  }

  double get _newSalePrice {
    return _salePriceController.doubleValue;
  }

  double get _newPurchasePrice {
    return _purchasePriceController.doubleValue;
  }

  bool get _hasChanges {
    return _newSalePrice != widget.product.salePrice ||
        _newPurchasePrice != widget.product.purchasePrice;
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: 'Editar Precios',
      icon: Icons.edit_rounded,
      width: 400,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DialogComponents.sectionSpacing,
            // Campos de precios
            _buildPriceFields(),
            DialogComponents.sectionSpacing,
            // Resumen de información siempre visible
            _buildChangesSummary(),
            DialogComponents.sectionSpacing,
          ],
        ),
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cancelar',
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        DialogComponents.primaryActionButton(
          context: context,
          text: 'Guardar',
          icon: Icons.check,
          onPressed: _isLoading || !_hasChanges ? null : _saveChanges,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildPriceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Precio de Compra
        MoneyInputTextField(
          controller: _purchasePriceController,
          labelText: 'Precio de Compra (Opcional)',
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final purchasePrice = _purchasePriceController.doubleValue;
              final salePrice = _salePriceController.doubleValue;

              if (purchasePrice < 0) {
                return 'El precio no puede ser negativo';
              }

              // Validar que el precio de compra no sea mayor al de venta si ambos están definidos
              if (purchasePrice > 0 &&
                  salePrice > 0 &&
                  purchasePrice > salePrice) {
                return 'El precio de compra no puede ser mayor al de venta';
              }
            }
            return null;
          },
          onTextChanged: (value) {
            setState(() {}); // Para actualizar el estado de los cambios
          },
        ),
        const SizedBox(height: 16),
        // Precio de Venta
        MoneyInputTextField(
          controller: _salePriceController,
          labelText: 'Precio de Venta al Público *',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El precio de venta es requerido';
            }
            final salePrice = _salePriceController.doubleValue;
            final purchasePrice = _purchasePriceController.doubleValue;

            if (salePrice <= 0) {
              return 'El precio debe ser mayor a 0';
            }

            // Validar que el precio de venta no sea menor al de compra si ambos están definidos
            if (purchasePrice > 0 &&
                salePrice > 0 &&
                salePrice < purchasePrice) {
              return 'El precio de venta no puede ser menor al de compra';
            }

            return null;
          },
          onTextChanged: (value) {
            setState(() {}); // Para actualizar el estado de los cambios
          },
        ),
      ],
    );
  }

  Widget _buildChangesSummary() {
    final theme = Theme.of(context);

    // Calcular porcentajes de ganancia
    final oldProfitMargin = _calculateProfitMargin(
        widget.product.salePrice, widget.product.purchasePrice);
    final newProfitMargin =
        _calculateProfitMargin(_newSalePrice, _newPurchasePrice);
    final hasProfitMarginChange = oldProfitMargin != newProfitMargin;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _hasChanges ? 'Resumen de cambios:' : 'Información actual:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),

          // Mostrar precios siempre
          if (_hasChanges) ...[
            // Modo cambios: mostrar valores antiguos y nuevos
            if (_newSalePrice != widget.product.salePrice)
              _buildChangeRow(
                'Venta',
                CurrencyFormatter.formatPrice(value: widget.product.salePrice),
                CurrencyFormatter.formatPrice(value: _newSalePrice),
              ),

            if (_newPurchasePrice != widget.product.purchasePrice)
              _buildChangeRow(
                'Compra',
                CurrencyFormatter.formatPrice(
                    value: widget.product.purchasePrice),
                CurrencyFormatter.formatPrice(value: _newPurchasePrice),
              ),

            // Mostrar cambio en porcentaje de ganancia si es relevante
            if (hasProfitMarginChange &&
                (_newPurchasePrice > 0 ||
                    widget.product.purchasePrice > 0)) ...[
              const SizedBox(height: 4),
              _buildProfitMarginRow(oldProfitMargin, newProfitMargin, theme),
            ],
          ] else ...[
            // Modo información: mostrar valores actuales
            _buildInfoRow('Venta',
                CurrencyFormatter.formatPrice(value: widget.product.salePrice)),
            if (widget.product.purchasePrice > 0)
              _buildInfoRow(
                  'Compra',
                  CurrencyFormatter.formatPrice(
                      value: widget.product.purchasePrice)),

            // Mostrar porcentaje de ganancia actual si hay precio de compra
            if (widget.product.purchasePrice > 0) ...[
              const SizedBox(height: 4),
              _buildInfoRow(
                'Ganancia',
                '${oldProfitMargin.toStringAsFixed(1)}%',
                valueColor: oldProfitMargin > 0
                    ? Colors.green
                    : theme.colorScheme.error,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildChangeRow(String label, String oldValue, String newValue) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            oldValue,
            style: theme.textTheme.bodySmall?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: theme.colorScheme.error,
            ),
          ),
          Text(
            ' → ',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            newValue,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Calcula el porcentaje de ganancia basado en el precio de venta y compra
  double _calculateProfitMargin(double salePrice, double purchasePrice) {
    if (purchasePrice <= 0 || salePrice <= 0) return 0;
    return ((salePrice - purchasePrice) / purchasePrice) * 100;
  }

  /// Construye la fila que muestra el cambio en el porcentaje de ganancia
  Widget _buildProfitMarginRow(
      double oldMargin, double newMargin, ThemeData theme) {
    final oldMarginText =
        oldMargin > 0 ? '${oldMargin.toStringAsFixed(1)}%' : 'N/A';
    final newMarginText =
        newMargin > 0 ? '${newMargin.toStringAsFixed(1)}%' : 'N/A';

    // Determinar el color basado en si la ganancia mejoró o empeoró
    Color? newValueColor;
    if (newMargin > oldMargin) {
      newValueColor = Colors.green; // Ganancia mejoró
    } else if (newMargin < oldMargin) {
      newValueColor = theme.colorScheme.error; // Ganancia empeoró
    } else {
      newValueColor = theme.colorScheme.primary; // Sin cambio significativo
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            'Ganancia: ',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            oldMarginText,
            style: theme.textTheme.bodySmall?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: theme.colorScheme.error,
            ),
          ),
          Text(
            ' → ',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            newMarginText,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: newValueColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una fila de información simple para mostrar valores actuales
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Validaciones adicionales antes de guardar
      final salePrice = _newSalePrice;
      final purchasePrice = _newPurchasePrice;

      // Validación final: Precio de venta obligatorio
      if (salePrice <= 0) {
        throw Exception('El precio de venta debe ser mayor a 0');
      }

      // Validación final: Precio de compra no puede ser negativo
      if (purchasePrice < 0) {
        throw Exception('El precio de compra no puede ser negativo');
      }

      // Validación final: Precio de compra no puede ser mayor al de venta
      if (purchasePrice > 0 && purchasePrice > salePrice) {
        throw Exception(
            'El precio de compra (${CurrencyFormatter.formatPrice(value: purchasePrice)}) no puede ser mayor al precio de venta (${CurrencyFormatter.formatPrice(value: salePrice)})');
      }

      // Obtener providers necesarios
      final sellProvider =
          provider_package.Provider.of<SellProvider>(context, listen: false);
      final catalogueProvider =
          widget.catalogueProvider; // Usar el provider pasado como parámetro

      // Obtener información de la cuenta
      final accountId = sellProvider.profileAccountSelected.id;
      final accountProfile = sellProvider.profileAccountSelected;

      if (accountId.isEmpty) {
        throw Exception('No se pudo obtener el ID de la cuenta');
      }

      // Crear producto actualizado
      // Obtener la cantidad actual del producto en el ticket si existe
      final currentQuantity = sellProvider.ticket.products
          .firstWhere((p) => p.id == widget.product.id,
              orElse: () => widget.product)
          .quantity;

      final updatedProduct = widget.product.copyWith(
        salePrice: salePrice,
        purchasePrice: purchasePrice,
        quantity: currentQuantity, // Preservar la cantidad del ticket
        upgrade: DateFormatter.getCurrentTimestamp(),
        documentIdUpgrade: accountId,
      );

      // Actualizar en el catálogo
      await catalogueProvider.addAndUpdateProductToCatalogue(
        updatedProduct,
        accountId,
        accountProfile: accountProfile,
      );

      // Actualizar en la lista de productos seleccionados si el producto está en el ticket
      sellProvider.addProductsticket(updatedProduct, replaceQuantity: true);

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Precios actualizados correctamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Llamar al callback y cerrar diálogo
        widget.onProductUpdated?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Log del error para debugging
      if (kDebugMode) {
        debugPrint('❌ Error al actualizar precios: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// Función helper para mostrar el diálogo de edición de precios
/// Sigue el patrón establecido en la arquitectura del proyecto
Future<void> showProductPriceEditDialog(
  BuildContext context, {
  required ProductCatalogue product,
  required CatalogueProvider catalogueProvider,
  VoidCallback? onProductUpdated,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false, // No se cierra al hacer click fuera
    builder: (context) => ProductPriceEditDialog(
      product: product,
      catalogueProvider: catalogueProvider,
      onProductUpdated: onProductUpdated,
    ),
  );
}
