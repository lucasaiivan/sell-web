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

    // Mostrar máximo 3 cajas
    final visibleRegisters = activeCashRegisters.take(3).toList();

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
                // Determinar si debemos mostrar versión compacta basado en el ancho
                final isCompact = constraints.maxWidth < 160;

                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: visibleRegisters.map((cashRegister) {
                      final isLast = visibleRegisters.indexOf(cashRegister) ==
                          visibleRegisters.length - 1;

                      return Column(
                        children: [
                          _buildCashRegisterItem(
                              context, cashRegister, color, isCompact),
                          if (!isLast) ...[
                            const SizedBox(height: 8),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: color.withValues(alpha: 0.1),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
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
              // Operador
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
              ),
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

/// Modal: Detalle completo de Cajas Activas
class ActiveCashRegistersModal extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return AnalyticsModal(
      accentColor: accentColor,
      icon: Icons.point_of_sale_rounded,
      title: 'Cajas Activas',
      subtitle:
          '${activeCashRegisters.length} ${activeCashRegisters.length == 1 ? 'caja abierta' : 'cajas abiertas'}',
      child: activeCashRegisters.isEmpty
          ? const AnalyticsModalEmptyState(
              icon: Icons.point_of_sale_outlined,
              title: 'No hay cajas activas',
              subtitle: 'Abre una caja para comenzar a operar',
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: activeCashRegisters.length,
              itemBuilder: (context, index) {
                final cashRegister = activeCashRegisters[index];
                return _buildCashRegisterDetailCard(
                  context,
                  cashRegister,
                  dateFormat,
                  index + 1,
                );
              },
            ),
    );
  }

  Widget _buildCashRegisterDetailCard(
    BuildContext context,
    CashRegister cashRegister,
    DateFormat dateFormat,
    int position,
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
          color: accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Nombre de la caja y estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.point_of_sale_rounded,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cashName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              operatorName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge de estado activo
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Activa',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tiempo activo destacado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timelapse_rounded,
                    size: 18,
                    color: accentColor,
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
                            color: accentColor,
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

            const SizedBox(height: 16),

            // Divider
            Container(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),

            const SizedBox(height: 16),

            // Estadísticas de transacciones (como en flujo de caja)
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

            const SizedBox(height: 16),

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
                    CurrencyHelper.formatCurrency(
                        cashRegister.getExpectedBalance),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

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
                    value:
                        CurrencyHelper.formatCurrency(cashRegister.initialCash),
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
                    value: CurrencyHelper.formatCurrency(
                        cashRegister.getTotalEgresos),
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Descuentos - calculados desde tickets para mayor precisión
            _DiscountMetricTile(
              cashRegister: cashRegister,
              accentColor: accentColor,
              cashRegisterProvider: cashRegisterProvider,
              accountId: accountId,
            ),
          ],
        ),
      ),
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
