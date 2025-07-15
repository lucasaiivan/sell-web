import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';

/// Widget que muestra los chips de métodos de pago
class TicketPaymentMethodsWidget extends StatelessWidget {
  final VoidCallback? onCashPaymentSelected;

  const TicketPaymentMethodsWidget({
    super.key,
    this.onCashPaymentSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 6, bottom: 0),
      child: Column(
        children: [
          // Texto de métodos de pago
          Text(
            'Métodos de pago:',
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87),
            ),
          ),
          const SizedBox(height: 6),
          // Chips de métodos de pago
          Consumer<SellProvider>(
            builder: (context, provider, _) {
              return Wrap(
                spacing: 5,
                alignment: WrapAlignment.center,
                runSpacing: 5,
                children: [
                  // Pago con efectivo
                  ChoiceChip(
                    label: const Text('Efectivo'),
                    selected: provider.ticket.payMode == 'effective',
                    onSelected: (bool selected) {
                      if (selected && onCashPaymentSelected != null) {
                        onCashPaymentSelected!();
                      }
                      provider.setPayMode(payMode: selected ? 'effective' : '');
                    },
                  ),
                  // Pago con Mercado Pago
                  ChoiceChip(
                    label: const Text('Mercado Pago'),
                    selected: provider.ticket.payMode == 'mercadopago',
                    onSelected: (bool selected) {
                      provider.setPayMode(payMode: selected ? 'mercadopago' : '');
                    },
                  ),
                  // Pago con tarjeta
                  ChoiceChip(
                    label: const Text('Tarjeta Deb/Cred'),
                    selected: provider.ticket.payMode == 'card',
                    onSelected: (bool selected) {
                      provider.setPayMode(payMode: selected ? 'card' : '');
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
