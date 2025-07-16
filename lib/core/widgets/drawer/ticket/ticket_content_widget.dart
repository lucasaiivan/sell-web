import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/core/utils/responsive.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';
import 'package:sellweb/core/widgets/drawer/ticket/ticket_header_widget.dart';
import 'package:sellweb/core/widgets/drawer/ticket/ticket_product_list_widget.dart';
import 'package:sellweb/core/widgets/drawer/ticket/ticket_total_widget.dart';
import 'package:sellweb/core/widgets/drawer/ticket/ticket_payment_methods_widget.dart';
import 'package:sellweb/core/widgets/drawer/ticket/ticket_print_checkbox_widget.dart';
import 'package:sellweb/core/widgets/drawer/ticket/ticket_action_buttons_widget.dart';
import 'package:sellweb/core/widgets/drawer/ticket/ticket_dashed_line_painter.dart';

/// Widget que contiene todo el contenido principal del ticket
class TicketContentWidget extends StatelessWidget {
  final VoidCallback? onEditCashAmount;
  final VoidCallback? onConfirmSale;
  final VoidCallback? onCloseTicket;

  const TicketContentWidget({
    super.key,
    this.onEditCashAmount,
    this.onConfirmSale,
    this.onCloseTicket,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SellProvider>(context);
    final ticket = provider.ticket;

    // Style adaptado a tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Color borderColor = colorScheme.onSurface;
    Color backgroundColor = colorScheme.primary.withValues(alpha: 0.1);

    final TextStyle textValuesStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: colorScheme.onSurface,
    );

    final TextStyle textDescriptionStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 18,
      color: colorScheme.onSurface,
    );

    final TextStyle textSmallStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 13,
      color: colorScheme.onSurface.withValues(alpha: 0.87),
    );

    Widget dividerLinesWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, 1),
                  painter: TicketDashedLinePainter(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: borderColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Encabezado del ticket
            TicketHeaderWidget(
              businessName: provider.profileAccountSelected.name.isNotEmpty
                  ? provider.profileAccountSelected.name
                  : 'TICKET',
              textDescriptionStyle: textDescriptionStyle,
              textSmallStyle: textSmallStyle,
            ),

            dividerLinesWidget,

            // Encabezados de columnas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              child: Row(
                children: [
                  Expanded(child: Text('Cant.', style: textSmallStyle)),
                  Expanded(
                    flex: 3,
                    child: Text('Producto', style: textSmallStyle),
                  ),
                  Expanded(
                    child: Text(
                      'Precio',
                      style: textSmallStyle,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),

            dividerLinesWidget,

            // Lista de productos
            Flexible(
              child: TicketProductListWidget(
                ticket: ticket,
                textValuesStyle: textValuesStyle,
              ),
            ),

            dividerLinesWidget,

            // Cantidad total de artículos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              child: Row(
                children: [
                  Text('Artículos:', style: textSmallStyle),
                  const Spacer(),
                  Text(
                    '${ticket.getProductsQuantity()}',
                    style: textDescriptionStyle,
                  ),
                ],
              ),
            ),

            dividerLinesWidget,
            const SizedBox(height: 5),

            // Vuelto (solo si corresponde)
            if (ticket.valueReceived > 0 &&
                ticket.valueReceived >= ticket.getTotalPrice)
              Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  bottom: 5,
                  top: 5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Spacer(),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onEditCashAmount,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Vuelto ${Publications.getFormatoPrecio(value: ticket.valueReceived - ticket.getTotalPrice)}',
                                style: textDescriptionStyle.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: colorScheme.onSurface,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Total del ticket
            TicketTotalWidget(
              total: ticket.getTotalPrice,
              color: colorScheme.primary,
            ),

            // Métodos de pago
            TicketPaymentMethodsWidget(
              onCashPaymentSelected: onEditCashAmount,
            ),

            const SizedBox(height: 12),

            // Checkbox para imprimir ticket
            const TicketPrintCheckboxWidget(),

            const SizedBox(height: 12),

            // Botones de acción
            TicketActionButtonsWidget(
              onConfirmSale: onConfirmSale,
              onCloseTicket: onCloseTicket,
              showCloseButton: isMobile(context),
            ),
          ],
        ),
      ),
    );
  }
}
