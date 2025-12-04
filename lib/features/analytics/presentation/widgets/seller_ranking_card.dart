import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'analytics_base_card.dart';

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
    final topSeller = salesBySeller.isNotEmpty ? salesBySeller.first : null;
    final topSellerName = topSeller?['sellerName'] as String? ?? 'Sin datos';
    final topSellerSales = topSeller?['totalSales'] as double? ?? 0.0;
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Spacer(),
          if (!hasData)
            const AnalyticsEmptyState(message: 'Sin datos')
          else ...[
            // Vendedor top con badge
            _buildTopSellerPreview(context, topSellerName, topSellerSales),
            const SizedBox(height: 8),
            // Contador de vendedores
            Text(
              '$totalSellers vendedor${totalSellers != 1 ? 'es' : ''} activo${totalSellers != 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopSellerPreview(
      BuildContext context, String sellerName, double totalSales) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Badge de oro
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD700).withValues(alpha: 0.2),
              border: Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFD700),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          // Nombre y ventas
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sellerName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  CurrencyHelper.formatCurrency(totalSales),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Badge "Top"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '🏆',
              style: TextStyle(fontSize: 10),
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

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ranking de Vendedores',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${salesBySeller.length} vendedores activos',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista de vendedores
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: salesBySeller.length,
              itemBuilder: (context, index) {
                final seller = salesBySeller[index];
                final sellerName = seller['sellerName'] as String;
                final totalSales = seller['totalSales'] as double;
                final transactionCount = seller['transactionCount'] as int;
                final averageTicket = seller['averageTicket'] as double;

                return _buildSellerItem(
                  context: context,
                  position: index + 1,
                  sellerName: sellerName,
                  totalSales: totalSales,
                  transactionCount: transactionCount,
                  averageTicket: averageTicket,
                );
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSellerItem({
    required BuildContext context,
    required int position,
    required String sellerName,
    required double totalSales,
    required int transactionCount,
    required double averageTicket,
  }) {
    // Badge de posición con colores especiales para top 3
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
        badgeColor = Theme.of(context).colorScheme.surfaceContainerHighest;
        badgeIcon = null;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: position <= 3
            ? Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Badge de posición
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: position <= 3 ? 0.2 : 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: badgeIcon != null
                  ? Icon(badgeIcon, color: badgeColor, size: 22)
                  : Text(
                      '$position',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // Información del vendedor
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sellerName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Total vendido
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyHelper.formatCurrency(totalSales),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8B5CF6),
                    ),
              ),
              Text(
                'total vendido',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
