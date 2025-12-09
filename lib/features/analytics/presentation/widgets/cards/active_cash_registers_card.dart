import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/utils/formatters/date_formatter.dart';
import 'package:sellweb/core/utils/helpers/currency_helper.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import '../core/widgets.dart';

/// Widget: Tarjeta de Cajas Registradoras Activas
///
/// **Responsabilidad:**
/// - Mostrar lista de cajas registradoras activas
/// - Mostrar nombre, balance y total de transacciones de cada caja
/// - Diseño minimalista consistente con otras tarjetas de analytics
///
/// **Usa:** [AnalyticsBaseCard] como base visual consistente
class ActiveCashRegistersCard extends StatelessWidget {
  final List<CashRegister> activeCashRegisters;

  /// Color de la tarjeta (debe venir del registro para consistencia)
  final Color color;

  const ActiveCashRegistersCard({
    super.key,
    required this.activeCashRegisters,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = activeCashRegisters.isEmpty;
    final count = activeCashRegisters.length;

    return AnalyticsBaseCard(
      color: color,
      isZero: isEmpty,
      icon: Icons.point_of_sale_rounded,
      title: 'Cajas Activas',
      subtitle: isEmpty
          ? null
          : '$count ${count == 1 ? 'caja abierta' : 'cajas abiertas'}',
      expandChild: true, // Expandir para poder alinear al fondo
      showActionIndicator: !isEmpty,
      onTap: isEmpty ? null : () => _showCashRegistersModal(context),
      child: isEmpty
          ? const AnalyticsEmptyState(message: 'No hay cajas activas')
          : LayoutBuilder(
              builder: (context, constraints) {
                // Si hay solo 1 caja, mostrar UI detallada actual
                if (count == 1) {
                  return _buildSingleCashRegisterView(context, constraints);
                }
                // Si hay múltiples cajas, mostrar UI simple (máximo 3)
                return _buildMultipleCashRegistersView(context, constraints);
              },
            ),
    );
  }

  /// Vista detallada para una sola caja activa (UI actual)
  Widget _buildSingleCashRegisterView(
      BuildContext context, BoxConstraints constraints) {
    final isCompact = constraints.maxWidth < 200;
    final cashRegister = activeCashRegisters.first;

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildCashRegisterItem(context, cashRegister, color, isCompact),
        ],
      ),
    );
  }

  /// Vista simple para múltiples cajas activas (máximo 3 visibles)
  Widget _buildMultipleCashRegistersView(
      BuildContext context, BoxConstraints constraints) {
    // Mostrar máximo 3 cajas
    const maxVisibleCashRegisters = 3;
    final visibleRegisters =
        activeCashRegisters.take(maxVisibleCashRegisters).toList();
    final remainingCount = activeCashRegisters.length - maxVisibleCashRegisters;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ...visibleRegisters.map((cashRegister) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child:
                  _buildSimpleCashRegisterRow(context, cashRegister, color),
            );
          }),
          // Mostrar indicador si hay más cajas
          if (remainingCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+$remainingCount más',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  /// Fila simple para mostrar una caja activa (indicador verde, nombre, balance)
  Widget _buildSimpleCashRegisterRow(
    BuildContext context,
    CashRegister cashRegister,
    Color color,
  ) {
    final theme = Theme.of(context);
    final name = cashRegister.description.isNotEmpty
        ? cashRegister.description
        : 'Caja sin nombre';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Indicador verde de caja activa
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          // Nombre de la caja
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Balance total
          Text(
            CurrencyHelper.formatCurrency(cashRegister.getExpectedBalance),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showCashRegistersModal(BuildContext context) {
    // Capturar providers antes de abrir el modal
    final cashRegisterProvider = context.read<CashRegisterProvider>();
    final salesProvider = context.read<SalesProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ActiveCashRegistersModal(
        activeCashRegisters: activeCashRegisters,
        cashRegisterProvider: cashRegisterProvider,
        accountId: salesProvider.profileAccountSelected.id,
        accentColor: color,
      ),
    );
  }

  Widget _buildCashRegisterItem(
    BuildContext context,
    CashRegister cashRegister,
    Color color,
    bool isCompact,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isCompact ? 8 : 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Indicador visual de caja activa
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              // Nombre de la caja
              Expanded(
                child: Text(
                  cashRegister.description.isNotEmpty
                      ? cashRegister.description
                      : 'Caja sin nombre',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    fontSize: isCompact ? 12 : 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Tiempo transcurrido (ocultar en muy compacto si choca)
              if (!isCompact) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.timelapse_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormatter.getElapsedTime(
                      fechaInicio: cashRegister.opening),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // Fila inferior con operador y balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tiempo transcurrido (ocultar en muy compacto si choca)
              if (isCompact) ...[
                Flexible(
                  child: Row(
                    children: [
                      Icon(
                        Icons.timelapse_rounded,
                        size: 14,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatter.getElapsedTime(
                            fechaInicio: cashRegister.opening),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Operador
              if (!isCompact) ...[
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: isCompact ? 12 : 14,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          cashRegister.nameUser.isNotEmpty
                              ? cashRegister.nameUser
                              : 'Sin operador',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontSize: isCompact ? 10 : 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              ],
              const SizedBox(width: 8),
              // Balance
              Text(
                CurrencyHelper.formatCurrency(cashRegister.getExpectedBalance),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: isCompact ? 12 : 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Modal: Detalle completo de Cajas Activas con tiles expandibles
class ActiveCashRegistersModal extends StatefulWidget {
  final List<CashRegister> activeCashRegisters;
  final CashRegisterProvider cashRegisterProvider;
  final String accountId;

  /// Color de acento para el modal (consistencia con la tarjeta)
  final Color accentColor;

  const ActiveCashRegistersModal({
    super.key,
    required this.activeCashRegisters,
    required this.cashRegisterProvider,
    required this.accountId,
    required this.accentColor,
  });

  @override
  State<ActiveCashRegistersModal> createState() =>
      _ActiveCashRegistersModalState();
}

class _ActiveCashRegistersModalState extends State<ActiveCashRegistersModal> {
  // Track expansion state for each cash register by index
  final Map<int, bool> _expandedStates = {};

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Calcular totales consolidados
    // Balance total (esperado)
    final totalBalance = widget.activeCashRegisters.fold<double>(
      0.0,
      (sum, register) => sum + register.getExpectedBalance,
    );
    // Total de transacciones (tickets)
    final totalTransactions = widget.activeCashRegisters.fold<int>(
      0,
      (sum, register) => sum + register.sales,
    );
    // Facturación total (suma de montos de tickets)
    final totalBilling = widget.activeCashRegisters.fold<double>(
      0.0,
      (sum, register) => sum + register.billing,
    );

    return AnalyticsModal(
      accentColor: widget.accentColor,
      icon: Icons.point_of_sale_rounded,
      title: 'Cajas Activas',
      subtitle: '${widget.activeCashRegisters.length} ${widget.activeCashRegisters.length == 1 ? 'caja abierta' : 'cajas abiertas'}',
      child: widget.activeCashRegisters.isEmpty
          ? const AnalyticsModalEmptyState(
              icon: Icons.point_of_sale_outlined,
              title: 'No hay cajas activas',
              subtitle: 'Abre una caja para comenzar a operar',
            )
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                // Tarjeta de resumen consolidado primero
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: AnalyticsStatusCard(
                    statusColor: widget.accentColor,
                    icon: Icons.account_balance_wallet_rounded,
                    mainValue: CurrencyHelper.formatCurrency(totalBalance),
                    mainLabel: 'Balance Total Consolidado',
                    leftMetric: AnalyticsMetric(
                      value: '$totalTransactions',
                      label: 'Transacciones',
                    ),
                    rightMetric: AnalyticsMetric(
                      value: CurrencyHelper.formatCurrency(totalBilling),
                      label: 'Facturación',
                    ),
                    feedbackIcon: Icons.info_outline,
                    feedbackText: 'Suma de todas las cajas activas',
                  ),
                ),
                // Lista de cajas individuales
                ...List.generate(
                  widget.activeCashRegisters.length,
                  (index) {
                    final cashRegister = widget.activeCashRegisters[index];
                    final isExpanded = _expandedStates[index] ?? false;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: _buildExpandableCashRegisterTile(
                        context,
                        cashRegister,
                        dateFormat,
                        index + 1,
                        index,
                        isExpanded,
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  /// Tile expandible para mostrar información de una caja
  Widget _buildExpandableCashRegisterTile(
    BuildContext context,
    CashRegister cashRegister,
    DateFormat dateFormat,
    int position,
    int index,
    bool isExpanded,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Nombre de la caja
    final cashName = cashRegister.description.isNotEmpty
        ? cashRegister.description
        : 'Caja $position';

    // Operador
    final operatorName = cashRegister.nameUser.isNotEmpty
        ? cashRegister.nameUser
        : 'Sin operador asignado';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedStates[index] = expanded;
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.point_of_sale_rounded,
                  color: widget.accentColor,
                  size: 22,
                ),
              ),
              // Punto verde pequeño indicando estado activo (sobre el icono)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  cashName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Ocultar tiempo cuando está expandido
              if (!isExpanded) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.22),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timelapse_rounded,
                        size: 12,
                        color: widget.accentColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormatter.getElapsedTime(
                            fechaInicio: cashRegister.opening),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: widget.accentColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                // Operador
                Icon(
                  Icons.person_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    operatorName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Ocultar balance cuando está expandido
                if (!isExpanded) ...[
                  const SizedBox(width: 8),
                  Text(
                    CurrencyHelper.formatCurrency(
                        cashRegister.getExpectedBalance),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: widget.accentColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          children: [
            _buildExpandedContent(context, cashRegister, dateFormat),
          ],
        ),
      ),
    );
  }

  /// Contenido expandido con detalles de la caja
  Widget _buildExpandedContent(
    BuildContext context,
    CashRegister cashRegister,
    DateFormat dateFormat,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider sutil
        Container(
          height: 1,
          margin: const EdgeInsets.only(bottom: 12),
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),

        // Tiempo activo destacado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.timelapse_rounded,
                size: 18,
                color: widget.accentColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiempo activo',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.getElapsedTime(
                          fechaInicio: cashRegister.opening),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                dateFormat.format(cashRegister.opening),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Estadísticas de transacciones
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                label: 'Transacciones',
                value: '${cashRegister.sales}',
                icon: Icons.receipt_long_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                label: 'Efectivas',
                value: '${cashRegister.getEffectiveSales}',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                label: 'Anulados',
                value: '${cashRegister.annulledTickets}',
                icon: Icons.cancel_rounded,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Balance Total destacado
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                'Balance Total',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Text(
                CurrencyHelper.formatCurrency(cashRegister.getExpectedBalance),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Grid de métricas financieras
        Row(
          children: [
            // Facturación
            Expanded(
              child: _buildMetricTile(
                context,
                icon: Icons.attach_money_rounded,
                label: 'Facturación',
                value: CurrencyHelper.formatCurrency(cashRegister.billing),
                color: const Color(0xFF059669),
              ),
            ),
            const SizedBox(width: 12),
            // Monto inicial
            Expanded(
              child: _buildMetricTile(
                context,
                icon: Icons.savings_rounded,
                label: 'Fondo inicial',
                value: CurrencyHelper.formatCurrency(cashRegister.initialCash),
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            // Ingresos
            Expanded(
              child: _buildMetricTile(
                context,
                icon: Icons.arrow_downward_rounded,
                label: 'Ingresos',
                value: CurrencyHelper.formatCurrency(
                    cashRegister.getTotalIngresos),
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            // Egresos
            Expanded(
              child: _buildMetricTile(
                context,
                icon: Icons.arrow_upward_rounded,
                label: 'Egresos',
                value:
                    CurrencyHelper.formatCurrency(cashRegister.getTotalEgresos),
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Descuentos
        _DiscountMetricTile(
          cashRegister: cashRegister,
          accentColor: widget.accentColor,
          cashRegisterProvider: widget.cashRegisterProvider,
          accountId: widget.accountId,
        ),
      ],
    );
  }

  /// Widget para mostrar estadísticas de transacciones (como en flujo de caja)
  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Icon(
                icon,
                size: 18,
                color: color.withValues(alpha: 0.7),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget que calcula y muestra los descuentos desde los tickets
/// Usa StreamBuilder para obtener el valor real de descuentos
class _DiscountMetricTile extends StatelessWidget {
  final CashRegister cashRegister;
  final Color accentColor;
  final CashRegisterProvider cashRegisterProvider;
  final String accountId;

  const _DiscountMetricTile({
    required this.cashRegister,
    required this.accentColor,
    required this.cashRegisterProvider,
    required this.accountId,
  });

  static const _discountColor = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<List<TicketModel>>(
      stream: cashRegisterProvider.getCashRegisterTicketsStream(
        accountId: accountId,
        cashRegisterId: cashRegister.id,
      ),
      builder: (context, snapshot) {
        // Calcular descuento desde tickets si están disponibles
        double totalDiscount = cashRegister.discount; // fallback

        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty) {
          totalDiscount = cashRegister.calculateTotalDiscount(snapshot.data!);
        }

        return Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _discountColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _discountColor.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.discount_rounded,
                          size: 14,
                          color: _discountColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Descuentos',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyHelper.formatCurrency(totalDiscount),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        );
      },
    );
  }
}
