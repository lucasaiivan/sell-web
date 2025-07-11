import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../presentation/providers/cash_register_provider.dart';
import '../../buttons/primary_button.dart';

/// Diálogo para registrar ingresos o egresos de caja
class CashFlowDialog extends StatelessWidget {
  final bool isInflow;
  final String cashRegisterId;
  final String accountId;
  final String userId;

  const CashFlowDialog({
    super.key,
    required this.isInflow,
    required this.cashRegisterId,
    required this.accountId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final cashRegisterProvider = context.watch<CashRegisterProvider>();
    final title = isInflow ? 'Ingreso de Efectivo' : 'Egreso de Efectivo';
    final buttonText = isInflow ? 'Registrar Ingreso' : 'Registrar Egreso';
    final buttonColor = isInflow ? Colors.green : Colors.red;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isInflow ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: buttonColor,
          ),
          const SizedBox(width: 8),
          Text(title),
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
            TextField(
              controller: cashRegisterProvider.movementAmountController,
              decoration: InputDecoration(
                labelText: 'Monto',
                hintText: '0.00',
                prefixIcon: Icon(
                  Icons.attach_money,
                  color: buttonColor,
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cashRegisterProvider.movementDescriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                hintText: 'Motivo del ${isInflow ? "ingreso" : "egreso"}',
                prefixIcon: Icon(
                  Icons.description,
                  color: buttonColor,
                ),
              ),
              maxLines: 2,
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
        PrimaryButton(
          onPressed: cashRegisterProvider.isProcessing
              ? null
              : () => _handleCashFlow(context, cashRegisterProvider),
          isLoading: cashRegisterProvider.isProcessing,
          text: buttonText,
          backgroundColor: buttonColor,
        ),
      ],
    );
  }

  Future<void> _handleCashFlow(
    BuildContext context,
    CashRegisterProvider provider,
  ) async {
    final success = isInflow
        ? await provider.addCashInflow(accountId, cashRegisterId, userId)
        : await provider.addCashOutflow(accountId, cashRegisterId, userId);

    if (success && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
