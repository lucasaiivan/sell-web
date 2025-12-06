import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'analytics_base_card.dart';
import 'analytics_modal.dart';

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
    // Obtener hasta 3 vendedores para preview
    final previewSellers = salesBySeller.take(3).toList();

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
          else ...[
            // Mostrar hasta 3 vendedores
            ...previewSellers.asMap().entries.map((entry) {
              final index = entry.key;
              final seller = entry.value;
              final sellerName =
                  seller['sellerName'] as String? ?? 'Sin nombre';
              final totalSales = seller['totalSales'] as double? ?? 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildSellerPreview(
                    context, sellerName, totalSales, index + 1),
              );
            }),
            const SizedBox(height: 2),
            // Contador de vendedores compacto
            Text(
              '$totalSellers vendedor${totalSellers != 1 ? 'es' : ''} 🏆',
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

  /// Preview del vendedor con posición
  Widget _buildSellerPreview(BuildContext context, String sellerName,
      double totalSales, int position) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
        // Sombra sutil para el vendedor #1
        boxShadow: isTopSeller
            ? [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Icono de medalla o número
          if (badgeIcon != null)
            Icon(
              badgeIcon,
              size: 14,
              color: badgeColor,
            )
          else
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$position',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 6),
          // Nombre del vendedor
          Expanded(
            child: Text(
              displayName,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Ventas compacto
          Text(
            CurrencyHelper.formatCurrency(totalSales),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
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

  static const _accentColor = Color(0xFF8B5CF6);

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
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: salesBySeller.length,
              itemBuilder: (context, index) {
                final seller = salesBySeller[index];
                final sellerName = seller['sellerName'] as String;
                final totalSales = seller['totalSales'] as double;
                final transactionCount = seller['transactionCount'] as int;
                final averageTicket = seller['averageTicket'] as double;
                final position = index + 1;

                return AnalyticsListItem(
                  position: position,
                  accentColor: _accentColor,
                  leading: _buildSellerAvatar(context, sellerName, position),
                  title: sellerName,
                  subtitleWidget: Row(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$transactionCount ventas',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.analytics_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Prom: ${CurrencyHelper.formatCurrency(averageTicket)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _accentColor,
                          ),
                    ),
                    Text(
                      'total vendido',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                );
              },
            ),
    );
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
