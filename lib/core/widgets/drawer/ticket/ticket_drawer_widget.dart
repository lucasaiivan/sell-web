import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sellweb/core/utils/responsive.dart';
import 'package:sellweb/core/widgets/drawer/ticket/ticket_confirmed_purchase_widget.dart';
import 'package:sellweb/core/widgets/drawer/ticket/ticket_content_widget.dart';

/// Widget principal que muestra el drawer/vista del ticket de venta
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
        ? TicketConfirmedPurchaseWidget(
            width: isMobile(context) ? MediaQuery.of(context).size.width : 400,
          ).animate().scale(
            duration: 600.ms,
            curve: Curves.elasticOut,
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
          )
        : AnimatedContainer(
            width: isMobile(context) ? MediaQuery.of(context).size.width : 400,
            curve: Curves.fastOutSlowIn,
            duration: const Duration(milliseconds: 300),
            child: TicketContentWidget(
              onEditCashAmount: onEditCashAmount,
              onConfirmSale: onConfirmSale,
              onCloseTicket: onCloseTicket,
            ),
          );
  }
}
