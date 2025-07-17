import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/widgets/inputs/inputs.dart';
import '../../../../core/utils/fuctions.dart';
import '../../../../domain/entities/cash_register_model.dart';
import '../../../../presentation/providers/cash_register_provider.dart';
import '../../../../presentation/providers/sell_provider.dart';
import '../../buttons/app_button.dart';

/// Diálogo para cerrar una caja registradora
class CashRegisterCloseDialog extends StatelessWidget {
  final CashRegister cashRegister;

  const CashRegisterCloseDialog({
    super.key,
    required this.cashRegister,
  });

  @override
  Widget build(BuildContext context) {
    final cashRegisterProvider = context.watch<CashRegisterProvider>();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lock_outline, color: Colors.red),
          const SizedBox(width: 8),
          const Text('Cierre de Caja'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryCard(context),
              const SizedBox(height: 16),
              MoneyInputTextField(
                controller: cashRegisterProvider.finalBalanceController,
                labelText: 'Balance Final',
              ),
              const SizedBox(height: 16),
              if (cashRegister.getDifference != 0) ...[
                Text(
                  'Diferencia: ${Publications.getFormatoPrecio(value: cashRegister.getDifference)}',
                  style: TextStyle(
                    color: cashRegister.getDifference < 0
                        ? Colors.red
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              if (cashRegisterProvider.errorMessage != null)
                Text(
                  cashRegisterProvider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
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
                  : () => _handleCloseCashRegister(
                        context,
                        cashRegisterProvider,
                        sellProvider,
                      ),
              isLoading: cashRegisterProvider.isProcessing,
              text: 'Cerrar Caja',
              backgroundColor: Colors.red,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de Caja',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Monto Inicial:',
                Publications.getFormatoPrecio(value: cashRegister.initialCash)),
            _buildSummaryRow('Ventas:', cashRegister.sales.toString()),
            _buildSummaryRow(
                'Facturación:', Publications.getFormatoPrecio(value: cashRegister.billing)),
            _buildSummaryRow(
                'Descuentos:', Publications.getFormatoPrecio(value: cashRegister.discount)),
            _buildSummaryRow(
                'Ingresos:', Publications.getFormatoPrecio(value: cashRegister.cashInFlow)),
            _buildSummaryRow(
                'Egresos:', Publications.getFormatoPrecio(value: cashRegister.cashOutFlow)),
            const Divider(),
            _buildSummaryRow(
              'Balance Esperado:',
              Publications.getFormatoPrecio(value: cashRegister.getExpectedBalance),
              true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, [bool isTotal = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCloseCashRegister(
    BuildContext context,
    CashRegisterProvider cashRegisterProvider,
    SellProvider sellProvider,
  ) async {
    final success = await cashRegisterProvider.closeCashRegister(
      sellProvider.profileAccountSelected.id,
      cashRegister.id,
    );

    if (success && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
