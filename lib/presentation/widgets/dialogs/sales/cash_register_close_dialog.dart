import '../../../../../../core/core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/cash_register_model.dart';
import '../../../../presentation/providers/cash_register_provider.dart';
import '../../../../presentation/providers/sell_provider.dart';

/// Diálogo para cerrar una caja registradora
class CashRegisterCloseDialog extends StatefulWidget {
  final CashRegister cashRegister;

  const CashRegisterCloseDialog({
    super.key,
    required this.cashRegister,
  });

  @override
  State<CashRegisterCloseDialog> createState() =>
      _CashRegisterCloseDialogState();
}

class _CashRegisterCloseDialogState extends State<CashRegisterCloseDialog> {
  @override
  void initState() {
    super.initState();
    // Limpiar errores previos al inicializar el diálogo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<CashRegisterProvider>();
        provider.clearError();

        // Limpiar el campo de balance final para empezar con valor vacío
        provider.finalBalanceController.clear();
      }
    });
  }

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
              if (widget.cashRegister.getDifference != 0) ...[
                Text(
                  'Diferencia: ${CurrencyFormatter.formatPrice(value: widget.cashRegister.getDifference)}',
                  style: TextStyle(
                    color: widget.cashRegister.getDifference < 0
                        ? Colors.red
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              // text : Mensaje de error si existe
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
        Row(
          children: [
            const Spacer(),
            // button : Cerrar caja
            Consumer<SellProvider>(
              builder: (context, sellProvider, child) {
                return DialogComponents.primaryActionButton(
                    context: context,
                    text: 'Confirmar',
                    isLoading: cashRegisterProvider.isProcessing,
                    icon: Icons.exit_to_app_rounded,
                    onPressed: () {
                      if (cashRegisterProvider.isProcessing) return;
                      _handleCloseCashRegister(
                        context,
                        cashRegisterProvider,
                        sellProvider,
                      );
                    });
              },
            ),
            // button : Cancelar cierre de caja
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
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
            _buildSummaryRow(
                'Monto Inicial:',
                CurrencyFormatter.formatPrice(
                    value: widget.cashRegister.initialCash)),
            _buildSummaryRow('Ventas:', widget.cashRegister.sales.toString()),
            _buildSummaryRow(
                'Facturación:',
                CurrencyFormatter.formatPrice(
                    value: widget.cashRegister.billing)),
            _buildSummaryRow(
                'Descuentos:',
                CurrencyFormatter.formatPrice(
                    value: widget.cashRegister.discount)),
            _buildSummaryRow(
                'Ingresos:',
                CurrencyFormatter.formatPrice(
                    value: widget.cashRegister.cashInFlow)),
            _buildSummaryRow(
                'Egresos:',
                CurrencyFormatter.formatPrice(
                    value: widget.cashRegister.cashOutFlow)),
            const Divider(),
            _buildSummaryRow(
              'Balance Esperado:',
              CurrencyFormatter.formatPrice(
                  value: widget.cashRegister.getExpectedBalance),
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
      widget.cashRegister.id,
    );

    if (success && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
