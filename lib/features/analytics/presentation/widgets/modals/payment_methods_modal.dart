import 'package:flutter/material.dart';
import 'package:sellweb/core/constants/payment_methods.dart';
import 'package:sellweb/core/utils/helpers/currency_helper.dart';
import 'package:sellweb/core/utils/helpers/number_helper.dart';
import 'package:sellweb/features/analytics/domain/entities/sales_analytics.dart';
import 'package:sellweb/features/analytics/domain/entities/date_filter.dart';
import '../core/widgets.dart';

/// Widget: Modal de Métodos de Pago
///
/// **Responsabilidad:**
/// - Mostrar desglose detallado de métodos de pago
/// - Visualizar porcentajes y estadísticas
/// - Comparar rendimiento entre métodos
class PaymentMethodsModal extends StatelessWidget {
  final SalesAnalytics analytics;
  final DateFilter? currentFilter;

  const PaymentMethodsModal({
    super.key,
    required this.analytics,
    this.currentFilter,
  });

  static const _accentColor = Color(0xFF64748B); // Gris Azulado

  String _getModalFeedback(List<MapEntry<String, double>> sortedMethods, double totalForPeriod) {
    if (sortedMethods.isEmpty) return 'Sin métodos de pago registrados';

    final methodsCount = sortedMethods.length;
    final topMethod = sortedMethods.first;
    final topPercentage = totalForPeriod > 0
        ? (topMethod.value / totalForPeriod * 100)
        : 0.0;

    if (methodsCount == 1) {
      return 'Aceptas un solo método de pago. Considera agregar más opciones para tus clientes.';
    } else if (topPercentage >= 70) {
      return 'Un método domina tus ventas. Promociona otros medios para mayor flexibilidad.';
    } else if (methodsCount >= 4) {
      return 'Ofreces variedad de medios de pago. Esto facilita la compra a tus clientes.';
    } else {
      return 'Buena diversificación de medios de pago. Mantiene opciones para todos tus clientes.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Obtener métodos de pago filtrados por fecha (si se proporcionó filtro)
    final paymentMethodsData = currentFilter != null
        ? analytics.getPaymentMethodsForFilter(currentFilter!)
        : analytics.paymentMethodsBreakdown;

    // Ordenar métodos por monto
    final sortedMethods = paymentMethodsData.entries.toList()
      ..sort((a, b) {
        if (a.key.isEmpty) return 1;
        if (b.key.isEmpty) return -1;
        return b.value.compareTo(a.value);
      });

    return AnalyticsModal(
      accentColor: _accentColor,
      icon: PaymentMethod.fromCode(sortedMethods.first.key).icon,
      title: 'Medios de Pago',
      subtitle: 'Análisis de métodos de pago',
      child: sortedMethods.isEmpty
          ? const AnalyticsModalEmptyState(
              icon: Icons.payment_rounded,
              title: 'Sin pagos registrados',
              subtitle: 'Realiza algunas ventas para ver el análisis',
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // Resumen : metodo mas usado y totales
                AnalyticsStatusCard(
                  statusColor: _accentColor,
                  icon: PaymentMethod.fromCode(sortedMethods.first.key).icon,
                  feedbackIcon: Icons.info_rounded,
                  feedbackText:
                    'El método más usado es ${PaymentMethod.fromCode(sortedMethods.first.key).displayName} con ${NumberHelper.formatPercentage(analytics.totalSales > 0 ? (sortedMethods.first.value / analytics.totalSales * 100) : 0.0)}',
                  showPlusSign: true,
                  mainValue: PaymentMethod.fromCode(sortedMethods.first.key).displayName,
                  mainLabel: 'Medio de pago más usado',
                  leftMetric: AnalyticsMetric(
                  value: CurrencyHelper.formatCurrency(sortedMethods.first.value),
                  label: 'Facturado',
                  ),
                  rightMetric: AnalyticsMetric(
                  value: '${analytics.paymentMethodsCount[sortedMethods.first.key] ?? 0}',
                  label: 'Transacciones',
                  ),
                ),
                const SizedBox(height: 16),
                // Feedback contextual
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
                        Icons.credit_card_rounded,
                        size: 16,
                        color: _accentColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getModalFeedback(
                            sortedMethods,
                            paymentMethodsData.values.fold(0.0, (sum, val) => sum + val),
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Lista detallada
                Text(
                  'Desglose por método',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...sortedMethods.map(
                  (entry) => _buildPaymentMethodDetail(context, entry),
                ),
              ],
            ),
    );
  }

  Widget _buildPaymentMethodDetail(
    BuildContext context,
    MapEntry<String, double> entry,
  ) {
    final paymentMethod = PaymentMethod.fromCode(entry.key);
    final methodColor = paymentMethod.color;
    final amount = entry.value;
    final count = analytics.paymentMethodsCount[entry.key] ?? 0;
    final percentage =
        analytics.totalSales > 0 ? (amount / analytics.totalSales * 100) : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnalyticsListItem(
          accentColor: methodColor,
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: methodColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              paymentMethod.icon,
              color: methodColor,
              size: 22,
            ),
          ),
          title: paymentMethod.displayName,
          subtitle: '$count transacción${count != 1 ? 'es' : ''}',
          trailingWidgets: [
            Text(
              CurrencyHelper.formatCurrency(amount),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold, 
                  ),
            ),
            const SizedBox(height: 2),
            AnalyticsBadge(
              text: NumberHelper.formatPercentage(percentage),
              color: methodColor,
            ),
          ],
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              backgroundColor: methodColor.withValues(alpha: 0.1),
              color: methodColor,
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}

/// Muestra el modal de métodos de pago
void showPaymentMethodsModal(BuildContext context, SalesAnalytics analytics, [DateFilter? currentFilter]) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PaymentMethodsModal(
      analytics: analytics,
      currentFilter: currentFilter,
    ),
  );
}
