import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/components/dialog_components.dart';
import '../../../../domain/entities/cash_register_model.dart';
import '../../../../presentation/providers/auth_provider.dart';
import '../../../../presentation/providers/cash_register_provider.dart';
import '../../../../presentation/providers/sell_provider.dart';
import 'cash_flow_dialog.dart';
import 'cash_register_close_dialog.dart';
import 'cash_register_open_dialog.dart';

/// Diálogo principal para administrar cajas registradoras.
class CashRegisterManagementDialog extends StatelessWidget {
  const CashRegisterManagementDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: 'Administración de Caja',
      icon: Icons.point_of_sale_rounded,
      width: 500, 
      content: Builder(
        builder: (context) {
          final provider = context.watch<CashRegisterProvider>();

          if (provider.isLoadingActive) {
            return const SizedBox(
              height: 120,
              width: double.infinity,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                if (provider.hasActiveCashRegister)
                  // view : Mostrar caja activa
                  _buildActiveCashRegister(context, provider)
                else
                  // view : Mostrar mensaje de no caja activa
                  _buildNoCashRegister(context),
                const SizedBox(height: 32),
                // view : Botones de flujo de caja
                _buildCashFlowButtons(context, provider),
                // view : Mensaje de error si existe
                if (provider.errorMessage != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            provider.errorMessage!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveCashRegister(
      BuildContext context, CashRegisterProvider provider) {
    final theme = Theme.of(context);
    final cashRegister = provider.currentActiveCashRegister!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DialogComponents.infoSection(
          context: context,
          title: 'Caja Activa',
          icon: Icons.point_of_sale_rounded,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cashRegister.description,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              DialogComponents.summaryContainer(
                context: context,
                label: 'Balance Actual',
                value:
                    '\$${cashRegister.getExpectedBalance.toStringAsFixed(2)}',
                icon: Icons.monetization_on_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatColumn(
                        context: context,
                        label: 'Ventas',
                        value: cashRegister.sales.toString(),
                        icon: Icons.shopping_cart_rounded,
                      ),
                    ),
                    Expanded(
                      child: _buildStatColumn(
                        context: context,
                        label: 'Facturación',
                        value: '\$${cashRegister.billing.toStringAsFixed(2)}',
                        icon: Icons.attach_money_rounded,
                      ),
                    ),
                    Expanded(
                      child: _buildStatColumn(
                        context: context,
                        label: 'Descuentos',
                        value: '\$${cashRegister.discount.toStringAsFixed(2)}',
                        icon: Icons.local_offer_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.clear_rounded),
                        label: const Text('Deseleccionar'),
                        onPressed: () => provider.clearSelectedCashRegister(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.lock_outlined),
                        label: const Text('Cerrar Caja'),
                        onPressed: () => _showCloseDialog(context, cashRegister),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 24,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNoCashRegister(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CashRegisterProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (provider.hasAvailableCashRegisters) ...[
          // view : Mostrar lista de cajas disponibles
          Text('Cajas disponibles'),
          const SizedBox(height: 16),
          // Mostrar lista de cajas disponibles
          ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.activeCashRegisters.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cashRegister = provider.activeCashRegisters[index];
                  return _buildCashRegisterTile(context, cashRegister, provider);
                },
              ),
          const SizedBox(height: 24), 
        ] else ...[
          // Mostrar mensaje de no cajas disponibles
          Container(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(
                  Icons.point_of_sale_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay cajas disponibles',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crea una nueva caja para comenzar',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
        FilledButton(
          onPressed: () => _showOpenDialog(context),
          child: const Text('Apertura de nueva caja'),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCashRegisterTile(
    BuildContext context, 
    CashRegister cashRegister, 
    CashRegisterProvider provider
  ) {
    final theme = Theme.of(context);

    // view : Tarjeta de caja registradora
    
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => provider.selectCashRegister(cashRegister),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [ 
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.point_of_sale_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                cashRegister.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashFlowButtons(
      BuildContext context, CashRegisterProvider provider) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Ingreso'),
            onPressed: provider.hasActiveCashRegister
                ? () => _showCashFlowDialog(context, true)
                : null,
            style: OutlinedButton.styleFrom(
              backgroundColor: provider.hasActiveCashRegister
                  ? Colors.green.withValues(alpha: 0.1)
                  : null,
              foregroundColor:
                  provider.hasActiveCashRegister ? Colors.green : null,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.remove_circle_outline_rounded),
            label: const Text('Egreso'),
            onPressed: provider.hasActiveCashRegister
                ? () => _showCashFlowDialog(context, false)
                : null,
            style: OutlinedButton.styleFrom(
              backgroundColor: provider.hasActiveCashRegister
                  ? Colors.red.withOpacity(0.1)
                  : null,
              foregroundColor:
                  provider.hasActiveCashRegister ? Colors.red : null,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showOpenDialog(BuildContext context) {
    // Capturar los providers antes de mostrar el diálogo
    final cashRegisterProvider =
        Provider.of<CashRegisterProvider>(context, listen: false);
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
    final cashRegisterProvider =
        Provider.of<CashRegisterProvider>(context, listen: false);
    final sellProvider = Provider.of<SellProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CashRegisterProvider>.value(
              value: cashRegisterProvider),
          ChangeNotifierProvider<SellProvider>.value(value: sellProvider),
        ],
        child: CashRegisterCloseDialog(cashRegister: cashRegister),
      ),
    );
  }

  void _showCashFlowDialog(BuildContext context, bool isInflow) {
    // Capturar todos los providers necesarios antes de mostrar el diálogo
    final cashRegisterProvider =
        Provider.of<CashRegisterProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sellProvider = Provider.of<SellProvider>(context, listen: false);

    if (!cashRegisterProvider.hasActiveCashRegister) return;

    final cashRegister = cashRegisterProvider.currentActiveCashRegister!;

    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CashRegisterProvider>.value(
              value: cashRegisterProvider),
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
