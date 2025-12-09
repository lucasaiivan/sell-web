import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import '../../../domain/entities/date_filter.dart';
import '../transactions/widgets.dart';

/// Diálogo para mostrar la lista completa de transacciones
///
/// **Responsabilidad:**
/// - Mostrar todas las transacciones agrupadas por mes
/// - Permitir expandir/colapsar meses
/// - Navegar al detalle de transacciones
///
/// **Nota:** Usa estado interno para gestionar la expansión de meses
/// ya que el diálogo se renderiza fuera del árbol del Provider.
class TransactionsDialog extends StatefulWidget {
  final List<TicketModel> transactions;
  final void Function(TicketModel) onTransactionTap;
  final DateFilter currentFilter;

  const TransactionsDialog({
    super.key,
    required this.transactions,
    required this.onTransactionTap,
    required this.currentFilter,
  });

  @override
  State<TransactionsDialog> createState() => _TransactionsDialogState();
}

class _TransactionsDialogState extends State<TransactionsDialog> {
  // Estado local para meses expandidos (todos expandidos por defecto)
  final Set<String> _expandedMonths = {};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inicializar todos los meses como expandidos la primera vez
    if (!_initialized && widget.transactions.isNotEmpty) {
      _initializeExpandedMonths();
      _initialized = true;
    }
  }

  void _initializeExpandedMonths() {
    // Obtener todos los meses únicos
    final Set<String> uniqueMonths = {};
    for (final transaction in widget.transactions) {
      final monthKey = _getMonthKey(transaction.creation);
      uniqueMonths.add(monthKey);
    }

    // Si hay solo un mes, expandirlo por defecto
    // Si hay múltiples meses, dejarlos todos colapsados
    if (uniqueMonths.length == 1) {
      _expandedMonths.addAll(uniqueMonths);
    }
    // Si hay más de 1 mes, _expandedMonths queda vacío (todos colapsados)
  }

  String _getMonthKey(dynamic timestamp) {
    final date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  bool _isMonthExpanded(String monthKey) {
    return _expandedMonths.contains(monthKey);
  }

  void _toggleMonth(String monthKey) {
    setState(() {
      if (_expandedMonths.contains(monthKey)) {
        _expandedMonths.remove(monthKey);
      } else {
        _expandedMonths.add(monthKey);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Transacciones'),
          actions: [
            // Mostrar filtro actual
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: AppBarButtonCircle(
                  text: widget.currentFilter.label,
                  tooltip: 'Filtro actual',
                  onPressed: () {}, // Read-only en el diálogo
                  backgroundColor: theme.colorScheme.primaryContainer,
                  colorAccent: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        body: widget.transactions.isEmpty
            ? _buildEmptyState(context)
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: MonthGroupedTransactionsList(
                      transactions: widget.transactions,
                      isMonthExpanded: _isMonthExpanded,
                      onToggleMonth: _toggleMonth,
                      onTransactionTap: widget.onTransactionTap,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay transacciones',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las transacciones aparecerán aquí',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Muestra el diálogo de transacciones
Future<void> showTransactionsDialog({
  required BuildContext context,
  required List<TicketModel> transactions,
  required void Function(TicketModel) onTransactionTap,
  required DateFilter currentFilter,
  // Parámetros opcionales que ya no se usan (mantenidos por compatibilidad)
  bool Function(String)? isMonthExpanded,
  void Function(String)? onToggleMonth,
}) {
  return showDialog(
    context: context,
    builder: (context) => TransactionsDialog(
      transactions: transactions,
      onTransactionTap: onTransactionTap,
      currentFilter: currentFilter,
    ),
  );
}

/// Versión BottomSheet para móviles (alternativa)
Future<void> showTransactionsBottomSheet({
  required BuildContext context,
  required List<TicketModel> transactions,
  required bool Function(String) isMonthExpanded,
  required void Function(String) onToggleMonth,
  required void Function(TicketModel) onTransactionTap,
}) {
  final theme = Theme.of(context);

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Transacciones',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${transactions.length}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Expanded(
              child: transactions.isEmpty
                  ? const Center(
                      child: Text('No hay transacciones'),
                    )
                  : CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: MonthGroupedTransactionsList(
                            transactions: transactions,
                            isMonthExpanded: isMonthExpanded,
                            onToggleMonth: onToggleMonth,
                            onTransactionTap: onTransactionTap,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    ),
  );
}
