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
                children: sortedMethods.map((entry) {
                  final percentage =
                      totalSales > 0 ? entry.value / totalSales : 0.0;

                  // Obtener información del método de pago desde el enum
                  final paymentMethod = PaymentMethod.fromCode(entry.key);
                  final displayName = paymentMethod.displayName;
                  final methodIcon = paymentMethod.icon;

                  return _buildPaymentMethodItem(
                    context,
                    methodIcon,
                    displayName,
                    entry.value,
                    percentage,
                    color,
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
    Color color,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                CurrencyHelper.formatCurrency(amount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: color.withValues(alpha: 0.15),
                    color: color,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 48,
                child: Text(
                  '${(percentage * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
