import 'package:sellweb/core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
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
      title: 'Editar precios',
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // descripción del producto 
          Text(
            widget.product.description,
            style: theme.textTheme.titleMedium,
          ),
          // Título compacto
          Row(
            children: [
              Icon(
                _hasChanges ? Icons.compare_arrows : Icons.info_outline,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _hasChanges ? 'Cambios' : 'Actual',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Información horizontal
          if (_hasChanges) ...[
            _buildHorizontalChanges(theme, oldProfitMargin, newProfitMargin),
          ] else ...[
            _buildHorizontalCurrent(theme, oldProfitMargin),
          ],
        ],
      ),
    );
  }

  Widget _buildHorizontalChanges(
      ThemeData theme, double oldProfitMargin, double newProfitMargin) {
    final items = <Widget>[];

    // Precio de venta
    if (_newSalePrice != widget.product.salePrice) {
      items.add(_buildCompactChangeItem(
        'Venta',
        CurrencyFormatter.formatPrice(value: widget.product.salePrice),
        CurrencyFormatter.formatPrice(value: _newSalePrice),
        theme,
      ));
    }

    // Precio de compra
    if (_newPurchasePrice != widget.product.purchasePrice) {
      items.add(_buildCompactChangeItem(
        'Compra',
        CurrencyFormatter.formatPrice(value: widget.product.purchasePrice),
        CurrencyFormatter.formatPrice(value: _newPurchasePrice),
        theme,
      ));
    }

    // Ganancia
    if (oldProfitMargin != newProfitMargin &&
        (_newPurchasePrice > 0 || widget.product.purchasePrice > 0)) {
      final oldMarginText = oldProfitMargin > 0
          ? '${oldProfitMargin.toStringAsFixed(1)}%'
          : 'N/A';
      final newMarginText = newProfitMargin > 0
          ? '${newProfitMargin.toStringAsFixed(1)}%'
          : 'N/A';

      items.add(_buildCompactChangeItem(
        'Ganancia',
        oldMarginText,
        newMarginText,
        theme,
        newValueColor: newProfitMargin > oldProfitMargin
            ? Colors.green
            : newProfitMargin < oldProfitMargin
                ? theme.colorScheme.error
                : null,
      ));
    }

    return Wrap(
      spacing: 24,
      runSpacing: 8,
      children: items,
    );
  }

  Widget _buildHorizontalCurrent(ThemeData theme, double profitMargin) {
    final items = <Widget>[
      _buildCompactCurrentItem(
          'Venta',
          CurrencyFormatter.formatPrice(value: widget.product.salePrice),
          theme),
    ];

    if (widget.product.purchasePrice > 0) {
      items.add(_buildCompactCurrentItem(
          'Compra',
          CurrencyFormatter.formatPrice(value: widget.product.purchasePrice),
          theme));
      items.add(_buildCompactCurrentItem(
        'Ganancia',
        '${profitMargin.toStringAsFixed(1)}%',
        theme,
        valueColor: profitMargin > 0 ? Colors.green : theme.colorScheme.error,
      ));
    }

    return Wrap(
      spacing: 24,
      runSpacing: 8,
      children: items,
    );
  }

  Widget _buildCompactChangeItem(
    String label,
    String oldValue,
    String newValue,
    ThemeData theme, {
    Color? newValueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              oldValue,
              style: theme.textTheme.bodySmall?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.arrow_forward,
                size: 12,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              newValue,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: newValueColor ?? theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactCurrentItem(String label, String value, ThemeData theme,
      {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// Calcula el porcentaje de ganancia basado en el precio de venta y compra
  /// Retorna el margen de ganancia: ((venta - compra) / venta) * 100
  double _calculateProfitMargin(double salePrice, double purchasePrice) {
    if (purchasePrice <= 0 || salePrice <= 0) return 0;

    // Validación adicional: el precio de compra no puede ser mayor al de venta
    if (purchasePrice >= salePrice) return 0;

    // Calcular margen de ganancia: (ganancia / precio_venta) * 100
    return ((salePrice - purchasePrice) / salePrice) * 100;
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
