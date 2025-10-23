import 'package:sellweb/core/core.dart';
import 'package:flutter/material.dart';
import 'package:sellweb/presentation/widgets/dialogs/catalogue/product_price_edit_dialog.dart';
import 'package:sellweb/domain/entities/catalogue.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';
import 'package:sellweb/presentation/providers/catalogue_provider.dart';
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
  late int _quantity;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.product.quantity;
  }

  // Validaciones y propiedades calculadas
  String get _titleItem {
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
      title: 'Editar cantidad',
      icon: Icons.edit,
      width: 450,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información principal del producto
          _buildProductInfo(),
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
      icon: _itemCode.isNotEmpty ? null : Icons.flash_on_rounded,
      title: _itemCode.isNotEmpty ? 'Código: $_itemCode' : 'Venta Rápida',
      // iconbutton : botones personalizados de accion
      rightIcon: widget.product.local || widget.product.code.isEmpty
          ? null
          : IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                widget.product.favorite ? Icons.star : Icons.star_border,
                color: widget.product.favorite ? Colors.amber : null,
              ),
              onPressed: _isProcessing ? null : _toggleFavorite,
            ),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar o imagen del producto
          SizedBox(
            width: 80,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ProductImage(
                  imageUrl: widget.product.image,
                  size: 80,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre/marca del producto con verificación
                Row(
                  children: [
                    // Ícono de verificación si el producto está verificado
                    if (widget.product.verified) ...[
                      Icon(
                        Icons.verified,
                        size: 20,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Nombre del producto
                    _titleItem.isEmpty
                        ? const SizedBox()
                        : Expanded(
                            child: Text(
                              _titleItem,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: widget.product.verified
                                          ? Colors.blue
                                          : null,
                                      fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                  ],
                ),

                const SizedBox(height: 4),

                // Descripción
                Text(
                  _itemDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // badge : informacion adicional y accion de editar el precio
                Row(
                  children: [
                    // text : precio del producto
                    DialogComponents.infoBadge(
                      context: context,
                      text: CurrencyFormatter.formatPrice(
                          value: widget.product.salePrice),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      textColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    // textbutton : editar producto
                    TextButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              _editProductPrices();
                            },
                      icon: widget.product.code.isNotEmpty
                          ? const Icon(Icons.security, size: 18)
                          : null,
                      label: const Text('Editar'),
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

    return Column(
      children: [
        // view : cantidad de unidades del producto
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Spacer(),
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
        const SizedBox(height: 20),
        // Header con total destacado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Spacer(),
            // Contenedor destacado para el total
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1)),
              ),
              child: Text(
                'Total: ${CurrencyFormatter.formatPrice(value: _totalPrice)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onPrimaryContainer,
                  fontSize: 30,
                ),
              ),
            ),
          ],
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

  Future<void> _toggleFavorite() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Obtener el SellProvider
      final sellProvider =
          provider_package.Provider.of<SellProvider>(context, listen: false);

      // Obtener el ID de la cuenta
      final accountId = sellProvider.profileAccountSelected.id;

      if (accountId.isEmpty) {
        throw Exception('No se pudo obtener el ID de la cuenta');
      }

      // Cambiar el estado local primero para dar feedback inmediato
      final newFavoriteState = !widget.product.favorite;
      setState(() {
        widget.product.favorite = newFavoriteState;
      });

      // Actualizar en Firebase a través del provider pasado como parámetro
      await widget.catalogueProvider.updateProductFavorite(
        accountId,
        widget.product.id,
        newFavoriteState,
      );

      // Llamar al callback si existe
      widget.onProductUpdated?.call();
    } catch (e) {
      // Si hay error, revertir el cambio local
      setState(() {
        widget.product.favorite = !widget.product.favorite;
      });

      print('❌ Error al actualizar favorito: $e');

      // Mostrar mensaje de error al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
          provider_package.Provider.of<SellProvider>(context, listen: false);
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
