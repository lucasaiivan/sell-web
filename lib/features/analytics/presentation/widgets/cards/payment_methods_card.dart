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
    final sortedMethods = (paymentMethodsBreakdown.entries.toList()
          ..sort((a, b) {
            if (a.key.isEmpty) return 1;
            if (b.key.isEmpty) return -1;
            return b.value.compareTo(a.value);
          }))
        .take(4)
        .toList();

    final isEmpty = sortedMethods.isEmpty;

    return AnalyticsBaseCard(
      color: color,
      isZero: isEmpty,
      icon: Icons.payment_rounded,
      title: 'Medios de Pago',
      expandChild: false,
      onTap: onTap,
      showActionIndicator: showActionIndicator,
      child: isEmpty
          ? const AnalyticsEmptyState(message: 'No hay pagos registrados')
          : LayoutBuilder(
              builder: (context, constraints) {
                // Ajustar tamaños basado en el espacio disponible
                final isSmall = constraints.maxWidth < 300;
                final isCompact = constraints.maxWidth < 180;

                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: sortedMethods.asMap().entries.map((indexedEntry) {
                      final index = indexedEntry.key;
                      final entry = indexedEntry.value;
                      final isTopMethod = index == 0;
                      final percentage =
                          totalSales > 0 ? entry.value / totalSales : 0.0;

                      final paymentMethod = PaymentMethod.fromCode(entry.key);
                      final displayName = paymentMethod.displayName;
                      final methodIcon = paymentMethod.icon;
                      final methodColor = paymentMethod.color;

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
    final double itemHeight = isTopMethod
        ? (isCompact ? 36 : 42)
        : (isCompact ? 28 : 32);
    
    final double fontSize = isTopMethod
        ? (isCompact ? 12 : 14)
        : (isCompact ? 10 : 12);
        
    final double iconSize = isTopMethod
        ? (isCompact ? 16 : 20)
        : (isCompact ? 14 : 16);
        
    final double bottomPadding = isTopMethod ? 8.0 : 6.0;

    const textColor = Colors.white;
    const iconColor = Colors.white;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Barra de progreso
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withValues(alpha: isDark ? 0.3 : 0.4),
              color: color.withValues(alpha: isDark ? 0.8 : 0.9),
              minHeight: itemHeight,
            ),
            // Contenido sobre la barra
            Container(
              height: itemHeight,
              padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 8 : 12.0),
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
