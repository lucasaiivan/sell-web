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
    final iconColor = theme.colorScheme.tertiary;
    final cardColor = iconColor.withValues(alpha: 0.08);
    
    // Ordenar métodos por monto descendente
    final sortedMethods = paymentMethodsBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Material(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.payment,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Medios de Pago',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (sortedMethods.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
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
              ...sortedMethods.map((entry) {
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

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(methodIcon, size: 18, color: theme.colorScheme.onSurfaceVariant),
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              color: theme.colorScheme.tertiary,
                              borderRadius: BorderRadius.circular(4),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(percentage * 100).toStringAsFixed(1)}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}
