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
  bool get _isQuickSaleProduct => widget.producto.isQuickSale;

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
          // Fondo más diferenciado
          color: isDark 
              ? theme.colorScheme.surfaceContainer
              : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12), // Bordes un poco más redondeados para look moderno
          border: Border.all(
            color: isDark 
                ? theme.colorScheme.outline.withValues(alpha: 0.15)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8), // Sombra más suave y baja
              spreadRadius: -4,
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
                      // badge : stock alert
                      if (alertStockText.isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _buildMinimalistBadge(
                            alertStockText,
                            backgroundColor: Colors.red.shade400,
                          ),
                        ),
                    ],
                  ),
                ),
                // view : informacion del producto
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (_isQuickSaleProduct) ...[
                                Icon(
                                  Icons.bolt_rounded,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ), 
                              ],
                              // text : nombre del producto
                              Expanded(
                                child: Text(
                                  _isQuickSaleProduct && widget.producto.description.isEmpty ? 'Venta Rápida' : widget.producto.description,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // text : precio total
                              Text(
                                CurrencyFormatter.formatPrice(value: widget.producto.totalPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  letterSpacing: -0.5,
                                  height: 1.0,
                                ),
                              ),
                              // text : cantidad y unidad
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  '${widget.producto.quantity} ${widget.producto.unitSymbol}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (widget.producto.isCombo)
                      const Positioned(
                        top: -10,
                        left: 10,
                        child: ComboTag(isCompact: true),
                      ),
                  ],
                ),
              ],
            ),
            // badge : quantity
            if ( widget.producto.salePrice != widget.producto.totalPrice)
              Positioned(
                top: 8,
                right: 8,
                child: _buildPriceBadge(context),
              ), 
            // overlay : edit product
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => showProductEditDialog(
                    context,
                    producto: widget.producto,
                    onProductUpdated: () => setState(() {}),
                  ),
                  splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
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
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.2),
            colorScheme.primaryContainer.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Text(
          'VR',
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w900,
            color: colorScheme.primary.withValues(alpha: 0.05),
            letterSpacing: 4,
          ),
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

  Widget _buildPriceBadge(BuildContext context) {
    final theme = Theme.of(context); 
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
          CurrencyFormatter.formatSimplifiedPrice(value: widget.producto.salePrice),
          style: TextStyle(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
    );
  }
}
