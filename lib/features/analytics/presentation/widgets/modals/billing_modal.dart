import 'package:flutter/material.dart';
import 'package:sellweb/core/constants/analytics_colors.dart';
import 'package:sellweb/core/constants/payment_methods.dart';
import 'package:sellweb/core/utils/helpers/currency_helper.dart';
import 'package:sellweb/features/analytics/domain/entities/sales_analytics.dart';
import '../core/widgets.dart';

/// Widget: Modal de Facturación Detallada
///
/// **Responsabilidad:**
/// - Mostrar desglose completo de la facturación
/// - Visualizar ingresos por método de pago
/// - Mostrar estadísticas de transacciones
class BillingModal extends StatelessWidget {
  final SalesAnalytics analytics;

  const BillingModal({
    super.key,
    required this.analytics,
  });

  static const _accentColor = AnalyticsColors.billing; // Verde Bosque

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calcular estadísticas adicionales
    final averagePerTransaction = analytics.totalTransactions > 0
        ? analytics.totalSales / analytics.totalTransactions
        : 0.0;

    // Ordenar métodos de pago por monto
    final sortedPaymentMethods =
        analytics.paymentMethodsBreakdown.entries.toList()
          ..sort((a, b) {
            if (a.key.isEmpty) return 1;
            if (b.key.isEmpty) return -1;
            return b.value.compareTo(a.value);
          });

    return AnalyticsModal(
      accentColor: _accentColor,
      icon: Icons.attach_money_rounded,
      title: 'Facturación',
      subtitle: 'Desglose de ingresos',
      child: analytics.totalSales == 0
          ? const AnalyticsModalEmptyState(
              icon: Icons.attach_money_rounded,
              title: 'Sin facturación',
              subtitle: 'Realiza algunas ventas para ver el desglose',
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // Resumen principal
                _buildSummaryCard(context, averagePerTransaction),
                const SizedBox(height: 24),

                // Desglose por método de pago
                if (sortedPaymentMethods.isNotEmpty) ...[
                  Text(
                    'Desglose por método de pago',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...sortedPaymentMethods.map(
                    (entry) => _buildPaymentMethodItem(
                      context,
                      entry.key,
                      entry.value,
                      analytics.paymentMethodsCount[entry.key] ?? 0,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double averagePerTransaction) {
    final theme = Theme.of(context);

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
          // Total facturado grande
          Text(
            CurrencyHelper.formatCurrency(analytics.totalSales),
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: _accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total Facturado',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          // Estadísticas adicionales
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.receipt_long_rounded,
                  '${analytics.totalTransactions}',
                  'Transacciones',
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
                  Icons.trending_up_rounded,
                  CurrencyHelper.formatCurrency(averagePerTransaction),
                  'Promedio/Venta',
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
        ),
      ],
    );
  }

  Widget _buildPaymentMethodItem(
    BuildContext context,
    String methodCode,
    double amount,
    int count,
  ) {
    final theme = Theme.of(context);
    final percentage =
        analytics.totalSales > 0 ? (amount / analytics.totalSales * 100) : 0.0;

    // Obtener información del método de pago
    final paymentMethod = PaymentMethod.fromCode(methodCode);

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
      child: Row(
        children: [
          // Icono del método de pago
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
          // Nombre y cantidad
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
          // Monto y porcentaje
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
    );
  }
}

/// Muestra el modal de facturación
void showBillingModal(BuildContext context, SalesAnalytics analytics) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => BillingModal(analytics: analytics),
  );
}
