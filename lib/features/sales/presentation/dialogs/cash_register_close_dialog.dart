import '../../../../../../../core/core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/presentation/widgets/success/process_success_view.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';

/// Diálogo para cerrar una caja registradora
class CashRegisterCloseDialog extends StatefulWidget {
  final CashRegister cashRegister;
  final bool fullView;

  const CashRegisterCloseDialog({
    super.key,
    required this.cashRegister,
    this.fullView = false,
  });

  @override
  State<CashRegisterCloseDialog> createState() =>
      _CashRegisterCloseDialogState();
}

class _CashRegisterCloseDialogState extends State<CashRegisterCloseDialog> {
  double _currentDifference = 0.0;
  late CashRegisterProvider _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<CashRegisterProvider>();
  }

  @override
  void initState() {
    super.initState();
    // Limpiar errores previos al inicializar el diálogo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _provider.clearError();

        // Limpiar el campo de balance final para empezar con valor vacío
        _provider.finalBalanceController.clear();

        // Escuchar cambios en el balance final para calcular la diferencia en tiempo real
        _provider.finalBalanceController.addListener(_updateDifference);
      }
    });
  }

  @override
  void dispose() {
    // Remover el listener cuando se destruya el widget
    _provider.finalBalanceController.removeListener(_updateDifference);
    super.dispose();
  }

  void _updateDifference() {
    if (mounted) {
      setState(() {
        final finalBalance = _provider.finalBalanceController.doubleValue;
        final expectedBalance = widget.cashRegister.getExpectedBalance;

        // Diferencia = Balance Final (lo que hay) - Balance Esperado (lo que debería haber)
        // Positivo = sobrante (verde), Negativo = faltante (rojo)
        _currentDifference = finalBalance - expectedBalance;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cashRegisterProvider = context.watch<CashRegisterProvider>();

    return BaseDialog(
      title: 'Cierre de Caja',
      icon: Icons.lock_rounded,
      width: 500,
      fullView: widget.fullView,
      headerColor:
          Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DialogComponents.sectionSpacing,
          _buildSummaryCard(context),
          const SizedBox(height: 16),
          MoneyInputTextField(
            controller: cashRegisterProvider.finalBalanceController,
            labelText: 'Balance Final',
          ),
          // Mostrar diferencia en tiempo real mientras el usuario escribe
          if (_currentDifference != 0) ...[
            const SizedBox(height: 12),
            Text(
              'Diferencia: ${CurrencyFormatter.formatPrice(value: _currentDifference.abs())}',
              style: TextStyle(
                color: _currentDifference < 0 ? Colors.red : Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 16),
          // text : Mensaje de error si existe
          if (cashRegisterProvider.errorMessage != null)
            Text(
              cashRegisterProvider.errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          DialogComponents.sectionSpacing,
        ],
      ),
      actions: [
        // button : Cerrar caja
        Consumer<SalesProvider>(
          builder: (context, sellProvider, child) {
            return DialogComponents.primaryActionButton(
              context: context,
              text: 'Confirmar Cierre',
              icon: Icons.lock_rounded,
              isLoading: cashRegisterProvider.isProcessing,
              onPressed: () {
                if (cashRegisterProvider.isProcessing) return;
                _handleCloseCashRegister(
                  context,
                  cashRegisterProvider,
                  sellProvider,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      elevation: 0,
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
    SalesProvider sellProvider,
  ) async {
    // Mostrar ProcessSuccessView mientras se ejecuta el cierre
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProcessSuccessView(
          loadingText: 'Cerrando caja...',
          successTitle: '¡Caja cerrada!',
          successSubtitle: widget.cashRegister.description,
          finalText: 'Balance: ${CurrencyFormatter.formatPrice(value: _provider.finalBalanceController.doubleValue)}',
          popCount: 2, // Cerrar ProcessSuccessView + CashRegisterCloseDialog
          action: () async {
            final success = await cashRegisterProvider.closeCashRegister(
              sellProvider.profileAccountSelected.id,
              widget.cashRegister.id,
            );
            
            if (!success) {
              throw Exception(cashRegisterProvider.errorMessage ?? 'Error al cerrar la caja');
            }
          },
          onError: (error) {
            // Mostrar error con SnackBar
            if (context.mounted) {
              Navigator.of(context).pop(); // Cerrar ProcessSuccessView
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error.toString().replaceAll('Exception: ', '')),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
