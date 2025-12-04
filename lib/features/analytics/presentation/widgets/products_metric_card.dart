import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';

/// Widget: Card de Métrica de Productos
///
/// **Responsabilidad:**
/// - Mostrar el total de productos vendidos
/// - Mostrar el producto más vendido (avatar y descripción)
/// - Abrir modal con los 10 productos más vendidos al hacer tap
class ProductsMetricCard extends StatelessWidget {
  /// Total de productos vendidos
  final int totalProducts;

  /// Lista de productos más vendidos con estadísticas
  /// Estructura: [{ 'product': ProductCatalogue, 'quantitySold': int, 'totalRevenue': double }]
  final List<Map<String, dynamic>> topSellingProducts;

  /// Color de la tarjeta
  final Color color;

  /// Indica si no hay datos (cero)
  final bool isZero;

  /// Subtítulo opcional
  final String? subtitle;

  const ProductsMetricCard({
    super.key,
    required this.totalProducts,
    required this.topSellingProducts,
    required this.color,
    this.isZero = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Sistema de colores Material 3 con tinte de la métrica
    final effectiveColor = isZero ? theme.colorScheme.onSurfaceVariant : color;

    final containerColor = isZero
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
        : (isDark
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.08));

    final onContainerColor = theme.colorScheme.onSurface;

    final iconContainerColor = isZero
        ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
        : color.withValues(alpha: 0.2);

    final iconColor =
        isZero ? theme.colorScheme.onSurface.withValues(alpha: 0.38) : color;

    final valueColor = isZero
        ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
        : onContainerColor;

    // Producto más vendido (si existe)
    final hasTopProduct = topSellingProducts.isNotEmpty;
    final topProduct = hasTopProduct
        ? topSellingProducts.first['product'] as ProductCatalogue
        : null;
    final topProductQuantity =
        hasTopProduct ? topSellingProducts.first['quantitySold'] as int : 0;

    return Card(
      elevation: 0,
      color: containerColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isZero
              ? theme.colorScheme.outline.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            hasTopProduct ? () => _showTopSellingProductsModal(context) : null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final minDim = w < h ? w : h;

            final padding = (minDim * 0.05).clamp(12.0, 24.0);
            final iconSize = (minDim * 0.01).clamp(20.0, 32.0);
            final iconBoxSize = (iconSize * 1).clamp(36.0, 56.0);
            final titleSize = (w * 0.08).clamp(12.0, 16.0);
            final subtitleSize = (w * 0.05).clamp(10.0, 13.0);

            final estimatedHeaderH = iconBoxSize;
            final estimatedFooterH = subtitle != null ? 20.0 : 0.0;
            final availableH =
                h - (padding * 2) - estimatedHeaderH - estimatedFooterH;
            final valueSizeHeightBase = availableH * 0.5;
            final valueFontSize = valueSizeHeightBase.clamp(24.0, 48.0);

            return Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header: Icono y Título ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: iconBoxSize,
                        height: iconBoxSize,
                        decoration: BoxDecoration(
                          color: iconContainerColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.inventory_2_rounded,
                          color: iconColor,
                          size: iconSize,
                        ),
                      ),
                      SizedBox(width: padding * 0.8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Productos',
                            style: TextStyle(
                              color: onContainerColor.withValues(alpha: 0.8),
                              fontSize: titleSize,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      // Indicador de que es clickeable
                      if (hasTopProduct)
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: onContainerColor.withValues(alpha: 0.4),
                        ),
                    ],
                  ),

                  const Spacer(),

                  // --- Valor Principal ---
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      totalProducts.toString(),
                      style: TextStyle(
                        color: valueColor,
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  // --- Producto más vendido ---
                  if (hasTopProduct && topProduct != null) ...[
                    const SizedBox(height: 8),
                    _buildTopProductPreview(
                      context,
                      topProduct,
                      topProductQuantity,
                      onContainerColor,
                      effectiveColor,
                    ),
                  ] else if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: onContainerColor.withValues(alpha: 0.6),
                        fontSize: subtitleSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Construye la vista previa del producto más vendido
  Widget _buildTopProductPreview(
    BuildContext context,
    ProductCatalogue product,
    int quantitySold,
    Color textColor,
    Color accentColor,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar del producto
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: product.image.isNotEmpty
                  ? ProductImage(
                      imageUrl: product.image,
                      size: 32,
                      borderRadius: 16,
                    )
                  : Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: textColor.withValues(alpha: 0.5),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          // Descripción y cantidad
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.description,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$quantitySold vendidos',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Badge "Top"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '🏆',
              style: TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra el modal con los 10 productos más vendidos
  void _showTopSellingProductsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TopSellingProductsModal(
        topSellingProducts: topSellingProducts.take(10).toList(),
      ),
    );
  }
}

/// Modal: Top 10 Productos Más Vendidos
///
/// Muestra una lista detallada de los productos más vendidos
/// con avatar, descripción, cantidad vendida e ingresos generados.
class TopSellingProductsModal extends StatelessWidget {
  final List<Map<String, dynamic>> topSellingProducts;

  const TopSellingProductsModal({
    super.key,
    required this.topSellingProducts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFD97706),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Productos',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Los más vendidos del período',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista de productos
          Expanded(
            child: topSellingProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay productos vendidos',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: topSellingProducts.length,
                    itemBuilder: (context, index) {
                      final item = topSellingProducts[index];
                      final product = item['product'] as ProductCatalogue;
                      final quantitySold = item['quantitySold'] as int;
                      final totalRevenue = item['totalRevenue'] as double;
                      final position = index + 1;

                      return _buildProductItem(
                        context,
                        product,
                        quantitySold,
                        totalRevenue,
                        position,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    ProductCatalogue product,
    int quantitySold,
    double totalRevenue,
    int position,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Colores para posiciones top
    Color? positionColor;
    if (position == 1) {
      positionColor = const Color(0xFFFFD700); // Oro
    } else if (position == 2) {
      positionColor = const Color(0xFFC0C0C0); // Plata
    } else if (position == 3) {
      positionColor = const Color(0xFFCD7F32); // Bronce
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: position <= 3
            ? positionColor?.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: position <= 3
              ? positionColor!.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            // Avatar del producto
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: position <= 3
                      ? positionColor!.withValues(alpha: 0.5)
                      : colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: product.image.isNotEmpty
                    ? ProductImage(
                        imageUrl: product.image,
                        size: 48,
                        borderRadius: 24,
                      )
                    : Icon(
                        Icons.inventory_2_outlined,
                        size: 24,
                        color: colorScheme.onSurfaceVariant,
                      ),
              ),
            ),
            // Badge de posición
            Positioned(
              top: -4,
              left: -4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: position <= 3 ? positionColor : colorScheme.primary,
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$position',
                    style: TextStyle(
                      color: position <= 3
                          ? Colors.black87
                          : colorScheme.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          product.description,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          product.nameMark.isNotEmpty ? product.nameMark : product.nameCategory,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Cantidad vendida
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$quantitySold uds',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFD97706),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Ingresos
            Text(
              CurrencyHelper.formatCurrency(totalRevenue),
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF059669),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
