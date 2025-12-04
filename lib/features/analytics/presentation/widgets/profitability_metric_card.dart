import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';

/// Widget: Card de Métrica de Rentabilidad
///
/// **Responsabilidad:**
/// - Mostrar la ganancia total
/// - Mostrar el producto más rentable (avatar, descripción, ventas y ganancia)
/// - Abrir modal con los 10 productos más rentables al hacer tap
class ProfitabilityMetricCard extends StatelessWidget {
  /// Ganancia total
  final double totalProfit;

  /// Lista de productos más rentables con estadísticas
  /// Estructura: [{ 'product': ProductCatalogue, 'quantitySold': int, 'totalProfit': double, 'profitPerUnit': double }]
  final List<Map<String, dynamic>> mostProfitableProducts;

  /// Color de la tarjeta
  final Color color;

  /// Indica si no hay datos (cero)
  final bool isZero;

  /// Subtítulo opcional
  final String? subtitle;

  const ProfitabilityMetricCard({
    super.key,
    required this.totalProfit,
    required this.mostProfitableProducts,
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

    // Producto más rentable (si existe)
    final hasTopProduct = mostProfitableProducts.isNotEmpty;
    final topProduct = hasTopProduct
        ? mostProfitableProducts.first['product'] as ProductCatalogue
        : null;
    final topProductQuantity =
        hasTopProduct ? mostProfitableProducts.first['quantitySold'] as int : 0;
    final topProductProfit = hasTopProduct
        ? mostProfitableProducts.first['totalProfit'] as double
        : 0.0;

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
        onTap: hasTopProduct
            ? () => _showMostProfitableProductsModal(context)
            : null,
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
                          Icons.diamond_rounded,
                          color: iconColor,
                          size: iconSize,
                        ),
                      ),
                      SizedBox(width: padding * 0.8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Rentabilidad',
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

                  // --- Valor Principal (Ganancia Total) ---
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      CurrencyHelper.formatCurrency(totalProfit),
                      style: TextStyle(
                        color: valueColor,
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  // --- Producto más rentable ---
                  if (hasTopProduct && topProduct != null) ...[
                    const SizedBox(height: 8),
                    _buildTopProductPreview(
                      context,
                      topProduct,
                      topProductQuantity,
                      topProductProfit,
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

  /// Construye la vista previa del producto más rentable
  Widget _buildTopProductPreview(
    BuildContext context,
    ProductCatalogue product,
    int quantitySold,
    double totalProfit,
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
                      Icons.diamond_outlined,
                      size: 16,
                      color: textColor.withValues(alpha: 0.5),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          // Descripción, ventas y ganancia
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
                Row(
                  children: [
                    Text(
                      '$quantitySold uds',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: textColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '•',
                      style: TextStyle(
                        fontSize: 8,
                        color: textColor.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      CurrencyHelper.formatCurrency(totalProfit),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
            child: const Text(
              '💎',
              style: TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra el modal con los 10 productos más rentables
  void _showMostProfitableProductsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MostProfitableProductsModal(
        mostProfitableProducts: mostProfitableProducts.take(10).toList(),
      ),
    );
  }
}

/// Modal: Top 10 Productos Más Rentables
///
/// Muestra una lista detallada de los productos más rentables
/// con avatar, descripción, cantidad vendida y ganancia generada.
class MostProfitableProductsModal extends StatelessWidget {
  final List<Map<String, dynamic>> mostProfitableProducts;

  const MostProfitableProductsModal({
    super.key,
    required this.mostProfitableProducts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const accentColor = Color(0xFF10B981); // Verde esmeralda

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
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.diamond_rounded,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Rentables',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Los que más ganancias generan',
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
            child: mostProfitableProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.diamond_outlined,
                          size: 64,
                          color: colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay datos de rentabilidad',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Agrega precio de compra a tus productos',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: mostProfitableProducts.length,
                    itemBuilder: (context, index) {
                      final item = mostProfitableProducts[index];
                      final product = item['product'] as ProductCatalogue;
                      final quantitySold = item['quantitySold'] as int;
                      final totalProfit = item['totalProfit'] as double;
                      final profitPerUnit = item['profitPerUnit'] as double;
                      final position = index + 1;

                      return _buildProductItem(
                        context,
                        product,
                        quantitySold,
                        totalProfit,
                        profitPerUnit,
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
    double totalProfit,
    double profitPerUnit,
    int position,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const accentColor = Color(0xFF10B981);

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
                        Icons.diamond_outlined,
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
                  color: position <= 3 ? positionColor : accentColor,
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$position',
                    style: TextStyle(
                      color: position <= 3 ? Colors.black87 : Colors.white,
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
        subtitle: Row(
          children: [
            Text(
              product.nameMark.isNotEmpty
                  ? product.nameMark
                  : product.nameCategory,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '+${CurrencyHelper.formatCurrency(profitPerUnit)}/u',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Ganancia total
            Text(
              CurrencyHelper.formatCurrency(totalProfit),
              style: theme.textTheme.titleSmall?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            // Cantidad vendida
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$quantitySold vendidos',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
