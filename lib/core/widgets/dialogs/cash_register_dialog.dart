import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/presentation/providers/cash_register_provider.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';
import 'package:sellweb/presentation/providers/auth_provider.dart';
import 'package:sellweb/domain/entities/cash_register_model.dart';
import 'base_dialog.dart';
import 'dialog_components.dart';

/// Diálogo para abrir una nueva caja registradora
class CashRegisterOpenDialog extends StatelessWidget {
  const CashRegisterOpenDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cashRegisterProvider = context.watch<CashRegisterProvider>();

    return BaseDialog(
      title: 'Apertura de Caja',
      icon: Icons.add_circle_outline_rounded,
      width: 400,
      content: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DialogComponents.textField(
                    context: context,
                    controller: cashRegisterProvider.openDescriptionController,
                    label: 'Descripción',
                    hint: 'Ej: Caja Principal',
                    prefixIcon: Icons.description_outlined,
                  ),
                  DialogComponents.sectionSpacing,
                  DialogComponents.textField(
                    context: context,
                    controller: cashRegisterProvider.initialCashController,
                    label: 'Monto Inicial',
                    hint: '0.00',
                    prefixIcon: Icons.attach_money_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
            ),
            if (cashRegisterProvider.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: theme.colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cashRegisterProvider.errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        Consumer<SellProvider>(
          builder: (context, sellProvider, child) {
            return DialogComponents.primaryActionButton(
              context: context,
              text: 'Abrir Caja',
              icon: Icons.check_rounded,
              isLoading: cashRegisterProvider.isProcessing,
              onPressed: cashRegisterProvider.isProcessing
                  ? null
                  : () => _handleOpenCashRegister(
                        context,
                        cashRegisterProvider,
                        sellProvider,
                      ),
            );
          },
        ),
      ],
    );
  }
 // _handleOpenCashRegister : pertura de una caja registradora
  Future<void> _handleOpenCashRegister(
    BuildContext context,
    CashRegisterProvider cashRegisterProvider,
    SellProvider sellProvider,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await cashRegisterProvider.openCashRegister(
      sellProvider.profileAccountSelected.id,
      authProvider.user?.email ?? '',
    );

    if (success && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Diálogo para cerrar una caja registradora
class CashRegisterCloseDialog extends StatelessWidget {
  final CashRegister cashRegister;

  const CashRegisterCloseDialog({
    super.key,
    required this.cashRegister,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cashRegisterProvider = context.watch<CashRegisterProvider>();

    return BaseDialog(
      title: 'Cierre de Caja',
      icon: Icons.lock_outline_rounded,
      width: 400,
      content: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSummaryCard(context),
                    DialogComponents.sectionSpacing,
                    Text(
                      '¿Estás seguro de que deseas cerrar esta caja?',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (cashRegisterProvider.errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: theme.colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cashRegisterProvider.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        Consumer<SellProvider>(
          builder: (context, sellProvider, child) {
            return DialogComponents.primaryActionButton(
              context: context,
              text: 'Cerrar Caja',
              icon: Icons.lock_rounded,
              isDestructive: true,
              isLoading: cashRegisterProvider.isProcessing,
              onPressed: cashRegisterProvider.isProcessing
                  ? null
                  : () => _handleCloseCashRegister(
                        context,
                        cashRegisterProvider,
                        sellProvider,
                      ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de Caja',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, 'Monto Inicial:', 
              '\$${cashRegister.initialCash.toStringAsFixed(2)}'),
          _buildInfoRow(context, 'Ventas:', 
              '\$${cashRegister.billing.toStringAsFixed(2)}'),
          _buildInfoRow(context, 'Ingresos:', 
              '\$${cashRegister.cashInFlow.toStringAsFixed(2)}'),
          _buildInfoRow(context, 'Egresos:', 
              '\$${cashRegister.cashOutFlow.toStringAsFixed(2)}'),
          const Divider(),
          _buildInfoRow(context, 'Balance Esperado:', 
              '\$${cashRegister.getExpectedBalance.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
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

/// Diálogo para registrar un movimiento de caja (ingreso o egreso)
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
    final theme = Theme.of(context);
    final provider = context.watch<CashRegisterProvider>();

    final title = isInflow ? 'Ingreso de Efectivo' : 'Egreso de Efectivo';
    final icon = isInflow 
        ? Icons.add_circle_outline_rounded 
        : Icons.remove_circle_outline_rounded;

    return BaseDialog(
      title: title,
      icon: icon,
      width: 400,
      content: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DialogComponents.textField(
                    context: context,
                    controller: provider.movementAmountController,
                    label: 'Monto',
                    hint: '0.00',
                    prefixIcon: Icons.attach_money_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  DialogComponents.sectionSpacing,
                  DialogComponents.textField(
                    context: context,
                    controller: provider.movementDescriptionController,
                    label: 'Descripción',
                    hint: 'Motivo del ${isInflow ? "ingreso" : "egreso"}',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            if (provider.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: theme.colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DialogComponents.primaryActionButton(
          context: context,
          text: isInflow ? 'Registrar Ingreso' : 'Registrar Egreso',
          icon: icon,
          isLoading: provider.isProcessing,
          isDestructive: !isInflow,
          onPressed: provider.isProcessing ? null : () => _handleFlow(context, provider),
        ),
      ],
    );
  }

  Future<void> _handleFlow(
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

/// Diálogo principal para administrar cajas registradoras (Material Design 3).
class CashRegisterManagementDialog extends StatelessWidget {
  const CashRegisterManagementDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BaseDialog(
      title: 'Administración de Caja',
      icon: Icons.point_of_sale_rounded,
      width: 500,
      content: Consumer<CashRegisterProvider>(
        builder: (context, provider, __) {
          if (provider.isLoadingActive) {
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              height: 100,
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (provider.hasActiveCashRegister) 
                        // Si hay una caja activa, mostrar sus detalles
                        _buildActiveCashRegister(context, provider)
                      else
                        // Si no hay caja activa, mostrar mensaje y botón para abrir una nueva
                        _buildNoCashRegister(context),
                      DialogComponents.sectionSpacing,
                      // Botones para registrar ingresos o egresos
                      _buildCashFlowButtons(context, provider),
                    ],
                  ),
                ),
                if (provider.errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: theme.colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildActiveCashRegister(BuildContext context, CashRegisterProvider provider) {
    final cashRegister = provider.currentActiveCashRegister!;
    
    return DialogComponents.infoSection(
      context: context,
      title: 'Caja Activa',
      icon: Icons.account_balance_rounded,
      content: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DialogComponents.infoRow(
                  context: context,
                  label: 'Descripción',
                  value: cashRegister.description,
                  icon: Icons.description_outlined,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.lock_outline_rounded),
                tooltip: 'Cerrar caja',
                onPressed: () => showCashRegisterCloseDialog(
                  context,
                  cashRegister: cashRegister,
                ),
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ),
          DialogComponents.minSpacing,
          Row(
            children: [
              Expanded(
                child: DialogComponents.infoRow(
                  context: context,
                  label: 'Monto Inicial',
                  value: '\$${cashRegister.initialCash.toStringAsFixed(2)}',
                  icon: Icons.play_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DialogComponents.infoRow(
                  context: context,
                  label: 'Total en Caja',
                  value: '\$${cashRegister.getExpectedBalance.toStringAsFixed(2)}',
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),
            ],
          ),
          DialogComponents.minSpacing,
          Row(
            children: [
              Expanded(
                child: DialogComponents.infoRow(
                  context: context,
                  label: 'Ingresos',
                  value: '\$${(cashRegister.cashInFlow + cashRegister.billing).toStringAsFixed(2)}',
                  icon: Icons.add_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DialogComponents.infoRow(
                  context: context,
                  label: 'Egresos',
                  value: '\$${cashRegister.cashOutFlow.toStringAsFixed(2)}',
                  icon: Icons.remove_circle_outline_rounded,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoCashRegister(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24), 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.point_of_sale_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay ninguna caja abierta',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          DialogComponents.primaryActionButton(
            context: context,
            text: 'Abrir Nueva Caja',
            icon: Icons.add_rounded,
            onPressed: () => showCashRegisterOpenDialog(context),
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
        DialogComponents.primaryActionButton(
          context: context,
          text: 'Ingreso',
          icon: Icons.add_circle_outline_rounded,
          onPressed: provider.hasActiveCashRegister
              ? () => _showCashFlowDialog(context, true)
              : null,
        ),
        DialogComponents.primaryActionButton(
          context: context,
          text: 'Egreso',
          icon: Icons.remove_circle_outline_rounded,
          isDestructive: true,
          onPressed: provider.hasActiveCashRegister
              ? () => _showCashFlowDialog(context, false)
              : null,
        )
      ],
    );
  }

  void _showCashFlowDialog(BuildContext context, bool isInflow) {
    final provider = Provider.of<CashRegisterProvider>(context, listen: false);
    final sellProvider = Provider.of<SellProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!provider.hasActiveCashRegister) return;

    final cashRegister = provider.currentActiveCashRegister!;

    showCashFlowDialog(
      context,
      isInflow: isInflow,
      cashRegisterId: cashRegister.id,
      accountId: sellProvider.profileAccountSelected.id,
      userId: authProvider.user?.email ?? '',
    );
  }
}

/// Helper functions para mostrar los diálogos de caja registradora
Future<void> showCashRegisterOpenDialog(BuildContext context) {
  final cashRegisterProvider = Provider.of<CashRegisterProvider>(context, listen: false);
  final sellProvider = Provider.of<SellProvider>(context, listen: false);
  
  return showDialog(
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

Future<void> showCashRegisterCloseDialog(
  BuildContext context, {
  required CashRegister cashRegister,
}) {
  final cashRegisterProvider = Provider.of<CashRegisterProvider>(context, listen: false);
  final sellProvider = Provider.of<SellProvider>(context, listen: false);

  return showDialog(
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

Future<void> showCashFlowDialog(
  BuildContext context, {
  required bool isInflow,
  required String cashRegisterId,
  required String accountId,
  required String userId,
}) {
  final cashRegisterProvider = Provider.of<CashRegisterProvider>(context, listen: false);

  return showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider<CashRegisterProvider>.value(
      value: cashRegisterProvider,
      child: CashFlowDialog(
        isInflow: isInflow,
        cashRegisterId: cashRegisterId,
        accountId: accountId,
        userId: userId,
      ),
    ),
  );
}

/// Helper function para mostrar el diálogo de administración de caja
Future<void> showCashRegisterManagementDialog(BuildContext context) {
  final cashRegisterProvider = Provider.of<CashRegisterProvider>(context, listen: false);
  final sellProvider = Provider.of<SellProvider>(context, listen: false);
  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  return showDialog(
    context: context,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider<CashRegisterProvider>.value(value: cashRegisterProvider),
        ChangeNotifierProvider<SellProvider>.value(value: sellProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: const CashRegisterManagementDialog(),
    ),
  );
}
