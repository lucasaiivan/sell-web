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
    //  values
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBackgroundColor =
        isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white;

    final String alertStockText = widget.producto.stock
        ? (widget.producto.quantityStock >= 0
            ? widget.producto.quantityStock <= widget.producto.alertStock
                ? 'Stock bajo'
                : ''
            : 'Sin stock')
        : '';

    // aparición animada
    return Card(
      color: cardBackgroundColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // view : Si es venta rápida, mostrar solo precio centrado sino mostrar layout normal
          _isQuickSaleProduct
              ? _buildQuickSaleLayout()
              : _buildNormalLayout(alertStockText),
          // view : selección del producto
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                mouseCursor: MouseCursor.uncontrolled,
                onTap: () {
                  // Mostrar el diálogo de edición del producto usando la función reutilizable
                  showProductEditDialog(
                    context,
                    producto: widget.producto,
                    onProductUpdated: () {
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          ),
          // view : cantidad de productos seleccionados
          !(widget.producto.isFractionalUnit || widget.producto.quantity >= 2.0)
              ? Container()
              : Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          // Usar getter formateado con símbolo de unidad
                          widget.producto.formattedQuantityWithUnit,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatPrice(
                              value: widget.producto.totalPrice),
                          style: const TextStyle(
                            color: Colors.white, // O un tono amarillo/verde
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // WIDGETS COMPONETS

  /// Layout para productos de venta rápida - solo precio centrado
  Widget _buildQuickSaleLayout() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? theme.colorScheme.onSurface : Colors.black87;
    final overlayColor = isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.1)
        : Colors.grey.shade200.withValues(alpha: 0.2);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: overlayColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            CurrencyFormatter.formatPrice(value: widget.producto.salePrice),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22, // Precio más grande
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// Layout normal para productos con descripción
  Widget _buildNormalLayout(String alertStockText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // image : imagen del producto que ocupa parte de la tarjeta con alerta de stock superpuesta
        Expanded(
          flex: 2,
          child: Stack(
            children: [
              ProductImage(
                borderRadius: 12,
                imageUrl: widget.producto.image,
                fit: BoxFit.cover,
                productDescription: widget.producto.description,
              ),
              // view : alerta de stock bajo o sin stock
              if (alertStockText.isNotEmpty)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        alertStockText,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              // view : etiqueta de combo
                if (widget.producto.isCombo)
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: ComboTag(),
                  ),
            ],
          ),
        ),
        // view : información del producto
        contentInfo(),
      ],
    );
  }

  Widget contentInfo() {

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final descriptionColor = isDark ? theme.colorScheme.onSurfaceVariant : Colors.grey;
    final priceColor = isDark ? theme.colorScheme.onSurface : Colors.black;
    final unitColor = isDark ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7) : Colors.grey.shade600;
    
    final producto = widget.producto;
    final hasMultipleQuantity = producto.quantity > 1.0 || 
        (producto.isFractionalUnit && producto.quantity != 1.0);

    return producto.description == ''
        ? Container()
        : Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // text : nombre del producto
                Text(producto.description,
                    style: TextStyle(
                        fontWeight: FontWeight.normal,
                        color: descriptionColor,
                        overflow: TextOverflow.ellipsis),
                    maxLines: 1),
                // Precio unitario debajo de la descripción
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.formatPrice(value: producto.salePrice),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                        color: priceColor,
                      ),
                    ),
                    if (producto.salePrice == producto.totalPrice)
                      Text(
                        '/${producto.unitSymbol}',
                        style: TextStyle(
                          fontSize: 11.0,
                          color: unitColor,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
  }
}
