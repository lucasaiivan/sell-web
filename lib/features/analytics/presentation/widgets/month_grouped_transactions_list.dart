import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'transaction_list_item.dart';

/// Widget: Lista de transacciones agrupadas por mes
///
/// **Responsabilidad:**
/// - Agrupar transacciones por mes con headers colapsables
/// - Mostrar conteo y revenue por mes
/// - Gestionar estado de expansión de cada mes
class MonthGroupedTransactionsList extends StatelessWidget {
  final List<TicketModel> transactions;
  final bool Function(String monthKey) isMonthExpanded;
  final void Function(String monthKey) onToggleMonth;
  final void Function(TicketModel transaction) onTransactionTap;

  const MonthGroupedTransactionsList({
    super.key,
    required this.transactions,
    required this.isMonthExpanded,
    required this.onToggleMonth,
    required this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return _buildEmptyState(context);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final transaction = transactions[index];
          final isLast = index == transactions.length - 1;
          final isFirstInMonth = index == 0 ||
              _isDifferentMonth(
                transactions[index - 1].creation,
                transaction.creation,
              );

          final monthKey = _getMonthKey(transaction.creation);
          final isExpanded = isMonthExpanded(monthKey);
          final transactionsInMonth = _countTransactionsInMonth(index);
          final monthRevenue = _calculateMonthRevenue(index);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de mes (expandible/colapsable)
              if (isFirstInMonth)
                _MonthHeader(
                  label: _getMonthYearLabel(transaction.creation),
                  transactionCount: transactionsInMonth,
                  revenue: monthRevenue,
                  isExpanded: isExpanded,
                  onTap: () => onToggleMonth(monthKey),
                ),

              // Item de transacción (solo si está expandido)
              if (isExpanded) ...[
                TransactionListItem(
                  ticket: transaction,
                  onTap: () => onTransactionTap(transaction),
                ),

                // Divisor entre items del mismo mes
                if (!isLast &&
                    !_isDifferentMonth(
                      transaction.creation,
                      transactions[index + 1].creation,
                    ))
                  Divider(
                    height: 1,
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.2),
                  ),
              ],
            ],
          );
        },
        childCount: transactions.length,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay transacciones en este período',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === Helpers ===

  bool _isDifferentMonth(Timestamp date1, Timestamp date2) {
    final dt1 = date1.toDate();
    final dt2 = date2.toDate();
    return dt1.year != dt2.year || dt1.month != dt2.month;
  }

  String _getMonthKey(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  String _getMonthYearLabel(Timestamp timestamp) {
    final date = timestamp.toDate();
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  int _countTransactionsInMonth(int startIndex) {
    if (startIndex >= transactions.length) return 0;

    final startDate = transactions[startIndex].creation;
    int count = 1;

    for (int i = startIndex + 1; i < transactions.length; i++) {
      if (_isDifferentMonth(startDate, transactions[i].creation)) break;
      count++;
    }

    return count;
  }

  double _calculateMonthRevenue(int startIndex) {
    if (startIndex >= transactions.length) return 0.0;

    final startDate = transactions[startIndex].creation;
    double revenue = transactions[startIndex].priceTotal;

    for (int i = startIndex + 1; i < transactions.length; i++) {
      if (_isDifferentMonth(startDate, transactions[i].creation)) break;
      revenue += transactions[i].priceTotal;
    }

    return revenue;
  }
}

/// Header de mes con indicador de expansión
class _MonthHeader extends StatelessWidget {
  final String label;
  final int transactionCount;
  final double revenue;
  final bool isExpanded;
  final VoidCallback onTap;

  const _MonthHeader({
    required this.label,
    required this.transactionCount,
    required this.revenue,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 12),
        child: Row(
          children: [
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_right_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$transactionCount',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                CurrencyHelper.formatCurrency(revenue),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF059669),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
