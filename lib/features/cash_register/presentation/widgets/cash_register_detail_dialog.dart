import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';

/// Diálogo de detalle de arqueo de caja
class CashRegisterDetailDialog extends StatelessWidget {
  final CashRegister cashRegister;

  const CashRegisterDetailDialog({
    super.key,
    required this.cashRegister,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = cashRegister.closure.year == 1970;
    final subtitle = DateFormat('dd MMMM yyyy').format(cashRegister.opening);

    return BaseDialog(
      title: 'Detalle de Caja',
      subtitle: subtitle,
      icon: Icons.point_of_sale_rounded,
      width: 550,
      maxHeight: 700,
      content: _buildContent(context, isOpen),
      actions: [
        TextButton.icon(
          onPressed: () => _handlePrint(context),
          icon: const Icon(Icons.print_outlined),
          label: const Text('Imprimir'),
        ),
        AppButton.primary(
          text: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, bool isOpen) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Estado y información básica
        _buildStatusBadge(theme, colorScheme, isOpen),
        const SizedBox(height: 24),

        // Información General de la Caja
        _buildCashInfoSection(theme, colorScheme, isOpen),
        const SizedBox(height: 24),

        // Movimientos de Caja
        _buildCashMovementsSection(theme, colorScheme),
        const SizedBox(height: 24),

        // Resumen Financiero
        _buildFinancialSummary(theme, colorScheme, isOpen),
      ],
    );
  }

  Widget _buildStatusBadge(ThemeData theme, ColorScheme colorScheme, bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOpen 
            ? Colors.green.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOpen 
              ? Colors.green.withValues(alpha: 0.2)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: isOpen ? Colors.green : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'CAJA ABIERTA' : 'CAJA CERRADA',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isOpen ? Colors.green.shade700 : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashInfoSection(ThemeData theme, ColorScheme colorScheme, bool isOpen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de sección
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Información General',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grid compacto de información
          Row(
            children: [
              Expanded(
                child: _CompactInfoItem(
                  icon: Icons.access_time,
                  label: 'Apertura',
                  value: DateFormat('HH:mm').format(cashRegister.opening),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CompactInfoItem(
                  icon: Icons.access_time_filled,
                  label: 'Cierre',
                  value: isOpen ? '-' : DateFormat('HH:mm').format(cashRegister.closure),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CompactInfoItem(
                  icon: Icons.person_outline,
                  label: 'Cajero',
                  value: cashRegister.nameUser.isNotEmpty 
                      ? cashRegister.nameUser.split('@')[0] 
                      : 'N/A',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CompactInfoItem(
                  icon: Icons.receipt_long,
                  label: 'Ventas',
                  value: '${cashRegister.getEffectiveSales}/${cashRegister.sales}',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Detalles de ventas
          _InfoRow(
            label: 'Caja Inicial',
            value: CurrencyFormatter.formatPrice(value: cashRegister.initialCash),
            theme: theme,
            isBold: true,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Facturación (efectivo)',
            value: CurrencyFormatter.formatPrice(value: cashRegister.billing),
            theme: theme,
            valueColor: Colors.green,
          ),
          if (cashRegister.annulledTickets > 0) ...[
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Tickets anulados',
              value: '${cashRegister.annulledTickets}',
              theme: theme,
              valueColor: Colors.red,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCashMovementsSection(ThemeData theme, ColorScheme colorScheme) {
    final hasInflows = cashRegister.cashInFlowList.isNotEmpty;
    final hasOutflows = cashRegister.cashOutFlowList.isNotEmpty;
    
    if (!hasInflows && !hasOutflows) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              'Sin movimientos de caja registrados',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.swap_vert, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Movimientos de Caja',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Ingresos
        if (hasInflows) ...[
          _MovementCard(
            title: 'Ingresos',
            icon: Icons.arrow_downward,
            color: Colors.green,
            total: cashRegister.cashInFlow,
            count: cashRegister.cashInFlowList.length,
            items: cashRegister.cashInFlowList.map((flowData) {
              final flow = CashFlow.fromMap(flowData);
              return _MovementItem(
                description: flow.description,
                amount: flow.amount,
                color: Colors.green,
              );
            }).toList(),
          ),
          if (hasOutflows) const SizedBox(height: 12),
        ],

        // Egresos
        if (hasOutflows)
          _MovementCard(
            title: 'Egresos',
            icon: Icons.arrow_upward,
            color: Colors.red,
            total: cashRegister.cashOutFlow.abs(),
            count: cashRegister.cashOutFlowList.length,
            items: cashRegister.cashOutFlowList.map((flowData) {
              final flow = CashFlow.fromMap(flowData);
              return _MovementItem(
                description: flow.description,
                amount: flow.amount.abs(),
                color: Colors.red,
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildFinancialSummary(ThemeData theme, ColorScheme colorScheme, bool isOpen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Resumen Financiero',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Balance esperado
          _InfoRow(
            label: 'Balance Esperado',
            value: CurrencyFormatter.formatPrice(value: cashRegister.getExpectedBalance),
            theme: theme,
          ),
          
          // Balance contabilizado (solo cajas cerradas)
          if (!isOpen) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Balance Contabilizado',
              value: CurrencyFormatter.formatPrice(value: cashRegister.balance),
              theme: theme,
              isBold: true,
              valueColor: colorScheme.primary,
            ),
            
            // Diferencia
            if (cashRegister.getDifference != 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (cashRegister.getDifference > 0 ? Colors.green : Colors.red)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (cashRegister.getDifference > 0 ? Colors.green : Colors.red)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          cashRegister.getDifference > 0 
                              ? Icons.trending_up 
                              : Icons.trending_down,
                          size: 20,
                          color: cashRegister.getDifference > 0 
                              ? Colors.green.shade700 
                              : Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Diferencia',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cashRegister.getDifference > 0 
                                ? Colors.green.shade700 
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.formatPrice(value: cashRegister.getDifference),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cashRegister.getDifference > 0 
                            ? Colors.green.shade700 
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _handlePrint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de impresión en desarrollo'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// Widget helpers

class _CompactInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CompactInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final bool isBold;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.theme,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _MovementCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double total;
  final int count;
  final List<Widget> items;

  const _MovementCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.total,
    required this.count,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Header del card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  CurrencyFormatter.formatPrice(value: total),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de items
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: items,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementItem extends StatelessWidget {
  final String description;
  final double amount;
  final Color color;

  const _MovementItem({
    required this.description,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.circle,
              size: 6,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            CurrencyFormatter.formatPrice(value: amount),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
