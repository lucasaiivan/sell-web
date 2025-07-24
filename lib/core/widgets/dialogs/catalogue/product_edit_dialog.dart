import 'package:flutter/material.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/core/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/base/standard_dialogs.dart';
import 'package:sellweb/core/widgets/dialogs/components/dialog_components.dart';
import 'package:sellweb/core/widgets/component/image.dart';
import 'package:sellweb/domain/entities/catalogue.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';
import 'package:provider/provider.dart' as provider_package;

/// Diálogo modernizado para editar productos en el ticket siguiendo Material Design 3
class ProductEditDialog extends StatefulWidget {
  const ProductEditDialog({
    super.key,
    required this.product,
    this.onProductUpdated,
  });

  final ProductCatalogue product;
  final VoidCallback? onProductUpdated;

  @override
  State<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<ProductEditDialog> {
  late int _quantity;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.product.quantity;
  }

  // Validaciones y propiedades calculadas
  String get _productName {
    if (widget.product.nameMark.isNotEmpty) return widget.product.nameMark;
    if (widget.product.description.isNotEmpty) {
      return widget.product.description.split(' ').take(2).join(' ');
    }
    return 'Producto';
  }

  String get _productDescription {
    return widget.product.description.isNotEmpty
        ? widget.product.description
        : 'Producto de venta rápida';
  }

  String get _productCode {
    return widget.product.code.isNotEmpty ? widget.product.code : 'Sin código';
  }

  bool get _isQuickSaleProduct {
    return widget.product.id.isEmpty || widget.product.id.startsWith('quick_');
  }

  double get _totalPrice {
    return widget.product.salePrice * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseDialog(
      title: _isQuickSaleProduct ? 'Venta Rápida' : 'Editar Producto',
      icon: _isQuickSaleProduct ? Icons.flash_on_rounded : Icons.edit_rounded,
      width: 450,
      headerColor:
          _isQuickSaleProduct ? theme.colorScheme.tertiaryContainer : null,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información principal del producto
          _buildProductInfo(),

          DialogComponents.sectionSpacing,

          // Controles de cantidad
          _buildQuantitySection(),

          DialogComponents.sectionSpacing,

          // Resumen del total
          DialogComponents.summaryContainer(
            context: context,
            value: Publications.getFormatoPrecio(value: _totalPrice),
            backgroundColor: Colors.transparent,
          ),
        ],
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Eliminar',
          icon: Icons.delete_outline_rounded,
          onPressed: _isProcessing ? null : _removeProduct,
        ),
        DialogComponents.primaryActionButton(
          context: context,
          text: 'Cerrar',
          icon: Icons.check_rounded,
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          isLoading: _isProcessing,
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return DialogComponents.infoSection(
      context: context,
      title: 'Información del Producto',
      icon: _isQuickSaleProduct
          ? Icons.flash_on_rounded
          : Icons.inventory_2_rounded,
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar o imagen del producto
          SizedBox(
            width: 80,
            height: 80,
            child: _isQuickSaleProduct
                ? Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.flash_on_rounded,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                      size: 40,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ProductImage(
                      imageUrl: widget.product.image,
                      size: 80,
                    ),
                  ),
          ),

          const SizedBox(width: 16),

          // Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre/marca del producto
                Text(
                  _productName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Descripción
                Text(
                  _productDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Código y precio
                Row(
                  children: [
                    DialogComponents.infoBadge(
                      context: context,
                      text: _productCode,
                      icon: Icons.qr_code_rounded,
                    ),
                    const SizedBox(width: 8),
                    DialogComponents.infoBadge(
                      context: context,
                      text: Publications.getFormatoPrecio(
                          value: widget.product.salePrice),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      textColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ],
                ),

                if (_isQuickSaleProduct) ...[
                  const SizedBox(height: 8),
                  DialogComponents.infoBadge(
                    context: context,
                    text: 'Venta Rápida',
                    icon: Icons.flash_on_rounded, 
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // view : selección de cantidad de unidades del producto
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Unidades',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón decrementar
                  _buildQuantityButton(
                    icon: Icons.remove_rounded,
                    onPressed: _quantity > 1
                        ? () => _updateQuantity(_quantity - 1)
                        : null,
                    isEnabled: _quantity > 1,
                  ),

                  // Cantidad actual
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_quantity',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Botón incrementar
                  _buildQuantityButton(
                    icon: Icons.add_rounded,
                    onPressed: () => _updateQuantity(_quantity + 1),
                    isEnabled: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isEnabled,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isEnabled
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.colorScheme.outline.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(
          icon,
          size: 20,
          color:
              isEnabled ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _updateQuantity(int newQuantity) {
    setState(() {
      _quantity = newQuantity;
      _isProcessing = true;
    });

    // Actualizar en el provider
    final sellProvider =
        provider_package.Provider.of<SellProvider>(context, listen: false);
    sellProvider.addProductsticket(
      widget.product.copyWith(quantity: newQuantity),
      replaceQuantity: true,
    );

    // Simular procesamiento breve
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        widget.onProductUpdated?.call();
      }
    });
  }

  Future<void> _removeProduct() async {
    // Mostrar confirmación antes de eliminar
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Eliminar Producto',
      message: '¿Estás seguro de que deseas eliminar este producto del ticket?',
      icon: Icons.delete_outline_rounded,
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isProcessing = true;
      });

      // Eliminar del provider
      final sellProvider =
          provider_package.Provider.of<SellProvider>(context, listen: false);
      sellProvider.removeProduct(widget.product);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onProductUpdated?.call();

        // Mostrar confirmación
        showInfoDialog(
          context: context,
          title: 'Producto Eliminado',
          message: 'El producto ha sido eliminado del ticket.',
          icon: Icons.check_circle_outline_rounded,
        );
      }
    }
  }
}

/// Helper function para mostrar el diálogo de edición de producto
Future<void> showProductEditDialog(
  BuildContext context, {
  required ProductCatalogue producto,
  VoidCallback? onProductUpdated,
}) {
  return showDialog(
    context: context,
    builder: (context) => ProductEditDialog(
      product: producto,
      onProductUpdated: onProductUpdated,
    ),
  );
}
