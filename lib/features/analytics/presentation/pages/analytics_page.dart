import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/core/presentation/widgets/navigation/drawer.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import '../../domain/entities/date_filter.dart';
import '../providers/analytics_provider.dart';
import '../widgets/active_cash_registers_card.dart';
import '../widgets/analytics_skeleton.dart';
import '../widgets/category_distribution_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/month_grouped_transactions_list.dart';
import '../widgets/payment_methods_card.dart';
import '../widgets/peak_hours_card.dart';
import '../widgets/products_metric_card.dart';
import '../widgets/profitability_metric_card.dart';
import '../widgets/reorderable_analytics_grid.dart';
import '../widgets/sales_trend_card.dart';
import '../widgets/seller_ranking_card.dart';
import '../widgets/slow_moving_products_card.dart';
import '../widgets/weekday_sales_card.dart';

/// Página: Analíticas
///
/// **Responsabilidad:**
/// - Mostrar métricas de ventas del negocio
/// - Filtrar transacciones por período de tiempo
/// - Mostrar lista de transacciones
/// - Gestionar estados: loading, error, success
///
/// **Métricas mostradas:**
/// - Total de transacciones
/// - Ganancia total (formateada con NumberFormat.currency)
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: const AppDrawer(),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, _) {
          return _buildContent(context, provider);
        },
      ),
    );
  }

  /// Construye el contenido según el estado
  Widget _buildContent(BuildContext context, AnalyticsProvider provider) {
    // Estado: Loading inicial - usar skeleton animado
    if (provider.isLoading && !provider.hasData) {
      return const SingleChildScrollView(
        child: AnalyticsSkeleton(),
      );
    }

    // Estado: Error
    if (provider.errorMessage != null && !provider.hasData) {
      return _buildErrorState(context, provider.errorMessage!);
    }

    // Estado: Success
    if (provider.hasData) {
      return _buildSuccessState(context, provider);
    }

    // Estado: Sin datos (inicial)
    return _buildEmptyState(context);
  }

  /// Construye el estado de éxito con las métricas y lista
  Widget _buildSuccessState(BuildContext context, AnalyticsProvider provider) {
    final analytics = provider.analytics!;
    // Obtenemos el provider de cajas para mostrar las cajas activas
    final cashRegisterProvider = context.watch<CashRegisterProvider>();
    final activeCashRegisters = cashRegisterProvider.activeCashRegisters;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        //
        // Grid de Métricas y Tarjetas (Responsive Layout)
        //
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;

                // DISEÑO COMPACTO VERTICAL (pantallas muy pequeñas < 600px)
                if (screenWidth < 600) {
                  return _buildMobileLayout(
                      context, analytics, activeCashRegisters);
                }
                // DISEÑO TABLET (600px - 900px)
                else if (screenWidth < 900) {
                  return _buildTabletLayout(
                      context, analytics, activeCashRegisters);
                }
                // DISEÑO DESKTOP (≥ 900px)
                else {
                  return _buildDesktopLayout(
                      context, analytics, activeCashRegisters);
                }
              },
            ),
          ),
        ),
        //
        // view : lista de transacciones
        //
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Transacciones',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ),
        ),

        // Lista de Transacciones agrupadas por mes
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          sliver: MonthGroupedTransactionsList(
            transactions: analytics.transactions,
            isMonthExpanded: provider.isMonthExpanded,
            onToggleMonth: provider.toggleMonthExpansion,
            onTransactionTap: (transaction) =>
                _showTransactionDetail(context, transaction),
          ),
        ),
      ],
    );
  }

  /// Layout para pantallas móviles (< 600px)
  /// Grid de 2 columnas con drag-and-drop para reordenar
  Widget _buildMobileLayout(
    BuildContext context,
    dynamic analytics,
    List<CashRegister> activeCashRegisters,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final gap = (screenWidth * 0.025).clamp(8.0, 16.0);

    // Lista de tarjetas con keys únicos para el reordering
    final List<Widget> cards = [
      // 1. Facturación - Destacada
      MetricCard(
        key: const ValueKey('billing'),
        title: 'Facturación',
        value: CurrencyHelper.formatCurrency(analytics.totalSales),
        icon: Icons.attach_money_rounded,
        color: const Color(0xFF059669),
        subtitle: 'Ingresos brutos',
        isZero: analytics.totalSales == 0,
        moreInformation: true,
      ),

      // 2. Ganancia
      MetricCard(
        key: const ValueKey('profit'),
        title: 'Ganancia',
        value: CurrencyHelper.formatCurrency(analytics.totalProfit),
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF7C3AED),
        isZero: analytics.totalProfit == 0,
      ),

      // 3. Ventas
      MetricCard(
        key: const ValueKey('sales'),
        title: 'Ventas',
        value: analytics.totalTransactions.toString(),
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF2563EB),
        isZero: analytics.totalTransactions == 0,
      ),

      // 4. Ticket Promedio
      MetricCard(
        key: const ValueKey('averageTicket'),
        title: 'Ticket Prom.',
        value: CurrencyHelper.formatCurrency(
            analytics.averageProfitPerTransaction),
        icon: Icons.analytics_rounded,
        color: const Color(0xFF0891B2),
        isZero: analytics.averageProfitPerTransaction == 0,
      ),

      // 5. Productos Vendidos
      ProductsMetricCard(
        key: const ValueKey('products'),
        totalProducts: analytics.totalProductsSold,
        topSellingProducts: analytics.topSellingProducts,
        color: const Color(0xFFD97706),
        isZero: analytics.totalProductsSold == 0,
      ),

      // 6. Rentabilidad
      ProfitabilityMetricCard(
        key: const ValueKey('profitability'),
        totalProfit: analytics.totalProfit,
        mostProfitableProducts: analytics.mostProfitableProducts,
        color: const Color(0xFF10B981),
        isZero: analytics.mostProfitableProducts.isEmpty,
      ),

      // 7. Lenta Rotación
      SlowMovingProductsCard(
        key: const ValueKey('slowMoving'),
        slowMovingProducts: analytics.slowMovingProducts,
        color: const Color(0xFFEF4444),
        isZero: analytics.slowMovingProducts.isEmpty,
      ),

      // 8. Horas Pico
      PeakHoursCard(
        key: const ValueKey('peakHours'),
        salesByHour: analytics.salesByHour,
        peakHours: analytics.peakHours,
        color: const Color(0xFFF59E0B),
        isZero: analytics.peakHours.isEmpty,
      ),

      // 9. Ranking de Vendedores
      SellerRankingCard(
        key: const ValueKey('sellerRanking'),
        salesBySeller: analytics.salesBySeller,
        color: const Color(0xFF8B5CF6),
        isZero: analytics.salesBySeller.isEmpty,
      ),

      // 10. Tendencia de Ventas
      SalesTrendCard(
        key: const ValueKey('salesTrend'),
        salesByDay: analytics.salesByDay,
        color: const Color(0xFF3B82F6),
        isZero: analytics.salesByDay.isEmpty,
      ),

      // 11. Distribución por Categorías
      CategoryDistributionCard(
        key: const ValueKey('categoryDist'),
        salesByCategory: analytics.salesByCategory,
        totalSales: analytics.totalSales,
        color: const Color(0xFFEC4899),
        isZero: analytics.salesByCategory.isEmpty,
      ),

      // 12. Días de Venta
      WeekdaySalesCard(
        key: const ValueKey('weekdaySales'),
        salesByWeekday: analytics.salesByWeekday,
        color: const Color(0xFF6366F1),
        isZero: analytics.salesByWeekday.isEmpty,
      ),

      // 13. Medios de Pago
      PaymentMethodsCard(
        key: const ValueKey('paymentMethods'),
        paymentMethodsBreakdown: analytics.paymentMethodsBreakdown,
        totalSales: analytics.totalSales,
      ),

      // 14. Cajas Activas (si existen)
      if (activeCashRegisters.isNotEmpty)
        ActiveCashRegistersCard(
          key: const ValueKey('cashRegisters'),
          activeCashRegisters: activeCashRegisters,
        ),
    ];

    return ReorderableAnalyticsGrid(
      layoutType: 'mobile',
      crossAxisCount: 2,
      gap: gap,
      childAspectRatio: 1.1,
      enableReordering: true,
      children: cards,
    );
  }

  /// Layout para tablets (600px - 900px)
  /// Grid de 3 columnas con drag-and-drop para reordenar
  Widget _buildTabletLayout(
    BuildContext context,
    dynamic analytics,
    List<CashRegister> activeCashRegisters,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final gap = (screenWidth * 0.015).clamp(8.0, 12.0);

    // Lista de tarjetas con keys únicos para el reordering
    final List<Widget> cards = [
      // 1. Facturación - Destacada
      MetricCard(
        key: const ValueKey('billing'),
        title: 'Facturación',
        value: CurrencyHelper.formatCurrency(analytics.totalSales),
        icon: Icons.attach_money_rounded,
        color: const Color(0xFF059669),
        subtitle: 'Ingresos brutos',
        isZero: analytics.totalSales == 0,
        moreInformation: true,
      ),

      // 2. Ganancia
      MetricCard(
        key: const ValueKey('profit'),
        title: 'Ganancia',
        value: CurrencyHelper.formatCurrency(analytics.totalProfit),
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF7C3AED),
        subtitle: 'Rentabilidad real',
        isZero: analytics.totalProfit == 0,
      ),

      // 3. Ventas
      MetricCard(
        key: const ValueKey('sales'),
        title: 'Ventas',
        value: analytics.totalTransactions.toString(),
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF2563EB),
        isZero: analytics.totalTransactions == 0,
      ),

      // 4. Ticket Promedio
      MetricCard(
        key: const ValueKey('averageTicket'),
        title: 'Ticket Prom.',
        value: CurrencyHelper.formatCurrency(
            analytics.averageProfitPerTransaction),
        icon: Icons.analytics_rounded,
        color: const Color(0xFF0891B2),
        isZero: analytics.averageProfitPerTransaction == 0,
      ),

      // 5. Productos Vendidos
      ProductsMetricCard(
        key: const ValueKey('products'),
        totalProducts: analytics.totalProductsSold,
        topSellingProducts: analytics.topSellingProducts,
        color: const Color(0xFFD97706),
        isZero: analytics.totalProductsSold == 0,
        subtitle: 'Movimiento de inventario',
      ),

      // 6. Rentabilidad
      ProfitabilityMetricCard(
        key: const ValueKey('profitability'),
        totalProfit: analytics.totalProfit,
        mostProfitableProducts: analytics.mostProfitableProducts,
        color: const Color(0xFF10B981),
        isZero: analytics.mostProfitableProducts.isEmpty,
        subtitle: 'Productos más rentables',
      ),

      // 7. Ranking de Vendedores
      SellerRankingCard(
        key: const ValueKey('sellerRanking'),
        salesBySeller: analytics.salesBySeller,
        color: const Color(0xFF8B5CF6),
        isZero: analytics.salesBySeller.isEmpty,
        subtitle: 'Desempeño del equipo',
      ),

      // 8. Horas Pico
      PeakHoursCard(
        key: const ValueKey('peakHours'),
        salesByHour: analytics.salesByHour,
        peakHours: analytics.peakHours,
        color: const Color(0xFFF59E0B),
        isZero: analytics.peakHours.isEmpty,
        subtitle: 'Mayor actividad',
      ),

      // 9. Productos de Lenta Rotación
      SlowMovingProductsCard(
        key: const ValueKey('slowMoving'),
        slowMovingProducts: analytics.slowMovingProducts,
        color: const Color(0xFFEF4444),
        isZero: analytics.slowMovingProducts.isEmpty,
        subtitle: 'Requieren atención',
      ),

      // 10. Tendencia de Ventas
      SalesTrendCard(
        key: const ValueKey('salesTrend'),
        salesByDay: analytics.salesByDay,
        color: const Color(0xFF3B82F6),
        isZero: analytics.salesByDay.isEmpty,
        subtitle: 'Evolución temporal',
      ),

      // 11. Distribución por Categorías
      CategoryDistributionCard(
        key: const ValueKey('categoryDist'),
        salesByCategory: analytics.salesByCategory,
        totalSales: analytics.totalSales,
        color: const Color(0xFFEC4899),
        isZero: analytics.salesByCategory.isEmpty,
        subtitle: 'Ventas por categoría',
      ),

      // 12. Días de Venta
      WeekdaySalesCard(
        key: const ValueKey('weekdaySales'),
        salesByWeekday: analytics.salesByWeekday,
        color: const Color(0xFF6366F1),
        isZero: analytics.salesByWeekday.isEmpty,
        subtitle: 'Rendimiento semanal',
      ),

      // 13. Medios de Pago
      PaymentMethodsCard(
        key: const ValueKey('paymentMethods'),
        paymentMethodsBreakdown: analytics.paymentMethodsBreakdown,
        totalSales: analytics.totalSales,
      ),

      // 14. Cajas Activas (si existen)
      if (activeCashRegisters.isNotEmpty)
        ActiveCashRegistersCard(
          key: const ValueKey('cashRegisters'),
          activeCashRegisters: activeCashRegisters,
        ),
    ];

    return ReorderableAnalyticsGrid(
      layoutType: 'tablet',
      crossAxisCount: 3,
      gap: gap,
      maxWidth: 900,
      childAspectRatio: 1.2,
      enableReordering: true,
      children: cards,
    );
  }

  /// Layout para desktop (≥ 900px)
  /// Grid de 4 columnas uniforme con drag-and-drop para reordenar
  Widget _buildDesktopLayout(
    BuildContext context,
    dynamic analytics,
    List<CashRegister> activeCashRegisters,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final gap = (screenWidth * 0.01).clamp(10.0, 14.0);

    // Lista de tarjetas con keys únicos para el reordering
    final List<Widget> cards = [
      // 1. Facturación - Destacada
      MetricCard(
        key: const ValueKey('billing'),
        title: 'Facturación',
        value: CurrencyHelper.formatCurrency(analytics.totalSales),
        icon: Icons.attach_money_rounded,
        color: const Color(0xFF059669),
        subtitle: 'Ingresos brutos',
        isZero: analytics.totalSales == 0,
        moreInformation: true,
      ),

      // 2. Ganancia
      MetricCard(
        key: const ValueKey('profit'),
        title: 'Ganancia',
        value: CurrencyHelper.formatCurrency(analytics.totalProfit),
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF7C3AED),
        subtitle: 'Rentabilidad real',
        isZero: analytics.totalProfit == 0,
      ),

      // 3. Ventas
      MetricCard(
        key: const ValueKey('sales'),
        title: 'Ventas',
        value: analytics.totalTransactions.toString(),
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF2563EB),
        isZero: analytics.totalTransactions == 0,
      ),

      // 4. Ticket Promedio
      MetricCard(
        key: const ValueKey('averageTicket'),
        title: 'Ticket Prom.',
        value: CurrencyHelper.formatCurrency(
            analytics.averageProfitPerTransaction),
        icon: Icons.analytics_rounded,
        color: const Color(0xFF0891B2),
        isZero: analytics.averageProfitPerTransaction == 0,
      ),

      // 5. Productos Vendidos
      ProductsMetricCard(
        key: const ValueKey('products'),
        totalProducts: analytics.totalProductsSold,
        topSellingProducts: analytics.topSellingProducts,
        color: const Color(0xFFD97706),
        isZero: analytics.totalProductsSold == 0,
        subtitle: 'Movimiento de inventario',
      ),

      // 6. Rentabilidad
      ProfitabilityMetricCard(
        key: const ValueKey('profitability'),
        totalProfit: analytics.totalProfit,
        mostProfitableProducts: analytics.mostProfitableProducts,
        color: const Color(0xFF10B981),
        isZero: analytics.mostProfitableProducts.isEmpty,
        subtitle: 'Productos más rentables',
      ),

      // 7. Ranking de Vendedores
      SellerRankingCard(
        key: const ValueKey('sellerRanking'),
        salesBySeller: analytics.salesBySeller,
        color: const Color(0xFF8B5CF6),
        isZero: analytics.salesBySeller.isEmpty,
        subtitle: 'Desempeño del equipo',
      ),

      // 8. Horas Pico
      PeakHoursCard(
        key: const ValueKey('peakHours'),
        salesByHour: analytics.salesByHour,
        peakHours: analytics.peakHours,
        color: const Color(0xFFF59E0B),
        isZero: analytics.peakHours.isEmpty,
        subtitle: 'Mayor actividad por hora',
      ),

      // 9. Productos de Lenta Rotación
      SlowMovingProductsCard(
        key: const ValueKey('slowMoving'),
        slowMovingProducts: analytics.slowMovingProducts,
        color: const Color(0xFFEF4444),
        isZero: analytics.slowMovingProducts.isEmpty,
        subtitle: 'Requieren atención',
      ),

      // 10. Tendencia de Ventas
      SalesTrendCard(
        key: const ValueKey('salesTrend'),
        salesByDay: analytics.salesByDay,
        color: const Color(0xFF3B82F6),
        isZero: analytics.salesByDay.isEmpty,
        subtitle: 'Evolución temporal',
      ),

      // 11. Distribución por Categorías
      CategoryDistributionCard(
        key: const ValueKey('categoryDist'),
        salesByCategory: analytics.salesByCategory,
        totalSales: analytics.totalSales,
        color: const Color(0xFFEC4899),
        isZero: analytics.salesByCategory.isEmpty,
        subtitle: 'Ventas por categoría',
      ),

      // 12. Días de Venta
      WeekdaySalesCard(
        key: const ValueKey('weekdaySales'),
        salesByWeekday: analytics.salesByWeekday,
        color: const Color(0xFF6366F1),
        isZero: analytics.salesByWeekday.isEmpty,
        subtitle: 'Rendimiento semanal',
      ),

      // 13. Medios de Pago
      PaymentMethodsCard(
        key: const ValueKey('paymentMethods'),
        paymentMethodsBreakdown: analytics.paymentMethodsBreakdown,
        totalSales: analytics.totalSales,
      ),

      // 14. Cajas Activas (si existen)
      if (activeCashRegisters.isNotEmpty)
        ActiveCashRegistersCard(
          key: const ValueKey('cashRegisters'),
          activeCashRegisters: activeCashRegisters,
        ),
    ];

    return ReorderableAnalyticsGrid(
      layoutType: 'desktop',
      crossAxisCount: 4,
      gap: gap,
      maxWidth: 1400,
      childAspectRatio: 1.3,
      enableReordering: true,
      children: cards,
    );
  }

  /// Construye el AppBar personalizado
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final salesProvider = context.read<SalesProvider>();

    return CustomAppBar(
      toolbarHeight: 70,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      titleWidget: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // Avatar y botón de drawer
            Builder(
              builder: (context) => GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: UserAvatar(
                  imageUrl: salesProvider.profileAccountSelected.image,
                  text: salesProvider.profileAccountSelected.name,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Título
            Text(
              'Analíticas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      actions: [
        // PopupMenu de filtros
        Consumer<AnalyticsProvider>(
          builder: (context, provider, _) {
            final hasActiveFilter = provider.selectedFilter != DateFilter.today;
            final filterLabel = provider.selectedFilter.label;

            return PopupMenuButton<DateFilter>(
              tooltip: 'Filtrar por fecha',
              offset: const Offset(0, 50),
              splashRadius: 24,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IgnorePointer(
                    child: AppBarButtonCircle(
                      icon: Icons.filter_list_rounded,
                      text: filterLabel,
                      tooltip: 'Filtrar por fecha',
                      onPressed: () {},
                      backgroundColor: hasActiveFilter
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      colorAccent: hasActiveFilter
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  // Badge indicador de filtro activo sobre el ícono
                  if (hasActiveFilter)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              onSelected: (DateFilter filter) {
                provider.setDateFilter(filter);
              },
              itemBuilder: (BuildContext context) {
                return DateFilter.values.map((DateFilter filter) {
                  final isSelected = filter == provider.selectedFilter;
                  return PopupMenuItem<DateFilter>(
                    value: filter,
                    child: Row(
                      children: [
                        if (isSelected)
                          Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 12),
                        Text(
                          filter.label,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
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
        const SizedBox(width: 8),
      ],
    );
  }

  /// Construye el estado de error
  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar analíticas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el estado vacío (sin datos)
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay datos de analíticas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Realiza algunas ventas para ver las métricas',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// Muestra el diálogo de detalle de transacción
  void _showTransactionDetail(BuildContext context, TicketModel transaction) {
    final salesProvider = context.read<SalesProvider>();
    final cashRegisterProvider = context.read<CashRegisterProvider>();

    // Capturar referencias necesarias antes del callback asíncrono
    final accountId = salesProvider.profileAccountSelected.id;
    final messenger = ScaffoldMessenger.of(context);

    showTicketDetailDialog(
      fullView: true,
      context: context,
      ticket: transaction,
      businessName: salesProvider.profileAccountSelected.name.isNotEmpty
          ? salesProvider.profileAccountSelected.name
          : 'PUNTO DE VENTA',
      title: 'Detalle de Transacción',
      onTicketAnnulled: transaction.annulled
          ? null
          : () async {
              final success = await cashRegisterProvider.annullTicket(
                accountId: accountId,
                ticket: transaction,
              );

              if (success) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Ticket anulado exitosamente'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content:
                        Text('Error al anular el ticket. Inténtalo nuevamente'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
    );
  }
}
