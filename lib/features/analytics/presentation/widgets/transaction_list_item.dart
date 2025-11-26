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

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primera fila: Total y Estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total de venta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(ticket.priceTotal),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: isAnnulled ? TextDecoration.lineThrough : null,
                            color: isAnnulled
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge de estado
                  if (isAnnulled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cancel_rounded,
                            size: 14,
                            color: colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Anulada',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Segunda fila: Detalles
              Row(
                children: [
                  // Fecha y hora
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _formatDateTime(ticket.creation.toDate()),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Método de pago
                  if (ticket.payMode.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPaymentIcon(ticket.payMode),
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getPaymentMethodLabel(ticket.payMode),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Tercera fila: Ganancia
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ganancia',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: profit > 0 
                          ? Colors.green.withValues(alpha: 0.1)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      currencyFormat.format(profit),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: profit > 0 ? Colors.green.shade700 : colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
}
