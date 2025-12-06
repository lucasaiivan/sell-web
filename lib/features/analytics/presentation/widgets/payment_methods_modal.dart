import 'package:flutter/material.dart';
import 'package:sellweb/core/constants/payment_methods.dart';
import 'package:sellweb/core/utils/helpers/currency_helper.dart';
import 'package:sellweb/features/analytics/domain/entities/sales_analytics.dart';
import 'analytics_modal.dart';

/// Widget: Modal de Métodos de Pago
///
/// **Responsabilidad:**
/// - Mostrar desglose detallado de métodos de pago
/// - Visualizar porcentajes y estadísticas
/// - Comparar rendimiento entre métodos
class PaymentMethodsModal extends StatelessWidget {
  final SalesAnalytics analytics;

  const PaymentMethodsModal({
    super.key,
    required this.analytics,
  });

  static const _accentColor = Color(0xFF0EA5E9);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Ordenar métodos por monto
    final sortedMethods = analytics.paymentMethodsBreakdown.entries.toList()
      ..sort((a, b) {
        if (a.key.isEmpty) return 1;
        if (b.key.isEmpty) return -1;
        return b.value.compareTo(a.value);
      });

    return AnalyticsModal(
      accentColor: _accentColor,
      icon: Icons.payment_rounded,
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
                // Resumen
                _buildPaymentSummary(context, sortedMethods),
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

  Widget _buildPaymentSummary(
    BuildContext context,
    List<MapEntry<String, double>> sortedMethods,
  ) {
    final theme = Theme.of(context);
    final totalMethods = sortedMethods.length;
    final topMethod = sortedMethods.isNotEmpty ? sortedMethods.first : null;
    final topMethodName = topMethod != null
        ? PaymentMethod.fromCode(topMethod.key).displayName
        : 'N/A';
    final topMethodPercentage = topMethod != null && analytics.totalSales > 0
        ? (topMethod.value / analytics.totalSales * 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accentColor.withValues(alpha: 0.15),
            _accentColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Método más usado
          Icon(
            PaymentMethod.fromCode(topMethod?.key ?? '').icon,
            size: 40,
            color: _accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            topMethodName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: _accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Método más usado (${topMethodPercentage.toStringAsFixed(1)}%)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          // Estadísticas
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.category_rounded,
                  '$totalMethods',
                  'Métodos usados',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.attach_money_rounded,
                  CurrencyHelper.formatCurrency(analytics.totalSales),
                  'Total Facturado',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: _accentColor,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodDetail(
    BuildContext context,
    MapEntry<String, double> entry,
  ) {
    final theme = Theme.of(context);
    final paymentMethod = PaymentMethod.fromCode(entry.key);
    final amount = entry.value;
    final count = analytics.paymentMethodsCount[entry.key] ?? 0;
    final percentage =
        analytics.totalSales > 0 ? (amount / analytics.totalSales * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icono del método
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  paymentMethod.icon,
                  color: _accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Nombre y transacciones
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paymentMethod.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count transacción${count != 1 ? 'es' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Monto
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyHelper.formatCurrency(amount),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _accentColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: _accentColor.withValues(alpha: 0.1),
              color: _accentColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Muestra el modal de métodos de pago
void showPaymentMethodsModal(BuildContext context, SalesAnalytics analytics) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PaymentMethodsModal(analytics: analytics),
  );
}
