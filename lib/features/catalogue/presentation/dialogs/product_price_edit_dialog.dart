import 'package:sellweb/core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/catalogue/presentation/providers/catalogue_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:provider/provider.dart' as provider_package;

/// Diálogo para editar precios de producto (precio de venta y precio de coste)
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

  /// Determina si el producto es un item de venta rápida (code vacío)
  bool get _isQuickItem => widget.product.code.isEmpty;

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
    if (_isQuickItem) {
      // Para items rápidos, solo verificar cambios en precio de venta
      return _newSalePrice != widget.product.salePrice;
    }
    // Para productos registrados, verificar ambos precios
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
          mainAxisSize: MainAxisSize.max,
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
    return DialogComponents.infoSection(
      context: context,
      title: 'Ajuste de Precios',
      icon: Icons.attach_money,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Para items rápidos: solo mostrar precio de venta
          if (_isQuickItem) ...[
            // Solo Precio de Venta para items rápidos
            DialogComponents.moneyField(
              context: context,
              controller: _salePriceController,
              label: 'Precio de Venta al Público *',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El precio de venta es requerido';
                }
                final salePrice = _salePriceController.doubleValue;

                if (salePrice <= 0) {
                  return 'El precio debe ser mayor a 0';
                }

                return null;
              },
              onChanged: (value) {
                setState(() {}); // Para actualizar el estado de los cambios
              },
            ),
          ] else ...[
            // Para productos registrados: mostrar ambos precios
            // Precio de Coste
            DialogComponents.moneyField(
              context: context,
              controller: _purchasePriceController,
              label: 'Precio de Coste (Opcional)',
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final purchasePrice = _purchasePriceController.doubleValue;
                  final salePrice = _salePriceController.doubleValue;

                  if (purchasePrice < 0) {
                    return 'El precio no puede ser negativo';
                  }

                  // Validar que el precio de coste no sea mayor al de venta si ambos están definidos
                  if (purchasePrice > 0 &&
                      salePrice > 0 &&
                      purchasePrice > salePrice) {
                    return 'El precio de coste no puede ser mayor al de venta';
                  }
                }
                return null;
              },
              onChanged: (value) {
                setState(() {}); // Para actualizar el estado de los cambios
              },
            ),
            const SizedBox(height: 16),
            // Precio de Venta
            DialogComponents.moneyField(
              context: context,
              controller: _salePriceController,
              label: 'Precio de Venta al Público *',
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
              onChanged: (value) {
                setState(() {}); // Para actualizar el estado de los cambios
              },
            ),
          ],
        ],
      ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined, 
                size: 20, 
                color: theme.colorScheme.onSurfaceVariant
              ),
              const SizedBox(width: 8),
              Text(
                'Resumen de Impacto',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // Badge de estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _hasChanges
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _hasChanges ? Icons.compare_arrows : Icons.check_circle_outline,
                      size: 14,
                      color: _hasChanges
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _hasChanges ? 'Modificado' : 'Sin cambios',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _hasChanges
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          DialogComponents.divider(context: context),
          const SizedBox(height: 16),

          // Información horizontal de precios
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
    
    // Si margin mejora, color verde, si empeora, rojo
    final isMarginBetter = newProfitMargin > oldProfitMargin;
    final isMarginWorse = newProfitMargin < oldProfitMargin;
    
    return Column(
      children: [
        // Comparativa Venta
        if (_newSalePrice != widget.product.salePrice)
          _buildComparisonRow(
            context: context,
            label: 'Precio Venta',
            oldValue: CurrencyFormatter.formatPrice(value: widget.product.salePrice),
            newValue: CurrencyFormatter.formatPrice(value: _newSalePrice),
            icon: Icons.sell_outlined,
          ),
          
        const SizedBox(height: 8),

        // Comparativa Coste
        if (_newPurchasePrice != widget.product.purchasePrice)
          _buildComparisonRow(
            context: context,
            label: 'Precio Coste',
            oldValue: CurrencyFormatter.formatPrice(value: widget.product.purchasePrice),
            newValue: CurrencyFormatter.formatPrice(value: _newPurchasePrice),
            icon: Icons.shopping_bag_outlined,
          ),
          
         const SizedBox(height: 8),

        // Comparativa Margen (solo si hay coste involucrado)
        if (oldProfitMargin != newProfitMargin &&
            (_newPurchasePrice > 0 || widget.product.purchasePrice > 0))
          _buildComparisonRow(
            context: context,
            label: 'Margen',
            oldValue: '${oldProfitMargin.toStringAsFixed(1)}%',
            newValue: '${newProfitMargin.toStringAsFixed(1)}%',
            icon: Icons.trending_up,
            isBetter: isMarginBetter,
            isWorse: isMarginWorse,
          ),
          
        if (!_isQuickItem && _newSalePrice == widget.product.salePrice && _newPurchasePrice == widget.product.purchasePrice)
           Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Ajusta los valores arriba',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHorizontalCurrent(ThemeData theme, double profitMargin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatColumn(
          context: context,
          label: 'Venta',
          value: CurrencyFormatter.formatPrice(value: widget.product.salePrice),
          icon: Icons.sell_outlined,
        ),
        if (widget.product.purchasePrice > 0) ...[
          Container(height: 30, width: 1, color: theme.colorScheme.outlineVariant),
          _buildStatColumn(
            context: context,
            label: 'Coste',
            value: CurrencyFormatter.formatPrice(value: widget.product.purchasePrice),
            icon: Icons.shopping_bag_outlined,
          ),
          Container(height: 30, width: 1, color: theme.colorScheme.outlineVariant),
          _buildStatColumn(
            context: context,
            label: 'Margen',
            value: '${profitMargin.toStringAsFixed(1)}%',
            icon: Icons.trending_up,
            valueColor: profitMargin > 0 ? Colors.green : theme.colorScheme.error,
          ),
        ],
      ],
    );
  }

  Widget _buildComparisonRow({
    required BuildContext context,
    required String label,
    required String oldValue,
    required String newValue,
    required IconData icon,
    bool? isBetter,
    bool? isWorse,
  }) {
    final theme = Theme.of(context);
    final valueColor = isBetter == true ? Colors.green : (isWorse == true ? theme.colorScheme.error : theme.colorScheme.primary);
    
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Text(
          oldValue,
          style: theme.textTheme.bodySmall?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: valueColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: valueColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            newValue,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
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

    // Validación adicional: el precio de coste no puede ser mayor al de venta
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

      // Validación final: Precio de coste no puede ser negativo
      if (purchasePrice < 0) {
        throw Exception('El precio de coste no puede ser negativo');
      }

      // Validación final: Precio de coste no puede ser mayor al de venta (solo para productos registrados)
      if (!_isQuickItem && purchasePrice > 0 && purchasePrice > salePrice) {
        throw Exception(
            'El precio de coste (${CurrencyFormatter.formatPrice(value: purchasePrice)}) no puede ser mayor al precio de venta (${CurrencyFormatter.formatPrice(value: salePrice)})');
      }

      // Obtener providers necesarios
      final sellProvider =
          provider_package.Provider.of<SalesProvider>(context, listen: false);

      // Obtener la cantidad actual del producto en el ticket si existe
      final currentQuantity = sellProvider.ticket.products
          .firstWhere((p) => p.id == widget.product.id,
              orElse: () => widget.product)
          .quantity;

      if (_isQuickItem) {
        // Para items rápidos: solo actualizar en la lista de productos seleccionados
        final updatedProduct = widget.product.copyWith(
          salePrice: salePrice,
          quantity: currentQuantity, // Preservar la cantidad del ticket
        );

        // Solo actualizar en la lista de productos seleccionados
        sellProvider.addProductsticket(updatedProduct, replaceQuantity: true);
      } else {
        // Para productos registrados: actualizar en catálogo y lista
        final catalogueProvider =
            widget.catalogueProvider; // Usar el provider pasado como parámetro

        // Obtener información de la cuenta
        final accountId = sellProvider.profileAccountSelected.id;
        final accountProfile = sellProvider.profileAccountSelected;

        if (accountId.isEmpty) {
          throw Exception('No se pudo obtener el ID de la cuenta');
        }

        // Crear producto actualizado
        final updatedProduct = widget.product.copyWith(
          salePrice: salePrice,
          purchasePrice: purchasePrice,
          quantity: currentQuantity, // Preservar la cantidad del ticket
          documentIdUpgrade: accountId,
        );

        // Actualizar en el catálogo (shouldUpdateUpgrade=true porque estamos editando precios)
        await catalogueProvider.addAndUpdateProductToCatalogue(
          updatedProduct,
          accountId,
          accountProfile: accountProfile,
          shouldUpdateUpgrade:
              true, // Actualizar upgrade porque cambiaron los precios
        );

        // Actualizar en la lista de productos seleccionados si el producto está en el ticket
        sellProvider.addProductsticket(updatedProduct, replaceQuantity: true);
      }

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        final uniqueKey = UniqueKey();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: uniqueKey,
            behavior: SnackBarBehavior.floating,
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
        ScaffoldMessenger.of(context).clearSnackBars();
        final uniqueKey = UniqueKey();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: uniqueKey,
            behavior: SnackBarBehavior.floating,
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
