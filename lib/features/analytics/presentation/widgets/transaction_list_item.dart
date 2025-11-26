import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

/// Widget: Item de Lista de Transacción
///
/// **Responsabilidad:**
/// - Mostrar información resumida de una transacción
/// - Formato visual consistente con el theme
///
/// **Información mostrada:**
/// - Fecha/hora de creación
/// - Total de la venta
/// - Ganancia
/// - Estado (anulado/activo)
/// - Método de pago
class TransactionListItem extends StatelessWidget {
  /// Ticket/Transacción a mostrar
  final TicketModel ticket;

  /// Callback opcional al tocar el item
  final VoidCallback? onTap;

  const TransactionListItem({
    super.key,
    required this.ticket,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currencyFormat = NumberFormat.currency(
      locale: 'es_AR',
      symbol: ticket.currencySymbol,
      decimalDigits: 2,
    );

    final isAnnulled = ticket.annulled;
    final profit = ticket.getProfit;
    final profitPercentage = ticket.getPercentageProfit;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Columna izquierda: Info principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila 1: Método de pago y fecha
                    Row(
                      children: [
                        // Badge método de pago
                        Material(
                          color: _getPaymentColor(ticket.payMode).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getPaymentIcon(ticket.payMode),
                                  size: 14,
                                  color: _getPaymentColor(ticket.payMode).withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getPaymentMethodLabel(ticket.payMode),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: _getPaymentColor(ticket.payMode).withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Separator dot
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Fecha
                        Flexible(
                          child: Text(
                            _formatDateTime(ticket.creation.toDate()),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Fila 2: Detalles de venta
                    Row(
                      children: [
                        // Caja y vendedor
                        Text(
                          'caja ${ticket.cashRegisterName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            ticket.sellerName.split('@')[0],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Fila 3: Total de venta
                    Row(
                      children: [ 
                        Text(
                          currencyFormat.format(ticket.priceTotal),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: isAnnulled ? TextDecoration.lineThrough : null,
                            color: isAnnulled
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                          ),
                        ),
                        if (isAnnulled) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ANULADA',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Columna derecha: Ganancia
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ganancia
                  if (profit != 0)
                    Text(
                      currencyFormat.format(profit),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: profit > 0 ? Colors.green.shade600 : colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  // Porcentaje
                  if (profitPercentage != 0) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          profitPercentage > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          size: 14,
                          color: profit > 0 ? Colors.green.shade600 : colorScheme.error,
                        ),
                        const SizedBox(width: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: profit > 0 
                                ? Colors.green.withValues(alpha: 0.15)
                                : colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$profitPercentage%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: profit > 0 ? Colors.green.shade700 : colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formatea DateTime para mostrar
  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  /// Obtiene label legible del método de pago
  String _getPaymentMethodLabel(String payMode) {
    switch (payMode.toLowerCase()) {
      case 'effective':
      case 'efective':
        return 'Efectivo';
      case 'mercadopago':
        return 'Mercado Pago';
      case 'card':
        return 'Tarjeta';
      case 'transfer':
        return 'Transferencia';
      default:
        return payMode;
    }
  }

  /// Obtiene el icono del método de pago
  IconData _getPaymentIcon(String payMode) {
    switch (payMode.toLowerCase()) {
      case 'effective':
      case 'efective':
        return Icons.attach_money;
      case 'mercadopago':
        return Icons.qr_code_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      case 'transfer':
        return Icons.account_balance_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  /// Obtiene el color del método de pago
  Color _getPaymentColor(String payMode) {
    switch (payMode.toLowerCase()) {
      case 'effective':
      case 'efective':
        return Colors.green;
      case 'mercadopago':
        return Colors.blue;
      case 'card':
        return Colors.orange;
      case 'transfer':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
