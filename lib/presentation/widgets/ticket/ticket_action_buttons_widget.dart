import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sellweb/core/widgets/buttons/buttons.dart';

/// Widget que contiene los botones de acción del ticket (confirmar venta y cerrar)
class TicketActionButtonsWidget extends StatelessWidget {
  final VoidCallback? onConfirmSale;
  final VoidCallback? onCloseTicket;
  final bool showCloseButton;

  const TicketActionButtonsWidget({
    super.key,
    this.onConfirmSale,
    this.onCloseTicket,
    this.showCloseButton = false,
  });

  @override
  Widget build(BuildContext context) {
    const String confirmarText = 'Confirmar venta';

    return Row(
      children: [
        const Spacer(),
        
        // Botón de cerrar (solo en móvil)
        if (showCloseButton && onCloseTicket != null) ...[
          AppFloatingActionButton(
            onTap: onCloseTicket!,
            icon: Icons.close_rounded,
            buttonColor: Colors.grey.withValues(alpha: 0.8),
          ).animate(delay: const Duration(milliseconds: 0)).fade(),
          const SizedBox(width: 8),
        ],
        
        // Botón de confirmar venta
        AppFloatingActionButton(
          onTap: onConfirmSale,
          icon: Icons.check_circle_outline_rounded,
          text: confirmarText,
          extended: true,
        ).animate(delay: const Duration(milliseconds: 0)).fade(),
      ],
    );
  }
}
