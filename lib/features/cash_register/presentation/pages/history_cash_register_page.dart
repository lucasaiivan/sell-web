import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/core/presentation/widgets/navigation/drawer.dart';
import 'package:sellweb/features/cash_register/presentation/widgets/cash_register_detail_dialog.dart';
import 'package:intl/intl.dart';

class HistoryCashRegisterPage extends StatefulWidget {
  const HistoryCashRegisterPage({super.key});

  @override
  State<HistoryCashRegisterPage> createState() => _HistoryCashRegisterPageState();
}

class _HistoryCashRegisterPageState extends State<HistoryCashRegisterPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  void _loadHistory() {
    final sellProvider = context.read<SalesProvider>();
    final cashRegisterProvider = context.read<CashRegisterProvider>();
    if (sellProvider.profileAccountSelected.id.isNotEmpty) {
      cashRegisterProvider.loadCashRegisterHistory(sellProvider.profileAccountSelected.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: const AppDrawer(),
      body: Consumer<CashRegisterProvider>(
        builder: (context, provider, child) {
          return _buildContent(context, provider);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final sellProvider = context.read<SalesProvider>();
    final theme = Theme.of(context);

    return AppBar(
      toolbarHeight: 70,
      titleSpacing: 0,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Builder(
              builder: (context) => GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: UserAvatar(
                  imageUrl: sellProvider.profileAccountSelected.image,
                  text: sellProvider.profileAccountSelected.name,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Historial de Cajas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      actions: [
        Consumer<CashRegisterProvider>(
          builder: (context, provider, _) {
            return PopupMenuButton<String>(
              tooltip: 'Filtrar historial',
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IgnorePointer(
                  child: AppBarButtonCircle(
                    icon: Icons.filter_list_rounded,
                    text: provider.historyFilter,
                    tooltip: 'Filtrar historial',
                    onPressed: () {},
                    backgroundColor: theme.colorScheme.primaryContainer,
                    colorAccent: theme.colorScheme.primary,
                  ),
                ),
              ),
              onSelected: (String newValue) {
                provider.setHistoryFilter(newValue, sellProvider.profileAccountSelected.id);
              },
              itemBuilder: (BuildContext context) {
                return <String>[
                  'Última semana',
                  'Último mes',
                  'Mes anterior',
                  'Todo'
                ].map<PopupMenuItem<String>>((String value) {
                  final isSelected = value == provider.historyFilter;
                  return PopupMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        if (isSelected)
                          Icon(Icons.check_rounded, size: 18, color: theme.colorScheme.primary)
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 12),
                        Text(
                          value,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? theme.colorScheme.primary : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, CashRegisterProvider provider) {
    if (provider.isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return _buildErrorState(context, provider.errorMessage!);
    }

    final hasActiveCashRegisters = provider.activeCashRegisters.isNotEmpty;
    final historyItems = provider.cashRegisterHistory;

    if (!hasActiveCashRegisters && historyItems.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      itemCount: (hasActiveCashRegisters ? provider.activeCashRegisters.length : 0) + 
                  historyItems.length,
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Divider(
          height: 0.5,
          thickness: 0.5,
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      itemBuilder: (context, index) {
        // Mostrar cajas activas al principio
        if (hasActiveCashRegisters && index < provider.activeCashRegisters.length) {
          final cashRegister = provider.activeCashRegisters[index];
          return _CashRegisterItem(cashRegister: cashRegister);
        }
        
        // Luego mostrar historial cerrado
        final historyIndex = index - (hasActiveCashRegisters ? provider.activeCashRegisters.length : 0);
        final cashRegister = historyItems[historyIndex];
        return _CashRegisterItem(cashRegister: cashRegister);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 64,
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay historial disponible',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta cambiar el filtro de fecha',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error al cargar el historial',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              text: 'Reintentar',
              onPressed: _loadHistory,
            ),
          ],
        ),
      ),
    );
  }
}

class _CashRegisterItem extends StatelessWidget {
  final CashRegister cashRegister;

  const _CashRegisterItem({required this.cashRegister});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOpen = cashRegister.closure.year == 1970;
    
    // Mostrar balance esperado si: caja está abierta O balance contabilizado es 0
    final shouldShowExpected = isOpen || cashRegister.balance == 0;
    final displayBalance = shouldShowExpected ? cashRegister.getExpectedBalance : cashRegister.balance;
    final balanceLabel = shouldShowExpected ? 'Balance' : 'Contabilizado';

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => CashRegisterDetailDialog(
            cashRegister: cashRegister,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Icono de estado
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isOpen 
                    ? Colors.green.withValues(alpha: 0.1) 
                    : colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.point_of_sale_rounded,
                color: isOpen ? Colors.green : colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            
            // Info Principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila 1: Fecha y badge de estado
                  Row(
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(cashRegister.opening),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isOpen) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            'ABIERTA',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Fila 2: Metadatos (hora, ventas)
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('HH:mm').format(cashRegister.opening)} - ${isOpen ? "Ahora" : DateFormat('HH:mm').format(cashRegister.closure)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Separador circular
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.receipt_long, size: 14, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '${cashRegister.getEffectiveSales} ${cashRegister.getEffectiveSales == 1 ? "venta" : "ventas"}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Balance (trailing)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CurrencyFormatter.formatPrice(value: displayBalance),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  balanceLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
