import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'analytics_base_card.dart';
import 'analytics_modal.dart';

/// Widget: Tarjeta de Productos de Lenta Rotación
///
/// **Responsabilidad:**
/// - Mostrar productos con pocas ventas
/// - Alertar sobre inventario estancado
/// - Abrir modal con lista completa de productos lentos
///
/// **Propiedades:**
/// - [slowMovingProducts]: Lista de productos con baja rotación
/// - [color]: Color principal de la tarjeta
/// - [isZero]: Indica si no hay datos
/// - [subtitle]: Subtítulo opcional para modo desktop
class SlowMovingProductsCard extends StatelessWidget {
  final List<Map<String, dynamic>> slowMovingProducts;
  final Color color;
  final bool isZero;
  final String? subtitle;

  const SlowMovingProductsCard({
    super.key,
    required this.slowMovingProducts,
    this.color = const Color(0xFFEF4444),
    this.isZero = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final totalSlowProducts = slowMovingProducts.length;
    final hasData = !isZero && slowMovingProducts.isNotEmpty;
    // Obtener hasta 2 productos para preview
    final previewProducts = slowMovingProducts.take(2).toList();

    return AnalyticsBaseCard(
      color: color,
      isZero: isZero || slowMovingProducts.isEmpty,
      icon: Icons.warning_amber_rounded,
      title: 'Lenta Rotación',
      subtitle: subtitle,
      showActionIndicator: hasData,
      onTap: hasData ? () => _showSlowMovingModal(context) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            hasData ? MainAxisAlignment.end : MainAxisAlignment.center,
        children: [
          if (!hasData) ...[
            const Flexible(
              child: AnalyticsEmptyState(message: 'Sin alertas'),
            ),
          ] else ...[
            // Mostrar hasta 2 productos con lenta rotación
            ...previewProducts.map((productData) {
              final product = productData['product'] as ProductCatalogue;
              final quantitySold = productData['quantitySold'] as int? ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildSlowProductPreview(context, product, quantitySold),
              );
            }),
            const SizedBox(height: 2),
            // Badge de alerta compacto
            Text(
              '$totalSlowProducts producto${totalSlowProducts != 1 ? 's' : ''} ⚠️',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  /// Preview simplificado del producto con lenta rotación
  Widget _buildSlowProductPreview(
      BuildContext context, ProductCatalogue product, int quantitySold) {
    final theme = Theme.of(context);
    // Asegurar que siempre haya un nombre visible
    final productName = product.description.isNotEmpty
        ? product.description
        : product.nameMark.isNotEmpty
            ? product.nameMark
            : product.nameCategory.isNotEmpty
                ? product.nameCategory
                : 'Producto sin nombre';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icono de alerta pequeño
          Icon(
            Icons.trending_down_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          // Nombre del producto
          Expanded(
            child: Text(
              productName,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          // Cantidad vendida
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$quantitySold',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSlowMovingModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          SlowMovingProductsModal(slowMovingProducts: slowMovingProducts),
    );
  }
}

/// Modal: Lista Completa de Productos de Lenta Rotación
class SlowMovingProductsModal extends StatelessWidget {
  final List<Map<String, dynamic>> slowMovingProducts;

  const SlowMovingProductsModal({
    super.key,
    required this.slowMovingProducts,
  });

  static const _accentColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return AnalyticsModal(
      accentColor: _accentColor,
      icon: Icons.warning_amber_rounded,
      title: 'Productos de Lenta Rotación',
      subtitle: '${slowMovingProducts.length} productos con pocas ventas',
      infoWidget: AnalyticsInfoCard.tip(
        message:
            'Productos vendidos 5 o menos veces. Considera promociones o ajustes de precio.',
      ),
      child: slowMovingProducts.isEmpty
          ? const AnalyticsModalEmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: '¡Excelente!',
              subtitle: 'No tienes productos con lenta rotación',
              iconColor: Color(0xFF10B981),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: slowMovingProducts.length,
              itemBuilder: (context, index) {
                final productData = slowMovingProducts[index];
                final product = productData['product'] as ProductCatalogue;
                final quantitySold = productData['quantitySold'] as int;
                final totalRevenue = productData['totalRevenue'] as double;
                final lastSoldDate = productData['lastSoldDate'] as DateTime;

                // Calcular días desde última venta
                final daysSinceLastSale =
                    DateTime.now().difference(lastSoldDate).inDays;
                final dateFormat = DateFormat('dd/MM/yyyy');

                // Color y label de alerta basado en días sin vender
                Color alertColor;
                String alertLabel;
                IconData alertIcon;
                if (daysSinceLastSale > 30) {
                  alertColor = const Color(0xFFEF4444);
                  alertLabel = 'Crítico';
                  alertIcon = Icons.error_outline_rounded;
                } else if (daysSinceLastSale > 14) {
                  alertColor = const Color(0xFFF59E0B);
                  alertLabel = 'Atención';
                  alertIcon = Icons.warning_amber_rounded;
                } else {
                  alertColor = const Color(0xFF10B981);
                  alertLabel = 'Reciente';
                  alertIcon = Icons.schedule_rounded;
                }

                return AnalyticsListItem(
                  accentColor: alertColor,
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: alertColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: alertColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: product.image.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              product.image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.inventory_2_outlined,
                                color: alertColor,
                                size: 24,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.inventory_2_outlined,
                            color: alertColor,
                            size: 24,
                          ),
                  ),
                  title: product.description,
                  subtitleWidget: Row(
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$quantitySold vendido${quantitySold != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(lastSoldDate),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ),
                  trailingWidgets: [
                    AnalyticsBadge(
                      text: alertLabel,
                      color: alertColor,
                      icon: alertIcon,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyHelper.formatCurrency(totalRevenue),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
