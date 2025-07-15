import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/widgets/inputs/inputs.dart';
import '../../../../presentation/providers/cash_register_provider.dart';
import '../../../../presentation/providers/sell_provider.dart';
import '../../buttons/app_button.dart';

/// Diálogo para abrir una nueva caja registradora
class CashRegisterOpenDialog extends StatelessWidget {
  const CashRegisterOpenDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final cashRegisterProvider = context.watch<CashRegisterProvider>();

    return AlertDialog(
      title: Row(
        children: [
          const Text('Apertura de Caja'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InputTextField(
              controller: cashRegisterProvider.openDescriptionController,
              labelText: 'Descripción',
              hintText: 'Ej: Caja Principal',
            ), 
            const SizedBox(height: 16),
            // input : Campo para monto inicial
            MoneyInputTextField(
              controller: cashRegisterProvider.initialCashController,
              labelText: 'Monto Inicial', 
              
            ), 
            if (cashRegisterProvider.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                cashRegisterProvider.errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        Consumer<SellProvider>(
          builder: (context, sellProvider, child) {
            return AppButton.primary(
              onPressed: cashRegisterProvider.isProcessing
                  ? null
                  : () => _handleOpenCashRegister(
                        context,
                        cashRegisterProvider,
                        sellProvider,
                      ),
              isLoading: cashRegisterProvider.isProcessing,
              text: 'Abrir Caja',
            );
          },
        ),
      ],
    );
  }

  Future<void> _handleOpenCashRegister(
    BuildContext context,
    CashRegisterProvider cashRegisterProvider,
    SellProvider sellProvider,
  ) async {
    final accountId = sellProvider.profileAccountSelected.id;
    final userId = sellProvider.profileAccountSelected.id;

    final success = await cashRegisterProvider.openCashRegister(
      accountId,
      userId,
    );

    if (success && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
