import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';
import 'package:sellweb/presentation/widgets/ticket/ticket_utils.dart';

/// Widget que muestra la confirmación de venta exitosa con animaciones
class TicketConfirmedPurchaseWidget extends StatelessWidget {
  final double width;

  const TicketConfirmedPurchaseWidget({
    super.key,
    this.width = 400,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SellProvider>(context, listen: false);
    final theme = Theme.of(context);
    final ticket = provider.ticket;

    // Obtener información del método de pago
    String paymentMethodText = TicketUtils.getPaymentMethodDisplayText(ticket.payMode);
    IconData paymentIcon = TicketUtils.getPaymentMethodIcon(ticket.payMode);

    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade400,
            Colors.green.shade600,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono principal con efecto circular
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),

            const SizedBox(height: 24),

            // Título principal
            Text(
              '¡Venta exitosa!',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtítulo
            Text(
              'Transacción completada correctamente',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Card con detalles de la venta
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Total de la venta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total vendido:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        Publications.getFormatoPrecio(
                            value: ticket.getTotalPrice),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),

                  const SizedBox(height: 16),

                  // Información adicional
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cantidad de artículos
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Artículos',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ticket.getProductsQuantity()}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Método de pago
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Método de pago',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                paymentIcon,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                paymentMethodText,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Mostrar vuelto si aplica
                  if (ticket.valueReceived > 0 &&
                      ticket.valueReceived > ticket.getTotalPrice) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Vuelto a entregar',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Publications.getFormatoPrecio(
                              value:
                                  ticket.valueReceived - ticket.getTotalPrice,
                            ),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'RobotoMono',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Información de fecha y hora
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    TicketUtils.getFormattedDateTime(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
