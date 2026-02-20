import 'package:sellweb/core/core.dart';
import 'package:flutter/material.dart';
import 'product_price_edit_dialog.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:sellweb/features/catalogue/presentation/providers/catalogue_provider.dart';
import 'package:sellweb/core/presentation/widgets/ui/quantity_selector.dart';
import 'package:provider/provider.dart' as provider_package;

/// Diálogo para editar producto seleccionado
class ProductEditDialog extends StatefulWidget {
  const ProductEditDialog({
    super.key,
    required this.product,
    required this.catalogueProvider,
    this.onProductUpdated,
  });

  final ProductCatalogue product;
  final CatalogueProvider catalogueProvider;
  final VoidCallback? onProductUpdated;

  @override
  State<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<ProductEditDialog> {
  late double _quantity;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.product.quantity;
  }

  // Validaciones y propiedades calculadas
  String get _titleItem {
    if (widget.product.isCombo) return '';
    if (widget.product.nameMark.isNotEmpty) return widget.product.nameMark;
    return '';
  }

  String get _itemDescription {
    return widget.product.description.isNotEmpty
        ? widget.product.description
        : 'Sin descripción';
  }

  String get _itemCode {
    return widget.product.code.isNotEmpty ? widget.product.code : '';
  }

  double get _totalPrice {
    return widget.product.salePrice * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: widget.product.isCombo ? 'Editar combo' : 'Editar cantidad',
      icon: Icons.edit,
      width: 450,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información principal del producto
          _buildProductInfo(),
           if (widget.product.isCombo)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _buildComboItemsList(),
            ),
          DialogComponents.sectionSpacing,
          // Controles de cantidad
          _buildQuantitySection(),
          DialogComponents.sectionSpacing,
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
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          isLoading: _isProcessing,
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return DialogComponents.infoSection(
      context: context,
      icon: _itemCode.isNotEmpty ? null : Icons.flash_on_rounded,
      title: _itemCode.isNotEmpty ? 'Código: $_itemCode' : 'Venta Rápida',
      rightIcon: widget.product.isSku || widget.product.code.isEmpty
          ? null
          : IconButton(
              style: IconButton.styleFrom(
                backgroundColor: widget.product.favorite
                    ? Colors.amber.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              icon: Icon(
                widget.product.favorite ? Icons.star : Icons.star_border,
                size: 20,
                color: widget.product.favorite
                    ? Colors.amber
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: _isProcessing ? null : _toggleFavorite,
            ),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ProductImage(
                imageUrl: widget.product.image,
                size: 80,
                productDescription: widget.product.description,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    if (widget.product.isVerified) ...[
                      const Icon(Icons.verified, size: 18, color: Colors.blue),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        _titleItem.isEmpty ? 'Producto' : _titleItem,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _itemDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    DialogComponents.infoBadge(
                      context: context,
                      text: CurrencyFormatter.formatPrice(
                          value: widget.product.salePrice),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      textColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      icon: Icons.attach_money,
                    ),
                    const SizedBox(width: 8),
                    // Action chip styled button for editing price
                    InkWell(
                      onTap: _isProcessing
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              _editProductPrices();
                            },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                         decoration: BoxDecoration(
                           borderRadius: BorderRadius.circular(20),
                           border: Border.all(
                             color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                           )
                         ),
                        child: Row(
                          children: [
                            if (widget.product.code.isNotEmpty) ...[
                               Icon(Icons.edit_outlined, 
                                size: 14, 
                                color: Theme.of(context).colorScheme.primary),
                               const SizedBox(width: 4),
                            ],
                            Text(
                              'Editar',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySection() {
    final theme = Theme.of(context);
    final formattedTotal = CurrencyFormatter.formatPrice(value: _totalPrice);

    return DialogComponents.infoSection(
      context: context,
      title: 'Ajustar Cantidad',
      icon: Icons.exposure,
      backgroundColor: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
      content: Column(
        children: [
          const SizedBox(height: 8),
          // view : quantity selector
          QuantitySelector(
            initialQuantity: _quantity,
            unit: widget.product.unit,
            onQuantityChanged: (newQuantity) {
              _updateQuantity(newQuantity);
            },
            showInput: true,
            showUnit: !widget.product.isCombo,
          ),
          const SizedBox(height: 20),
          DialogComponents.divider(context: context),
          const SizedBox(height: 16),
          // view : total price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Calculado',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              Text(
                formattedTotal,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComboItemsList() {
    return DialogComponents.itemList(
      context: context,
      title: 'Contenido del combo',
      items: widget.product.comboItems.map((item) {
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${item.quantity.toInt()}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
      useFillStyle: true,
      maxVisibleItems: 3,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
    );
  }

  void _updateQuantity(double newQuantity) {
    setState(() {
      _quantity = newQuantity;
      _isProcessing = true;
    });

    // Actualizar en el provider
    final sellProvider =
        provider_package.Provider.of<SalesProvider>(context, listen: false);
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

  Future<void> _toggleFavorite() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Obtener el SalesProvider
      final sellProvider =
          provider_package.Provider.of<SalesProvider>(context, listen: false);

      // Obtener el ID de la cuenta
      final accountId = sellProvider.profileAccountSelected.id;

      if (accountId.isEmpty) {
        throw Exception('No se pudo obtener el ID de la cuenta');
      }

      // Cambiar el estado de favorito
      final newFavoriteState = !widget.product.favorite;

      // Actualizar en Firebase a través del provider pasado como parámetro
      await widget.catalogueProvider.updateProductFavorite(
        accountId,
        widget.product.id,
        newFavoriteState,
      );

      // Llamar al callback si existe
      widget.onProductUpdated?.call();
    } catch (e) {
      // Mostrar mensaje de error al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        final uniqueKey = UniqueKey();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: uniqueKey,
            behavior: SnackBarBehavior.floating,
            content: Text('Error al actualizar favorito: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
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

  Future<void> _editProductPrices() async {
    if (_isProcessing) return;

    await showProductPriceEditDialog(
      context,
      product: widget.product,
      catalogueProvider: widget.catalogueProvider,
      onProductUpdated: widget.onProductUpdated,
    );
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
          provider_package.Provider.of<SalesProvider>(context, listen: false);
      sellProvider.removeProduct(widget.product);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onProductUpdated?.call();
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
  final catalogueProvider =
      provider_package.Provider.of<CatalogueProvider>(context, listen: false);

  return showDialog(
    context: context,
    barrierDismissible: true, // Permitir cerrar al hacer click fuera
    builder: (context) => ProductEditDialog(
      product: producto,
      catalogueProvider: catalogueProvider,
      onProductUpdated: onProductUpdated,
    ),
  );
}
