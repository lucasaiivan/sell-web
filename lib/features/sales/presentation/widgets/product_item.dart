import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/core/presentation/widgets/combo_tag.dart';

class ProductItem extends StatefulWidget {
  final ProductCatalogue producto;

  const ProductItem({super.key, required this.producto});

  @override
  State<ProductItem> createState() => _ProductItemState();
}

class _ProductItemState extends State<ProductItem> {
  // Identifica si es un producto de venta rápida
  bool get _isQuickSaleProduct {
    return widget.producto.id.isEmpty ||
        widget.producto.id.startsWith('quick_') ||
        widget.producto.description.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final String alertStockText = widget.producto.stock
        ? (widget.producto.quantityStock >= 0
            ? widget.producto.quantityStock <= widget.producto.alertStock
                ? 'Stock bajo'
                : ''
            : 'Sin stock')
        : '';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // LAYOUT PRINCIPAL
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // IMAGEN DEL PRODUCTO
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _isQuickSaleProduct
                          ? _buildQuickSaleImage()
                          : ProductImage(
                              borderRadius: 0, 
                              imageUrl: widget.producto.image,
                              fit: BoxFit.cover,
                              productDescription: widget.producto.description,
                              maxAbbreviationChars: 2,
                            ),
                      
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (alertStockText.isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _buildMinimalistBadge(
                            alertStockText,
                            backgroundColor: Colors.red.shade400,
                          ),
                        ),

                      if (widget.producto.isCombo)
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          child: ComboTag(isCompact: true),
                        ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isQuickSaleProduct ? 'Venta Rápida' : widget.producto.description,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.formatPrice(value: widget.producto.salePrice),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (!_isQuickSaleProduct) ...[
                            const SizedBox(width: 2),
                            Text(
                              '/${widget.producto.unitSymbol}',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (widget.producto.quantity > 0)
              Positioned(
                top: 8,
                right: 8,
                child: _buildQuantityBadge(context),
              ),

            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => showProductEditDialog(
                    context,
                    producto: widget.producto,
                    onProductUpdated: () => setState(() {}),
                  ),
                  splashColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                  highlightColor: theme.colorScheme.primary.withValues(alpha: 0.02),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSaleImage() {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Center(
        child: Icon(
          Icons.bolt_rounded,
          size: 40,
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildMinimalistBadge(String text, {required Color backgroundColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildQuantityBadge(BuildContext context) {
    final theme = Theme.of(context);
    final isFractional = widget.producto.isFractionalUnit;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.producto.formattedQuantityWithUnit,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isFractional || widget.producto.quantity > 1)
            Text(
              CurrencyFormatter.formatPrice(value: widget.producto.totalPrice),
              style: TextStyle(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
