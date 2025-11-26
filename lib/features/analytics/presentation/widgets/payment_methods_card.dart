import 'package:flutter/material.dart';

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
    
    // Ordenar métodos por monto descendente
    final sortedMethods = paymentMethodsBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.payment,
                    color: theme.colorScheme.tertiary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Medios de Pago',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (sortedMethods.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'Sin datos',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: sortedMethods.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = sortedMethods[index];
                    final percentage = totalSales > 0 ? entry.value / totalSales : 0.0;
                    
                    // Mapeo de nombres amigables
                    String displayName = entry.key;
                    IconData methodIcon = Icons.money;
                    
                    switch (entry.key.toLowerCase()) {
                      case 'efective':
                      case 'efectivo':
                        displayName = 'Efectivo';
                        methodIcon = Icons.attach_money;
                        break;
                      case 'mercadopago':
                        displayName = 'Mercado Pago';
                        methodIcon = Icons.qr_code;
                        break;
                      case 'card':
                      case 'tarjeta':
                        displayName = 'Tarjeta';
                        methodIcon = Icons.credit_card;
                        break;
                      default:
                        displayName = entry.key;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(methodIcon, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 8),
                                Text(
                                  displayName,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            Text(
                              '\$${entry.value.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          color: theme.colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 6,
                        ),
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${(percentage * 100).toStringAsFixed(1)}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
