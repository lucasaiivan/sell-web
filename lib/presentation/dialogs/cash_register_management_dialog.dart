import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/cash_register_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cash_register_provider.dart';
import '../providers/sell_provider.dart';
import 'cash_flow_dialog.dart';
import 'cash_register_close_dialog.dart';
import 'cash_register_open_dialog.dart';

/// Diálogo principal para administrar cajas registradoras.
class CashRegisterManagementDialog extends StatelessWidget {
  const CashRegisterManagementDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(16),
      titlePadding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      title: Row(
        children: [
          const Icon(Icons.point_of_sale, size: 28),
          const SizedBox(width: 8),
          Text(
            'Administración de Caja',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: Builder(
        builder: (context) {
          // Capturar los providers de manera segura
          final provider = context.watch<CashRegisterProvider>();
          // Acceder a SellProvider sin escuchar cambios ya que solo necesitamos el ID
          final accountId = Provider.of<SellProvider>(context, listen: false)
              .profileAccountSelected.id;

          if (provider.isLoadingActive) {
            return const SizedBox(
              height: 100,
              width: 400,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (provider.hasActiveCashRegister) 
                    _buildActiveCashRegister(context, provider)
                  else
                    _buildNoCashRegister(context),
                  const Divider(height: 32),
                  _buildCashFlowButtons(context, provider),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveCashRegister(BuildContext context, CashRegisterProvider provider) {
    final cashRegister = provider.currentActiveCashRegister!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.monetization_on, size: 40, color: Colors.green),
          title: Text(
            cashRegister.description,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            'Saldo actual: \$${cashRegister.getExpectedBalance.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          trailing: TextButton.icon(
            icon: const Icon(Icons.lock_outlined),
            label: const Text('Cerrar Caja'),
            onPressed: () => _showCloseDialog(context, cashRegister),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  context,
                  'Ventas',
                  cashRegister.sales.toString(),
                  Icons.shopping_cart,
                ),
                _buildStatColumn(
                  context,
                  'Facturación',
                  '\$${cashRegister.billing.toStringAsFixed(2)}',
                  Icons.attach_money,
                ),
                _buildStatColumn(
                  context,
                  'Descuentos',
                  '\$${cashRegister.discount.toStringAsFixed(2)}',
                  Icons.local_offer,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNoCashRegister(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.point_of_sale_outlined,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay ninguna caja abierta',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Abrir Nueva Caja'),
            onPressed: () => _showOpenDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowButtons(BuildContext context, CashRegisterProvider provider) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Ingreso'),
          onPressed: provider.hasActiveCashRegister
              ? () => _showCashFlowDialog(context, true)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.remove_circle_outline),
          label: const Text('Egreso'),
          onPressed: provider.hasActiveCashRegister
              ? () => _showCashFlowDialog(context, false)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showOpenDialog(BuildContext context) {
    // Capturar los providers antes de mostrar el diálogo
    final cashRegisterProvider = Provider.of<CashRegisterProvider>(context, listen: false);
    final sellProvider = Provider.of<SellProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CashRegisterProvider>.value(value: cashRegisterProvider),
          ChangeNotifierProvider<SellProvider>.value(value: sellProvider),
        ],
        child: const CashRegisterOpenDialog(),
      ),
    );
  }

  void _showCloseDialog(BuildContext context, CashRegister cashRegister) {
    // Capturar los providers antes de mostrar el diálogo
    final cashRegisterProvider = Provider.of<CashRegisterProvider>(context, listen: false);
    final sellProvider = Provider.of<SellProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CashRegisterProvider>.value(value: cashRegisterProvider),
          ChangeNotifierProvider<SellProvider>.value(value: sellProvider),
        ],
        child: CashRegisterCloseDialog(cashRegister: cashRegister),
      ),
    );
  }

  void _showCashFlowDialog(BuildContext context, bool isInflow) {
    // Capturar todos los providers necesarios antes de mostrar el diálogo
    final cashRegisterProvider = Provider.of<CashRegisterProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sellProvider = Provider.of<SellProvider>(context, listen: false);
    
    if (!cashRegisterProvider.hasActiveCashRegister) return;

    final cashRegister = cashRegisterProvider.currentActiveCashRegister!;

    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CashRegisterProvider>.value(value: cashRegisterProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<SellProvider>.value(value: sellProvider),
        ],
        child: CashFlowDialog(
          isInflow: isInflow,
          cashRegisterId: cashRegister.id,
          accountId: sellProvider.profileAccountSelected.id,
          userId: authProvider.user?.email ?? '',
        ),
      ),
    );
  }
}
