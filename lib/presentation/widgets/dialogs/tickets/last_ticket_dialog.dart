import 'package:sellweb/core/core.dart';
import 'package:flutter/material.dart';
import 'package:sellweb/presentation/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/presentation/widgets/dialogs/components/dialog_components.dart';
import 'package:sellweb/presentation/widgets/dialogs/tickets/ticket_options_dialog.dart';
import 'package:sellweb/domain/entities/ticket_model.dart';

/// Diálogo modernizado para mostrar el último ticket siguiendo Material Design 3
class LastTicketDialog extends StatefulWidget {
  const LastTicketDialog({
    super.key,
    required this.ticket,
    required this.businessName,
  });

  final TicketModel ticket;
  final String businessName;

  @override
  State<LastTicketDialog> createState() => _LastTicketDialogState();
}

class _LastTicketDialogState extends State<LastTicketDialog> {
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} - '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _getPaymentMethodName(String payMode) {
    switch (payMode) {
      case 'mercadopago':
        return 'Mercado Pago';
      case 'card':
        return 'Tarjeta Déb/Créd';
      default:
        return 'Efectivo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: 'Último Ticket',
      icon: Icons.receipt_long_rounded,
      width: 450,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del negocio y fecha
          DialogComponents.infoSection(
            context: context,
            title: 'Información del Ticket',
            icon: Icons.business_rounded,
            content: Column(
              children: [
                DialogComponents.infoRow(
                  context: context,
                  label: 'Negocio',
                  value: widget.businessName,
                  icon: Icons.store_rounded,
                ),
                DialogComponents.minSpacing,
                DialogComponents.infoRow(
                  context: context,
                  label: 'Fecha',
                  value: _formatDate(widget.ticket.creation.toDate()),
                  icon: Icons.schedule_rounded,
                ),
                DialogComponents.minSpacing,
                DialogComponents.infoRow(
                  context: context,
                  label: 'ID Ticket',
                  value: widget.ticket.id.length > 8
                      ? '...${widget.ticket.id.substring(widget.ticket.id.length - 8)}'
                      : widget.ticket.id,
                  icon: Icons.confirmation_number_rounded,
                ),
              ],
            ),
          ),

          DialogComponents.sectionSpacing,

          // Lista de productos
          Text(
            'Productos Vendidos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          DialogComponents.itemSpacing,
          // view : lista de productos
          DialogComponents.itemList(
            context: context,
            items: widget.ticket.products.map((product) {
              final quantity = product.quantity;
              final description = product.description;
              final unitPrice = product.salePrice;
              final totalPrice = unitPrice * quantity;
              // view : item de producto
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Cantidad en badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$quantity',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Descripción del producto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.formatPrice(value: unitPrice),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Precio total
                    Text(
                      CurrencyFormatter.formatPrice(value: totalPrice),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          DialogComponents.sectionSpacing,

          // Información de pago
          DialogComponents.infoSection(
            context: context,
            title: 'Información de Pago',
            icon: Icons.payment_rounded,
            content: Column(
              children: [
                DialogComponents.infoRow(
                  context: context,
                  label: 'Método de Pago',
                  value: _getPaymentMethodName(widget.ticket.payMode),
                  icon: Icons.credit_card_rounded,
                ),
                if (widget.ticket.valueReceived > 0) ...[
                  DialogComponents.minSpacing,
                  DialogComponents.infoRow(
                    context: context,
                    label: 'Recibido',
                    value: CurrencyFormatter.formatPrice(
                        value: widget.ticket.valueReceived),
                    icon: Icons.monetization_on_rounded,
                  ),
                  if (widget.ticket.valueReceived >
                      widget.ticket.getTotalPrice) ...[
                    DialogComponents.minSpacing,
                    DialogComponents.infoRow(
                      context: context,
                      label: 'Cambio',
                      value: CurrencyFormatter.formatPrice(
                        value: widget.ticket.valueReceived -
                            widget.ticket.getTotalPrice,
                      ),
                      icon: Icons.change_circle_rounded,
                    ),
                  ],
                ],
              ],
            ),
          ),

          DialogComponents.sectionSpacing,

          // Total del ticket
          DialogComponents.summaryContainer(
            context: context,
            label: 'Total del Ticket',
            value: CurrencyFormatter.formatPrice(
                value: widget.ticket.getTotalPrice),
            icon: Icons.receipt_rounded,
          ),
        ],
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DialogComponents.primaryActionButton(
          context: context,
          text: 'Imprimir',
          icon: Icons.print_rounded,
          onPressed: () => _showTicketOptions(),
        ),
      ],
    );
  }

  void _showTicketOptions() {
    Navigator.of(context).pop(); // Cerrar diálogo actual

    showTicketOptionsDialog(
      context: context,
      ticket: widget.ticket,
      businessName: widget.businessName,
      onComplete: () {
        // Acción al completar las opciones del ticket
      },
    );
  }
}

/// Helper function para mostrar el diálogo del último ticket
Future<void> showLastTicketDialog({
  required BuildContext context,
  required TicketModel ticket,
  required String businessName,
}) {
  return showDialog(
    context: context,
    builder: (context) => LastTicketDialog(
      ticket: ticket,
      businessName: businessName,
    ),
  );
}
