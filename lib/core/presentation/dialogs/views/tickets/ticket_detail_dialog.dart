import 'package:sellweb/core/core.dart';
import 'package:flutter/material.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'package:sellweb/core/presentation/widgets/ui/tags/combo_tag.dart';

/// Diálogo reutilizable para mostrar los detalles completos de un ticket
///
/// Este componente muestra:
/// - Información del negocio y fecha
/// - Estado del ticket (transaccionado o anulado)
/// - Método de pago y facturación
/// - Descuentos aplicados
/// - Lista completa de productos vendidos
/// - Acciones: Anular e Imprimir (solo si no está anulado)
///
/// **Uso:**
/// ```dart
/// showTicketDetailDialog(
///   context: context,
///   ticket: myTicket,
///   businessName: 'Mi Negocio',
///   title: 'Detalle de Transacción',
///   onTicketAnnulled: () => handleAnnulment(),
///   fullView: true, // Opcional: ocupa toda la pantalla
/// );
/// ```
class TicketDetailDialog extends StatefulWidget {
  const TicketDetailDialog({
    super.key,
    required this.ticket,
    required this.businessName,
    this.title = 'Ticket',
    this.onTicketAnnulled,
    this.fullView = false,
  });

  final TicketModel ticket;
  final String businessName;
  final String title;
  final VoidCallback? onTicketAnnulled;
  final bool fullView;

  @override
  State<TicketDetailDialog> createState() => _TicketDetailDialogState();
}

class _TicketDetailDialogState extends State<TicketDetailDialog> {
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} - '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // BaseDialog ahora maneja automáticamente el fullView
    return BaseDialog(
      title: widget.ticket.annulled ? '${widget.title} Anulado' : widget.title,
      icon: widget.ticket.annulled
          ? Icons.cancel_rounded
          : Icons.receipt_long_rounded,
      width: 450,
      headerColor: widget.ticket.annulled
          ? Theme.of(context).colorScheme.errorContainer
          : null,
      content: _buildContent(context),
      actions: _buildDialogActions(context),
      fullView: widget.fullView,
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información del negocio y fecha
        DialogComponents.infoSection(
          context: context,
          title: ' Información del Ticket',
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
                value: widget.ticket.id,
                icon: Icons.confirmation_number_rounded,
              ),
              DialogComponents.minSpacing,
              DialogComponents.infoRow(
                context: context,
                label: 'Estado',
                value: widget.ticket.annulled ? 'ANULADO' : 'TRANSACCIONADO',
                icon: widget.ticket.annulled
                    ? Icons.cancel_rounded
                    : Icons.check_circle_rounded,
                valueStyle: TextStyle(
                  color: widget.ticket.annulled
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        DialogComponents.sectionSpacing,
        // Información de pago
        DialogComponents.infoSection(
          context: context,
          title: 'Facturación',
          content: Column(
            children: [
              // Método de pago
              DialogComponents.infoRow(
                context: context,
                label: 'Método de Pago',
                value: widget.ticket.getNamePayMode,
                icon: Icons.credit_card_rounded,
                valueFill: true,
                valueStyle: TextStyle(
                  color: widget.ticket.getPayModeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Mostrar descuento si existe
              if (widget.ticket.discount > 0) ...[
                DialogComponents.minSpacing,
                DialogComponents.infoRow(
                  context: context,
                  label: 'Descuento',
                  value: widget.ticket.discountIsPercentage
                      ? '${widget.ticket.discount.toStringAsFixed(1)}% (${CurrencyFormatter.formatPrice(value: widget.ticket.getDiscountAmount)})'
                      : CurrencyFormatter.formatPrice(
                          value: widget.ticket.discount),
                  icon: Icons.discount_rounded,
                  valueStyle: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
          label: 'Total',
          value:
              CurrencyFormatter.formatPrice(value: widget.ticket.getTotalPrice),
          icon: Icons.receipt_rounded,
        ),
        DialogComponents.sectionSpacing,
        // view : lista de productos
        DialogComponents.itemList(
          title: 'Productos Vendidos',
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
                  // Cantidad en badge con unidad
                  Container(
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        product.formattedQuantityWithUnit,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
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
                        if (product.isCombo)
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: ComboTag(isCompact: true),
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
      ],
    );
  }

  /// Construye las acciones para el modo diálogo
  List<Widget> _buildDialogActions(BuildContext context) {
    return [
      if (!widget.ticket.annulled) ...[
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Anular',
          onPressed: () => _showAnnullConfirmation(),
        ),
        DialogComponents.primaryActionButton(
          context: context,
          text: 'Imprimir',
          onPressed: () => _showTicketOptions(),
        ),
      ] else ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Ticket Anulado',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
      DialogComponents.secondaryActionButton(
        context: context,
        text: 'ok',
        onPressed: () => Navigator.of(context).pop(),
      ),
    ];
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

  /// Muestra el diálogo de confirmación para anular el ticket
  void _showAnnullConfirmation() {
    showConfirmationDialog(
      context: context,
      title: 'Anular Ticket',
      message: '¿Estás seguro de que deseas anular este ticket?\n\n'
          'Esta acción marcará el ticket como anulado y no podrá ser revertida.',
      confirmText: 'Anular Ticket',
      cancelText: 'Cancelar',
      icon: Icons.warning_rounded,
      isDestructive: true,
      onConfirm: () => _annullTicket(),
    );
  }

  /// Ejecuta la anulación del ticket a través del callback
  void _annullTicket() {
    // Ejecutar el callback de anulación si está disponible
    if (widget.onTicketAnnulled != null) {
      // Cerrar el diálogo actual
      Navigator.of(context).pop();
      // Llamar al callback
      widget.onTicketAnnulled!();
    }
  }
}

/// Helper function para mostrar el diálogo de detalle de ticket
///
/// **Parámetros:**
/// - `context`: BuildContext necesario para mostrar el diálogo
/// - `ticket`: TicketModel con la información del ticket
/// - `businessName`: Nombre del negocio a mostrar
/// - `title`: Título personalizado del diálogo (default: 'Ticket')
/// - `onTicketAnnulled`: Callback opcional que se ejecuta al anular el ticket
/// - `fullView`: Si es true, el diálogo ocupa toda la pantalla (default: false)
///
/// **Ejemplo:**
/// ```dart
/// await showTicketDetailDialog(
///   context: context,
///   ticket: transaction,
///   businessName: 'Mi Tienda',
///   title: 'Detalle de Transacción',
///   fullView: true, // Opcional
/// );
/// ```
Future<void> showTicketDetailDialog({
  required BuildContext context,
  required TicketModel ticket,
  required String businessName,
  String title = 'Ticket',
  VoidCallback? onTicketAnnulled,
  bool fullView = false,
}) {
  final isSmallScreen = MediaQuery.of(context).size.width < 600;

  // Si es vista completa Y pantalla pequeña, usar Navigator.push para pantalla completa
  if (fullView && isSmallScreen) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => TicketDetailDialog(
          ticket: ticket,
          businessName: businessName,
          title: title,
          onTicketAnnulled: onTicketAnnulled,
          fullView: fullView,
        ),
      ),
    );
  }

  // Vista normal como diálogo (pantallas grandes o fullView = false)
  return showDialog(
    context: context,
    builder: (context) => TicketDetailDialog(
      ticket: ticket,
      businessName: businessName,
      title: title,
      onTicketAnnulled: onTicketAnnulled,
      fullView: fullView,
    ),
  );
}
