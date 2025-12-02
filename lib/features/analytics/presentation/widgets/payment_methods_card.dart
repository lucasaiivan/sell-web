import 'package:flutter/material.dart';
import 'package:sellweb/core/constants/payment_methods.dart';
import 'package:sellweb/core/utils/helpers/currency_helper.dart';

class PaymentMethodsCard extends StatelessWidget {
  final Map<String, double> paymentMethodsBreakdown;
  final double totalSales;

  const PaymentMethodsCard({
    super.key,
    required this.paymentMethodsBreakdown,
    required this.totalSales,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Color principal de la tarjeta (Tertiary - igual que otras métricas)
    final color = theme.colorScheme.tertiary;
    final containerColor =
        isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08);
    final iconContainerColor = color.withValues(alpha: 0.2);

    // Ordenar métodos por monto descendente, con 'Sin Especificar' (string vacío) al final
    final sortedMethods = paymentMethodsBreakdown.entries.toList()
      ..sort((a, b) {
        // String vacío (Sin Especificar) siempre va al final (retorna valor positivo)
        if (a.key.isEmpty) return 1;
        if (b.key.isEmpty) return -1;
        // Los demás se ordenan por monto descendente
        return b.value.compareTo(a.value);
      });

    return Card(
      elevation: 0,
      color: containerColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconContainerColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.payment_rounded,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Medios de Pago',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              sortedMethods.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No hay pagos registrados',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: sortedMethods.map((entry) {
                        final percentage =
                            totalSales > 0 ? entry.value / totalSales : 0.0;

                        // Obtener información del método de pago desde el enum
                        final paymentMethod = PaymentMethod.fromCode(entry.key);
                        final displayName = paymentMethod.displayName;
                        final methodIcon = paymentMethod.icon;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        methodIcon,
                                        size: 20,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        displayName,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    CurrencyHelper.formatCurrency(entry.value),
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
                                        backgroundColor:
                                            color.withValues(alpha: 0.15),
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
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
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
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
