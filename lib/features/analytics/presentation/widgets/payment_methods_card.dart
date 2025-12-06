import 'package:flutter/material.dart';
import 'package:sellweb/core/constants/payment_methods.dart';
import 'package:sellweb/core/utils/helpers/currency_helper.dart';
import 'analytics_base_card.dart';

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
    // Ordenar métodos por monto descendente, con 'Sin Especificar' (string vacío) al final
    final sortedMethods = paymentMethodsBreakdown.entries.toList()
      ..sort((a, b) {
        // String vacío (Sin Especificar) siempre va al final (retorna valor positivo)
        if (a.key.isEmpty) return 1;
        if (b.key.isEmpty) return -1;
        // Los demás se ordenan por monto descendente
        return b.value.compareTo(a.value);
      });

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
          : Padding(
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

                  // Obtener información del método de pago desde el enum
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
                  );
                }).toList(),
              ),
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
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Tamaños dinámicos: más grande para el método más usado, más pequeño para los demás
    final itemHeight = isTopMethod ? 42.0 : 32.0;
    final fontSize = isTopMethod ? 14.0 : 12.0;
    final iconSize = isTopMethod ? 20.0 : 16.0;
    final bottomPadding = isTopMethod ? 12.0 : 8.0;

    // Colores de texto e icono optimizados para contraste
    final textColor = theme.colorScheme.onSurface.withValues(alpha: isTopMethod ? 1.0 : 0.9);
    final iconColor = theme.colorScheme.onSurface.withValues(alpha: isTopMethod ? 1.0 : 0.8);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Barra de progreso - más prominente para el método más usado
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withValues(alpha: isDark ? 0.15 : 0.1),
              color: color.withValues(alpha: isDark ? 0.8 : 0.9),
              minHeight: itemHeight,
            ),
            // Contenido sobre la barra
            Container(
              height: itemHeight,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  // Icono
                  Icon(
                    icon,
                    size: iconSize,
                    color: iconColor,
                  ),
                  const SizedBox(width: 10),
                  // Nombre del método
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isTopMethod ? FontWeight.w700 : FontWeight.w600,
                        fontSize: fontSize,
                        color: textColor,
                        letterSpacing: 0.1,
                        shadows: [
                          Shadow(
                            color: theme.colorScheme.surface.withValues(alpha: 0.5),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Monto facturado
                  Text(
                    CurrencyHelper.formatCurrency(amount),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isTopMethod ? FontWeight.w800 : FontWeight.w700,
                      fontSize: fontSize,
                      color: textColor,
                      letterSpacing: 0.1,
                      shadows: [
                        Shadow(
                          color: theme.colorScheme.surface.withValues(alpha: 0.5),
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
