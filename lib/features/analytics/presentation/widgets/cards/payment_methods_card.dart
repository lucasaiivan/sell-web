import 'package:flutter/material.dart';
import 'package:sellweb/core/constants/payment_methods.dart';
import 'package:sellweb/core/utils/helpers/currency_helper.dart';
import '../core/widgets.dart';

/// Widget: Tarjeta de Métodos de Pago
///
/// **Responsabilidad:**
/// - Mostrar desglose de pagos por método
/// - Visualizar porcentaje de cada método con barra de progreso
/// - Abrir modal con análisis detallado al hacer tap
///
/// **Usa:** [AnalyticsBaseCard] como base visual consistente
class PaymentMethodsCard extends StatelessWidget {
  final Map<String, double> paymentMethodsBreakdown;
  final double totalSales;

  /// Color de la tarjeta (debe venir del registro para consistencia)
  final Color color;

  /// Callback al hacer tap en la tarjeta
  final VoidCallback? onTap;

  /// Mostrar indicador de acción (chevron)
  final bool showActionIndicator;

  const PaymentMethodsCard({
    super.key,
    required this.paymentMethodsBreakdown,
    required this.totalSales,
    required this.color,
    this.onTap,
    this.showActionIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    // Ordenar métodos por monto descendente
    final allSortedMethods = paymentMethodsBreakdown.entries.toList()
      ..sort((a, b) {
        if (a.key.isEmpty) return 1;
        if (b.key.isEmpty) return -1;
        return b.value.compareTo(a.value);
      });

    // IMPORTANTE: Usar showActionIndicator que ya considera periodTotals.totalTransactions
    // Si showActionIndicator es false, significa que no hay transacciones en el período
    final hasNoData = allSortedMethods.isEmpty || !showActionIndicator;

    return AnalyticsBaseCard(
      color: color,
      isZero: hasNoData,
      icon: Icons.payment_rounded,
      title: 'Medios de Pago',
      expandChild: true, // Expandir para alinear desde abajo
      onTap: hasNoData ? null : onTap,
      showActionIndicator: !hasNoData && showActionIndicator,
      child: hasNoData
          ? const AnalyticsEmptyState(message: 'Sin pagos')
          : LayoutBuilder(
              builder: (context, constraints) {
                // Ajustar tamaños basado en el espacio disponible
                final isSmall = constraints.maxWidth < 300;
                final isCompact = constraints.maxWidth < 180;

                // Calcular dinámicamente cuántos métodos de pago mostrar
                // Altura del item: topMethod ~42px (compacto ~36px), otros ~32px (compacto ~28px)
                // Spacing: topMethod ~8px, otros ~6px
                const paddingTop = 12.0;

                // Usar altura dinámica ya que el primer item es más grande
                final visibleCount = DynamicItemsCalculator
                    .calculateVisibleItemsWithDynamicHeight(
                  availableHeight: constraints.maxHeight - paddingTop,
                  getItemHeight: (index) {
                    final isTop = index == 0;
                    final itemHeight = isTop
                        ? (isCompact ? 36.0 : 42.0)
                        : (isCompact ? 28.0 : 32.0);
                    final spacing = isTop ? 8.0 : 6.0;
                    return itemHeight + spacing;
                  },
                  itemSpacing: 0.0, // Ya incluido en getItemHeight
                  minItems: 1,
                  maxItems: allSortedMethods.length,
                );

                final sortedMethods =
                    allSortedMethods.take(visibleCount).toList();

                // Calcular el total real de los métodos de pago para porcentajes precisos
                final methodsTotal = sortedMethods.fold<double>(
                    0.0, (sum, entry) => sum + entry.value);
                final displayTotal =
                    methodsTotal > 0 ? methodsTotal : totalSales;

                return Padding(
                  padding: const EdgeInsets.only(top: paddingTop),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment:
                        MainAxisAlignment.end, // Alinear desde abajo
                    children: sortedMethods.asMap().entries.map((indexedEntry) {
                      final index = indexedEntry.key;
                      final entry = indexedEntry.value;
                      final isTopMethod = index == 0;

                      // Calcular porcentaje: monto del método / total de métodos de pago visibles
                      // Esto es más preciso que usar periodTotals.totalSales
                      double percentage = displayTotal > 0
                          ? (entry.value / displayTotal).clamp(0.0, 1.0)
                          : 0.0;

                      final paymentMethod = PaymentMethod.fromCode(entry.key);
                      final displayName = paymentMethod.displayName;
                      final methodIcon = paymentMethod.icon;
                      final methodColor = paymentMethod.color;
                      // Construir el ítem del método de pago
                      return _buildPaymentMethodItem(
                        context,
                        methodIcon,
                        displayName,
                        entry.value,
                        percentage,
                        methodColor,
                        isTopMethod: isTopMethod,
                        isSmall: isSmall,
                        isCompact: isCompact,
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPaymentMethodItem(
    BuildContext context,
    IconData icon,
    String name,
    double amount,
    double percentage,
    Color color, {
    bool isTopMethod = false,
    bool isSmall = false,
    bool isCompact = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Tamaños dinámicos
    final double itemHeight =
        isTopMethod ? (isCompact ? 36 : 42) : (isCompact ? 28 : 32);

    final double fontSize =
        isTopMethod ? (isCompact ? 12 : 14) : (isCompact ? 10 : 12);

    final double iconSize =
        isTopMethod ? (isCompact ? 16 : 20) : (isCompact ? 14 : 16);

    final double bottomPadding = isTopMethod ? 8.0 : 6.0;

    const textColor = Colors.white;
    const iconColor = Colors.white;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Fondo base (track)
            Container(
              height: itemHeight,
              width: double.infinity,
              color: color.withValues(alpha: isDark ? 0.3 : 0.4),
            ),
            // Barra de progreso (indicator)
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: itemHeight,
                  width: constraints.maxWidth * percentage,
                  color: color.withValues(alpha: isDark ? 0.8 : 0.9),
                );
              },
            ),
            // Contenido sobre la barra
            Container(
              height: itemHeight,
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12.0),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: iconSize,
                    color: iconColor,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  SizedBox(width: isCompact ? 6 : 10),
                  // Nombre del método
                  if (!isCompact || isTopMethod)
                    Expanded(
                      child: Text(
                        name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isTopMethod ? FontWeight.w700 : FontWeight.w600,
                          fontSize: fontSize,
                          color: textColor,
                          letterSpacing: 0.1,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )
                  else
                    const Spacer(),

                  SizedBox(width: isCompact ? 4 : 12),
                  // Monto facturado
                  Text(
                    CurrencyHelper.formatCurrency(amount),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isTopMethod ? FontWeight.w800 : FontWeight.w700,
                      fontSize: fontSize,
                      color: textColor,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
