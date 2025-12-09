import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import '../core/widgets.dart';

/// Widget: Tarjeta de Ranking de Vendedores
///
/// **Responsabilidad:**
/// - Mostrar el vendedor con más ventas
/// - Abrir modal con ranking completo de vendedores
///
/// **Propiedades:**
/// - [salesBySeller]: Lista de vendedores con sus estadísticas
/// - [color]: Color principal de la tarjeta
/// - [isZero]: Indica si no hay datos
/// - [subtitle]: Subtítulo opcional para modo desktop
class SellerRankingCard extends StatelessWidget {
  final List<Map<String, dynamic>> salesBySeller;
  final Color color;
  final bool isZero;
  final String? subtitle;

  const SellerRankingCard({
    super.key,
    required this.salesBySeller,
    this.color = const Color(0xFF8B5CF6),
    this.isZero = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final totalSellers = salesBySeller.length;
    final hasData = !isZero && salesBySeller.isNotEmpty;

    return AnalyticsBaseCard(
      color: color,
      isZero: isZero || salesBySeller.isEmpty,
      icon: Icons.emoji_events_rounded,
      title: 'Vendedores',
      subtitle: subtitle,
      showActionIndicator: hasData,
      onTap: hasData ? () => _showSellerRankingModal(context) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            hasData ? MainAxisAlignment.end : MainAxisAlignment.center,
        children: [
          if (!hasData)
            const Flexible(child: AnalyticsEmptyState(message: 'Sin datos'))
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 180;

                // Calcular dinámicamente cuántos vendedores mostrar
                // Altura estimada: item ~32px (compacto ~28px), spacing ~4px, feedback ~24px
                final itemHeight = isCompact ? 28.0 : 32.0;
                const itemSpacing = 4.0;
                const feedbackHeight = 30.0; // Incluye SizedBox(6) + text

                // Determinar si hay espacio para mostrar el feedback
                final showFeedback = constraints.maxHeight > 100 && !isCompact;

                final visibleCount =
                    DynamicItemsCalculator.calculateVisibleItems(
                  availableHeight: constraints.maxHeight,
                  itemHeight: itemHeight,
                  itemSpacing: itemSpacing,
                  minItems: 1,
                  maxItems: salesBySeller.length,
                  reservedHeight: showFeedback ? feedbackHeight : 0,
                );

                final previewSellers =
                    salesBySeller.take(visibleCount).toList();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mostrar vendedores según el espacio disponible
                    ...previewSellers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final seller = entry.value;
                      final sellerName =
                          seller['sellerName'] as String? ?? 'Sin nombre';
                      final totalSales = seller['totalSales'] as double? ?? 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _buildSellerPreview(context, sellerName,
                            totalSales, index + 1, isCompact),
                      );
                    }),

                    if (showFeedback) ...[
                      const SizedBox(height: 6),
                      // Feedback
                      _buildFeedbackText(context, totalSellers),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFeedbackText(BuildContext context, int totalSellers) {
    final theme = Theme.of(context);
    String feedback;

    if (totalSellers >= 5) {
      feedback = 'Equipo grande trabajando';
    } else if (totalSellers >= 3) {
      feedback = 'Buen equipo de ventas';
    } else if (totalSellers == 2) {
      feedback = 'Equipo compacto y efectivo';
    } else {
      feedback = 'Operación individual';
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

  /// Preview del vendedor con posición
  Widget _buildSellerPreview(BuildContext context, String sellerName,
      double totalSales, int position, bool isCompact) {
    final theme = Theme.of(context);
    // Asegurar que siempre haya un nombre visible
    final displayName =
        sellerName.isNotEmpty ? sellerName : 'Vendedor $position';

    // Destacar vendedor #1 (o único)
    final isTopSeller = position == 1;

    // Colores para las posiciones
    Color badgeColor;
    IconData? badgeIcon;
    switch (position) {
      case 1:
        badgeColor = const Color(0xFFFFD700); // Oro
        badgeIcon = Icons.workspace_premium_rounded;
        break;
      case 2:
        badgeColor = const Color(0xFFC0C0C0); // Plata
        badgeIcon = Icons.workspace_premium_rounded;
        break;
      case 3:
        badgeColor = const Color(0xFFCD7F32); // Bronce
        badgeIcon = Icons.workspace_premium_rounded;
        break;
      default:
        badgeColor = color;
        badgeIcon = null;
    }

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 8, vertical: isCompact ? 3 : 5),
      decoration: BoxDecoration(
        // Destacar vendedor #1 con gradiente dorado
        gradient: isTopSeller
            ? LinearGradient(
                colors: [
                  badgeColor.withValues(alpha: 0.2),
                  badgeColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isTopSeller
            ? null
            : theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTopSeller
              ? badgeColor.withValues(alpha: 0.5)
              : color.withValues(alpha: 0.2),
          width: isTopSeller ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icono de medalla o número
          if (badgeIcon != null)
            Icon(
              badgeIcon,
              size: isCompact ? 12 : 14,
              color: badgeColor,
            )
          else
            Container(
              width: isCompact ? 12 : 14,
              height: isCompact ? 12 : 14,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$position',
                  style: TextStyle(
                    fontSize: isCompact ? 7 : 8,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 4),
          // Nombre del vendedor
          Expanded(
            child: Text(
              displayName,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                fontSize: isCompact ? 10 : 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isCompact) const SizedBox(width: 4),

          // Ventas compacto
          Text(
            CurrencyHelper.formatCurrency(totalSales),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: isCompact ? 8 : 9,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showSellerRankingModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SellerRankingModal(salesBySeller: salesBySeller),
    );
  }
}

/// Modal: Ranking Completo de Vendedores
class SellerRankingModal extends StatelessWidget {
  final List<Map<String, dynamic>> salesBySeller;

  const SellerRankingModal({
    super.key,
    required this.salesBySeller,
  });

  static const _accentColor = AnalyticsColors.sellerRanking; // Amarillo Oro

  @override
  Widget build(BuildContext context) {
    return AnalyticsModal(
      accentColor: _accentColor,
      icon: Icons.emoji_events_rounded,
      title: 'Ranking de Vendedores',
      subtitle: '${salesBySeller.length} vendedores activos',
      child: salesBySeller.isEmpty
          ? const AnalyticsModalEmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No hay vendedores',
              subtitle: 'Aún no hay datos de vendedores',
            )
          : Column(
              children: [
                // widget : Feedback sobre el equipo de ventas
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AnalyticsFeedbackBanner(
                    icon: Icon(Icons.people_rounded),
                    message: _getModalFeedback(salesBySeller),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: salesBySeller.length,
                    itemBuilder: (context, index) {
                      final seller = salesBySeller[index];
                      final sellerName = seller['sellerName'] as String;
                      final totalSales = seller['totalSales'] as double;
                      final transactionCount =
                          seller['transactionCount'] as int;
                      final averageTicket = seller['averageTicket'] as double;
                      final position = index + 1;

                      return AnalyticsListItem(
                        position: position,
                        accentColor: _accentColor,
                        leading:
                            _buildSellerAvatar(context, sellerName, position),
                        title: sellerName,
                        subtitleWidget: Row(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$transactionCount ventas',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.analytics_rounded,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Prom: ${CurrencyHelper.formatCurrency(averageTicket)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                        trailingWidgets: [
                          Text(
                            CurrencyHelper.formatCurrency(totalSales),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _accentColor,
                                ),
                          ),
                          Text(
                            'total vendido',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  String _getModalFeedback(List<Map<String, dynamic>> salesBySeller) {
    final sellersCount = salesBySeller.length;

    if (sellersCount >= 5) {
      return 'Tienes un equipo grande. Motívalos con metas y reconocimientos para mejorar resultados.';
    } else if (sellersCount >= 3) {
      return 'Tu equipo está bien dimensionado. Capacítalos para maximizar su potencial.';
    } else if (sellersCount == 2) {
      return 'Equipo compacto. Considera agregar más vendedores para crecer las ventas.';
    } else {
      return 'Operas solo. Considera incorporar personal para escalar tu negocio.';
    }
  }

  Widget _buildSellerAvatar(
      BuildContext context, String sellerName, int position) {
    final colorScheme = Theme.of(context).colorScheme;

    // Colores para top 3
    Color? badgeColor;
    if (position == 1) {
      badgeColor = const Color(0xFFFFD700);
    } else if (position == 2) {
      badgeColor = const Color(0xFFC0C0C0);
    } else if (position == 3) {
      badgeColor = const Color(0xFFCD7F32);
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _accentColor.withValues(alpha: 0.1),
        border: Border.all(
          color: badgeColor?.withValues(alpha: 0.5) ??
              colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: position <= 3
            ? Icon(
                Icons.workspace_premium_rounded,
                color: badgeColor,
                size: 24,
              )
            : Text(
                sellerName.isNotEmpty
                    ? sellerName.substring(0, 1).toUpperCase()
                    : '?',
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
