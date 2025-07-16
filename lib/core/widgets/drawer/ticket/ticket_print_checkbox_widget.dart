import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';

/// Widget que muestra el checkbox para imprimir ticket
class TicketPrintCheckboxWidget extends StatelessWidget {
  const TicketPrintCheckboxWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Consumer<SellProvider>(
        builder: (context, sellProvider, __) {
          final colorScheme = Theme.of(context).colorScheme;
          
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: sellProvider.shouldPrintTicket
                    ? colorScheme.primary.withValues(alpha: 0.3)
                    : colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(6),
              color: !sellProvider.shouldPrintTicket
                  ? colorScheme.primaryContainer.withValues(alpha: 0.1)
                  : colorScheme.primaryContainer.withValues(alpha: 0.7),
            ),
            child: CheckboxListTile(
              dense: true,
              value: sellProvider.shouldPrintTicket,
              onChanged: (bool? value) {
                sellProvider.setShouldPrintTicket(value ?? false);
              },
              title: Text(
                'Ticket',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: sellProvider.shouldPrintTicket
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              secondary: Icon(
                sellProvider.shouldPrintTicket
                    ? Icons.receipt_long
                    : Icons.receipt_long_outlined,
                color: sellProvider.shouldPrintTicket
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }
}
