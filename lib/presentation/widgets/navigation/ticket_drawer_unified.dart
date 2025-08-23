import '../../../core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/presentation/widgets/dialogs/sales/discount_dialog.dart';
import 'package:sellweb/domain/entities/catalogue.dart' hide Provider;
import 'package:sellweb/presentation/providers/sell_provider.dart';

// ============================================================================
// UTILIDADES PARA TICKETS - Integradas desde ticket_utils.dart
// ============================================================================

/// Clase de utilidades para el manejo de tickets
class TicketUtils {
  /// Obtiene el texto a mostrar para el método de pago
  static String getPaymentMethodDisplayText(String payMode) {
    switch (payMode) {
      case 'effective':
        return 'Efectivo';
      case 'mercadopago':
        return 'Mercado Pago';
      case 'card':
        return 'Tarjeta';
      default:
        return 'Sin especificar';
    }
  }

  /// Obtiene el icono correspondiente al método de pago
  static IconData getPaymentMethodIcon(String payMode) {
    switch (payMode) {
      case 'effective':
        return Icons.payments_rounded;
      case 'mercadopago':
        return Icons.account_balance_wallet_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  /// Obtiene la fecha y hora formateada para mostrar en la confirmación
  static String getFormattedDateTime() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

// ============================================================================
// WIDGET PRINCIPAL DEL TICKET DRAWER - Unificado
// ============================================================================

/// Widget principal que muestra el drawer/vista del ticket de venta
/// Consolidado para priorizar simplicidad y reducir fragmentación
class TicketDrawerWidget extends StatelessWidget {
  final bool showConfirmedPurchase;
  final VoidCallback? onEditCashAmount;
  final VoidCallback? onConfirmSale;
  final VoidCallback? onCloseTicket;

  const TicketDrawerWidget({
    super.key,
    required this.showConfirmedPurchase,
    this.onEditCashAmount,
    this.onConfirmSale,
    this.onCloseTicket,
  });

  @override
  Widget build(BuildContext context) {
    return showConfirmedPurchase
        ? _TicketConfirmedPurchase(
                width:
                    isMobile(context) ? MediaQuery.of(context).size.width : 400)
            .animate()
            .scale(
              duration: 600.ms,
              curve: Curves.elasticOut,
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
            )
        : AnimatedContainer(
            width: isMobile(context) ? MediaQuery.of(context).size.width : 400,
            height: double.infinity,
            curve: Curves.fastOutSlowIn,
            duration: const Duration(milliseconds: 300),
            child: _TicketContent(
              onEditCashAmount: onEditCashAmount,
              onConfirmSale: onConfirmSale,
              onCloseTicket: onCloseTicket,
            ),
          );
  }
}

/// Widget que contiene todo el contenido principal del ticket
class _TicketContent extends StatelessWidget {
  final VoidCallback? onEditCashAmount;
  final VoidCallback? onConfirmSale;
  final VoidCallback? onCloseTicket;

  const _TicketContent({
    this.onEditCashAmount,
    this.onConfirmSale,
    this.onCloseTicket,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SellProvider>(context);
    final ticket = provider.ticket;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Estilos del ticket
    final borderColor = colorScheme.onSurface;
    final backgroundColor = colorScheme.primaryContainer.withValues(alpha: 0.3);

    final textValuesStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: colorScheme.onSurface,
    );

    final textDescriptionStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 18,
      color: colorScheme.onSurface,
    );

    final textSmallStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 13,
      color: colorScheme.onSurface.withValues(alpha: 0.87),
    );

    final textTotalStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontWeight: FontWeight.bold,
      fontSize: 24,
      color: colorScheme.onPrimary,
    );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado del ticket
          _TicketHeader(
            onCloseTicket: onCloseTicket,
            backgroundColor: backgroundColor,
          ),

          // Línea divisoria
          CustomPaint(
            size: const Size(double.infinity, 1),
            painter: DashedLinePainter(
              color: borderColor,
              dashWidth: 4,
              dashSpace: 2,
            ),
          ),

          // Contenido del ticket
          Expanded(
            child: Container(
              color: backgroundColor,
              child: Column(
                children: [
                  // Lista de productos
                  Expanded(
                    child: _ProductList(
                      ticket: ticket,
                      textDescriptionStyle: textDescriptionStyle,
                      textValuesStyle: textValuesStyle,
                      textSmallStyle: textSmallStyle,
                    ),
                  ),

                  // Separador
                  const SizedBox(height: 8),

                  // Resumen de totales
                  _TicketSummary(
                    ticket: ticket,
                    textValuesStyle: textValuesStyle,
                    textTotalStyle: textTotalStyle,
                  ),

                  // Botones de acción
                  _TicketActions(
                    ticket: ticket,
                    onEditCashAmount: onEditCashAmount,
                    onConfirmSale: onConfirmSale,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Encabezado del ticket con título y botón de cerrar
class _TicketHeader extends StatelessWidget {
  final VoidCallback? onCloseTicket;
  final Color backgroundColor;

  const _TicketHeader({
    this.onCloseTicket,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TICKET DE VENTA',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'RobotoMono',
            ),
          ),
          if (onCloseTicket != null)
            IconButton(
              onPressed: onCloseTicket,
              icon: const Icon(Icons.close),
              tooltip: 'Cerrar ticket',
            ),
        ],
      ),
    );
  }
}

/// Lista de productos en el ticket
class _ProductList extends StatelessWidget {
  final dynamic ticket;
  final TextStyle textDescriptionStyle;
  final TextStyle textValuesStyle;
  final TextStyle textSmallStyle;

  const _ProductList({
    required this.ticket,
    required this.textDescriptionStyle,
    required this.textValuesStyle,
    required this.textSmallStyle,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SellProvider>(context);

    if (ticket.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos en el ticket',
              style: textDescriptionStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: ticket.products.length,
      itemBuilder: (context, index) {
        final product = ticket.products[index];
        return _ProductItem(
          product: product,
          onRemove: () => provider.removeProduct(product),
          onIncrement: () => provider.addProductsticket(
            ProductCatalogue(
              id: product.id,
              description: product.description,
              salePrice: product.salePrice,
              image: product.image,
              code: product.code,
            ),
          ),
          onDecrement: () => provider.removeProduct(product),
          textDescriptionStyle: textDescriptionStyle,
          textValuesStyle: textValuesStyle,
          textSmallStyle: textSmallStyle,
        );
      },
    );
  }
}

/// Item individual de producto en el ticket
class _ProductItem extends StatelessWidget {
  final dynamic product;
  final VoidCallback onRemove;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final TextStyle textDescriptionStyle;
  final TextStyle textValuesStyle;
  final TextStyle textSmallStyle;

  const _ProductItem({
    required this.product,
    required this.onRemove,
    required this.onIncrement,
    required this.onDecrement,
    required this.textDescriptionStyle,
    required this.textValuesStyle,
    required this.textSmallStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del producto y botón eliminar
          Row(
            children: [
              Expanded(
                child: Text(
                  product.title,
                  style: textDescriptionStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                tooltip: 'Eliminar producto',
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Precio unitario, cantidad y total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Precio unitario
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Precio', style: textSmallStyle),
                  Text(
                    CurrencyFormatter.formatPrice(value: product.price),
                    style: textValuesStyle,
                  ),
                ],
              ),

              // Controles de cantidad
              Row(
                children: [
                  IconButton(
                    onPressed: onDecrement,
                    icon: const Icon(Icons.remove),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${product.quantity}',
                      style: textValuesStyle,
                    ),
                  ),
                  IconButton(
                    onPressed: onIncrement,
                    icon: const Icon(Icons.add),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              // Total del producto
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total', style: textSmallStyle),
                  Text(
                    CurrencyFormatter.formatPrice(value: product.getTotalPrice),
                    style: textValuesStyle,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Resumen de totales del ticket
class _TicketSummary extends StatelessWidget {
  final dynamic ticket;
  final TextStyle textValuesStyle;
  final TextStyle textTotalStyle;

  const _TicketSummary({
    required this.ticket,
    required this.textValuesStyle,
    required this.textTotalStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal:', style: textTotalStyle),
              Text(
                CurrencyFormatter.formatPrice(value: ticket.getSubTotal),
                style: textTotalStyle,
              ),
            ],
          ),

          // Descuento (si existe)
          if (ticket.discount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Descuento:', style: textTotalStyle),
                Text(
                  '-${CurrencyFormatter.formatPrice(value: ticket.discount)}',
                  style: textTotalStyle.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          Divider(color: theme.colorScheme.onPrimary),
          const SizedBox(height: 12),

          // Total final
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL:',
                style: textTotalStyle.copyWith(fontSize: 28),
              ),
              Text(
                CurrencyFormatter.formatPrice(value: ticket.getTotalPrice),
                style: textTotalStyle.copyWith(fontSize: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Botones de acción del ticket
class _TicketActions extends StatelessWidget {
  final dynamic ticket;
  final VoidCallback? onEditCashAmount;
  final VoidCallback? onConfirmSale;

  const _TicketActions({
    required this.ticket,
    this.onEditCashAmount,
    this.onConfirmSale,
  });

  @override
  Widget build(BuildContext context) {
    final ticket = this.ticket;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Botón de descuento
          SizedBox(
            width: double.infinity,
            child: ButtonApp.outlined(
              text: ticket.discount > 0
                  ? 'Modificar Descuento (${CurrencyFormatter.formatPrice(value: ticket.discount)})'
                  : 'Aplicar Descuento',
              icon: const Icon(Icons.local_offer_outlined),
              onPressed: () => showDiscountDialog(context),
            ),
          ),

          const SizedBox(height: 12),

          // Botón de editar cantidad de efectivo
          if (onEditCashAmount != null)
            SizedBox(
              width: double.infinity,
              child: ButtonApp.text(
                text: 'Editar Cantidad de Efectivo',
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEditCashAmount,
              ),
            ),

          const SizedBox(height: 16),

          // Botón de confirmar venta
          SizedBox(
            width: double.infinity,
            child: ButtonApp.primary(
              text: 'Confirmar Venta',
              icon: const Icon(Icons.check_circle_outline),
              onPressed: ticket.products.isNotEmpty ? onConfirmSale : null,
              backgroundColor: ticket.products.isNotEmpty
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget que muestra la confirmación de compra exitosa
class _TicketConfirmedPurchase extends StatelessWidget {
  final double width;

  const _TicketConfirmedPurchase({required this.width});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SellProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono de éxito
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 48,
              color: colorScheme.onPrimary,
            ),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .then()
              .shake(duration: 400.ms),

          const SizedBox(height: 24),

          // Título
          Text(
            '¡Venta Confirmada!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Información de la venta
          _SaleInfo(provider: provider),

          const SizedBox(height: 24),

          // Botones de acción
          _ConfirmationActions(provider: provider),
        ],
      ),
    );
  }
}

/// Información de la venta confirmada
class _SaleInfo extends StatelessWidget {
  final SellProvider provider;

  const _SaleInfo({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ticket = provider.ticket;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Total de la venta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                CurrencyFormatter.formatPrice(value: ticket.getTotalPrice),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Método de pago
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Método de pago:', style: theme.textTheme.bodyMedium),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    TicketUtils.getPaymentMethodIcon(provider.ticket.payMode),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    TicketUtils.getPaymentMethodDisplayText(provider.ticket.payMode),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Fecha y hora
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fecha:', style: theme.textTheme.bodyMedium),
              Text(
                TicketUtils.getFormattedDateTime(),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Botones de acción en la confirmación
class _ConfirmationActions extends StatelessWidget {
  final SellProvider provider;

  const _ConfirmationActions({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botón para nueva venta
        SizedBox(
          width: double.infinity,
          child: ButtonApp.primary(
            text: 'Nueva Venta',
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: () {
              // Descartar el ticket actual para crear uno nuevo
              provider.discartTicket();
            },
          ),
        ),

        const SizedBox(height: 12),

        // Botón para imprimir ticket
        SizedBox(
          width: double.infinity,
          child: ButtonApp.outlined(
            text: 'Imprimir Ticket',
            icon: const Icon(Icons.print),
            onPressed: () {
              // TODO: Implementar lógica de impresión
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de impresión no implementada'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Painter para crear líneas punteadas
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
