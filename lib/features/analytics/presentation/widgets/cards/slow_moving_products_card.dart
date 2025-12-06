import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import '../core/widgets.dart';

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
            const SizedBox(height: 6),
            // Feedback
            _buildFeedbackText(context, totalSlowProducts),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackText(BuildContext context, int totalSlowProducts) {
    final theme = Theme.of(context);
    String feedback;
    
    if (totalSlowProducts >= 20) {
      feedback = 'Mucho inventario estancado';
    } else if (totalSlowProducts >= 10) {
      feedback = 'Revisa tu inventario';
    } else if (totalSlowProducts >= 5) {
      feedback = 'Algunos productos lentos';
    } else {
      feedback = 'Pocas alertas de rotación';
    }
    
    return Text(
      feedback,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        fontSize: 11,
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

  static const _accentColor = AnalyticsColors.slowMoving; // Naranja/Ámbar

  String _getModalFeedback(int productsCount) {
    if (productsCount >= 20) {
      return 'Tienes mucho inventario estancado. Urgente: aplica descuentos o promociones para liberar stock.';
    } else if (productsCount >= 10) {
      return 'Varios productos con poca rotación. Considera ajustar precios o hacer promoción 2x1.';
    } else if (productsCount >= 5) {
      return 'Algunos productos se venden lento. Evaluar descuentos para mejorar rotación.';
    } else {
      return 'Pocas alertas de rotación. Tu inventario está bien optimizado.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: colorScheme.surface,
                  surfaceTintColor: colorScheme.surface,
                  expandedHeight: 180,
                  toolbarHeight: 80,
                  automaticallyImplyLeading: false,
                  titleSpacing: 0,
                  title: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _accentColor.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: _accentColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Lenta Rotación',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${slowMovingProducts.length} productos con pocas ventas',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 100, 20, 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _accentColor.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: _accentColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getModalFeedback(slowMovingProducts.length),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (slowMovingProducts.isEmpty)
                  const SliverFillRemaining(
                    child: AnalyticsModalEmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      title: '¡Excelente!',
                      subtitle: 'No tienes productos con lenta rotación',
                      iconColor: Color(0xFF10B981),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final productData = slowMovingProducts[index];
                        final product =
                            productData['product'] as ProductCatalogue;
                        final quantitySold = productData['quantitySold'] as int;
                        final totalRevenue =
                            productData['totalRevenue'] as double;
                        final lastSoldDate =
                            productData['lastSoldDate'] as DateTime;

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

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: AnalyticsListItem(
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$quantitySold vendido${quantitySold != 1 ? 's' : ''}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dateFormat.format(lastSoldDate),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: slowMovingProducts.length,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
