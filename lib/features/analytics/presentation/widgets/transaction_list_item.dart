import 'package:flutter/material.dart';
import 'package:sellweb/core/constants/payment_methods.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'package:sellweb/core/utils/helpers/currency_helper.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;

    final isAnnulled = ticket.annulled;
    final profit = ticket.getProfit;
    final profitPercentage = ticket.getPercentageProfit;
    final itemsCount = ticket.totalProductCount;

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
          child: isLargeScreen
              ? _buildLargeScreenLayout(context, theme, colorScheme, isAnnulled, profit, profitPercentage, itemsCount)
              : _buildSmallScreenLayout(context, theme, colorScheme, isAnnulled, profit, profitPercentage, itemsCount),
        ),
      ),
    );
  }

  /// Layout para pantallas pequeñas (diseño original)
  Widget _buildSmallScreenLayout(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isAnnulled,
    double profit,
    int profitPercentage,
    int itemsCount,
  ) {
    return Row(
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
              // Fila 3: Cantidad de artículos y estado anulado
              Row(
                children: [
                  Text(
                    '$itemsCount ${itemsCount == 1 ? "artículo" : "artículos"}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
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
        // Columna derecha: Todos los montos
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total de venta
            Text(
              CurrencyHelper.formatCurrency(ticket.priceTotal, symbol: ticket.currencySymbol),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                decoration: isAnnulled ? TextDecoration.lineThrough : null,
                decorationThickness: isAnnulled ? 2.5 : null,
                color: colorScheme.onSurface,
              ),
            ),
            // Ganancia y porcentaje (solo si NO está anulado)
            if (!isAnnulled) ...[
              const SizedBox(height: 4),
              // Ganancia
              if (profit != 0)
                Text(
                  CurrencyHelper.formatCurrency(profit, symbol: ticket.currencySymbol),
                  style: theme.textTheme.bodyMedium?.copyWith(
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
          ],
        ),
      ],
    );
  }

  /// Layout para pantallas grandes (3 columnas)
  Widget _buildLargeScreenLayout(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isAnnulled,
    double profit,
    int profitPercentage,
    int itemsCount,
  ) {
    return Row(
      children: [
        // Columna 1: Método de pago, fecha, caja y vendedor
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 6),
              // Fecha
              Text(
                _formatDateTime(ticket.creation.toDate()),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              // Caja y vendedor
              Row(
                children: [
                  Icon(
                    Icons.point_of_sale_outlined,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'caja ${ticket.cashRegisterName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
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
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Columna 2 (Centro): Cantidad de artículos y estado
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$itemsCount ${itemsCount == 1 ? "artículo" : "artículos"}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isAnnulled) ...[
                const SizedBox(height: 6),
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
        ),

        const SizedBox(width: 16),

        // Columna 3: Total y ganancias
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Total de venta
              Text(
                CurrencyHelper.formatCurrency(ticket.priceTotal, symbol: ticket.currencySymbol),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  decoration: isAnnulled ? TextDecoration.lineThrough : null,
                  decorationThickness: isAnnulled ? 2.5 : null,
                  color: colorScheme.onSurface,
                ),
              ),
              // Ganancia y porcentaje (solo si NO está anulado)
              if (!isAnnulled) ...[
                const SizedBox(height: 4),
                // Ganancia
                if (profit != 0)
                  Text(
                    CurrencyHelper.formatCurrency(profit, symbol: ticket.currencySymbol),
                    style: theme.textTheme.bodyMedium?.copyWith(
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
            ],
          ),
        ),
      ],
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
    final method = PaymentMethod.fromCode(payMode);
    return method.displayName;
  }

  /// Obtiene el icono del método de pago
  IconData _getPaymentIcon(String payMode) {
    final method = PaymentMethod.fromCode(payMode);
    return method.icon;
  }

  /// Obtiene el color del método de pago
  Color _getPaymentColor(String payMode) {
    final method = PaymentMethod.fromCode(payMode);
    return method.color;
  }
}
