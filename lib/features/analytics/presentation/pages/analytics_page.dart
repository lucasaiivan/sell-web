import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../widgets/metric_card.dart';
import '../widgets/payment_methods_card.dart';
import '../widgets/active_cash_registers_card.dart';
import '../widgets/products_metric_card.dart';
import '../widgets/profitability_metric_card.dart';
import '../widgets/seller_ranking_card.dart';
import '../widgets/peak_hours_card.dart';
import '../widgets/slow_moving_products_card.dart';
import '../widgets/transaction_list_item.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

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
    // Estado: Loading inicial
    if (provider.isLoading && !provider.hasData) {
      return const Center(
        child: CircularProgressIndicator(),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: CustomScrollView(
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

          // Lista de Transacciones
          if (analytics.transactions.isEmpty)
            SliverToBoxAdapter(
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
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final transaction = analytics.transactions[index];
                    final isLast = index == analytics.transactions.length - 1;
                    final isFirstInMonth = index == 0 ||
                        _isDifferentMonth(
                          analytics.transactions[index - 1].creation,
                          transaction.creation,
                        );

                    final monthKey = _getMonthKey(transaction.creation);
                    final isExpanded = provider.isMonthExpanded(monthKey);
                    final transactionsInMonth = _countTransactionsInMonth(
                        analytics.transactions, index);
                    final monthRevenue =
                        _calculateMonthRevenue(analytics.transactions, index);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header de mes (expandible/colapsable)
                        if (isFirstInMonth)
                          InkWell(
                            onTap: () =>
                                provider.toggleMonthExpansion(monthKey),
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 20, bottom: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_down_rounded
                                        : Icons.keyboard_arrow_right_rounded,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getMonthYearLabel(transaction.creation),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$transactionsInMonth',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      CurrencyHelper.formatCurrency(
                                          monthRevenue),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: const Color(0xFF059669),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Item de transacción (solo si está expandido)
                        if (isExpanded) ...[
                          TransactionListItem(
                            ticket: transaction,
                            onTap: () =>
                                _showTransactionDetail(context, transaction),
                          ),

                          // Divisor entre items del mismo mes
                          if (!isLast &&
                              !_isDifferentMonth(
                                transaction.creation,
                                analytics.transactions[index + 1].creation,
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
                  childCount: analytics.transactions.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Layout para pantallas móviles (< 600px)
  /// Distribución vertical optimizada para espacio limitado
  Widget _buildMobileLayout(
    BuildContext context,
    dynamic analytics,
    List<CashRegister> activeCashRegisters,
  ) {
    const double gap = 12.0;

    return Column(
      children: [
        // 1. Facturación - Métrica principal destacada (más grande)
        AspectRatio(
          aspectRatio: 2.2,
          child: MetricCard(
            title: 'Facturación',
            value: CurrencyHelper.formatCurrency(analytics.totalSales),
            icon: Icons.attach_money_rounded,
            color: const Color(0xFF059669),
            subtitle: 'Ingresos brutos',
            isZero: analytics.totalSales == 0,
          ),
        ),
        const SizedBox(height: gap),

        // 2-3. Ganancia y Ventas (fila 2x1) - Tarjetas simples
        AspectRatio(
          aspectRatio: 2.5,
          child: Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Ganancia',
                  value: CurrencyHelper.formatCurrency(analytics.totalProfit),
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF7C3AED),
                  isZero: analytics.totalProfit == 0,
                ),
              ),
              const SizedBox(width: gap),
              Expanded(
                child: MetricCard(
                  title: 'Ventas',
                  value: analytics.totalTransactions.toString(),
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF2563EB),
                  isZero: analytics.totalTransactions == 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: gap),

        // 4-5. Ticket Promedio y Productos (fila 2x1) - Aspecto 1:1 para más contenido
        AspectRatio(
          aspectRatio: 2.0,
          child: Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Ticket Prom.',
                  value: CurrencyHelper.formatCurrency(
                      analytics.averageProfitPerTransaction),
                  icon: Icons.analytics_rounded,
                  color: const Color(0xFF0891B2),
                  isZero: analytics.averageProfitPerTransaction == 0,
                ),
              ),
              const SizedBox(width: gap),
              Expanded(
                child: ProductsMetricCard(
                  totalProducts: analytics.totalProductsSold,
                  topSellingProducts: analytics.topSellingProducts,
                  color: const Color(0xFFD97706),
                  isZero: analytics.totalProductsSold == 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: gap),

        // 6. Rentabilidad (ancho completo)
        AspectRatio(
          aspectRatio: 2.2,
          child: ProfitabilityMetricCard(
            totalProfit: analytics.totalProfit,
            mostProfitableProducts: analytics.mostProfitableProducts,
            color: const Color(0xFF10B981),
            isZero: analytics.mostProfitableProducts.isEmpty,
          ),
        ),
        const SizedBox(height: gap),

        // 7-8. Lenta Rotación y Horas Pico (fila 2x1) - Aspecto 1:1
        AspectRatio(
          aspectRatio: 2.0,
          child: Row(
            children: [
              Expanded(
                child: SlowMovingProductsCard(
                  slowMovingProducts: analytics.slowMovingProducts,
                  color: const Color(0xFFEF4444),
                  isZero: analytics.slowMovingProducts.isEmpty,
                ),
              ),
              const SizedBox(width: gap),
              Expanded(
                child: PeakHoursCard(
                  salesByHour: analytics.salesByHour,
                  peakHours: analytics.peakHours,
                  color: const Color(0xFFF59E0B),
                  isZero: analytics.peakHours.isEmpty,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: gap),

        // 9. Ranking de Vendedores (ancho completo)
        AspectRatio(
          aspectRatio: 2.2,
          child: SellerRankingCard(
            salesBySeller: analytics.salesBySeller,
            color: const Color(0xFF8B5CF6),
            isZero: analytics.salesBySeller.isEmpty,
          ),
        ),
        const SizedBox(height: gap),

        // 10. Medios de Pago (altura dinámica)
        PaymentMethodsCard(
          paymentMethodsBreakdown: analytics.paymentMethodsBreakdown,
          totalSales: analytics.totalSales,
        ),

        // 11. Cajas Activas (si existen)
        if (activeCashRegisters.isNotEmpty) ...[
          const SizedBox(height: gap),
          ActiveCashRegistersCard(
            activeCashRegisters: activeCashRegisters,
          ),
        ],
      ],
    );
  }

  /// Layout para tablets (600px - 900px)
  /// Grid de 4 columnas optimizado
  Widget _buildTabletLayout(
    BuildContext context,
    dynamic analytics,
    List<CashRegister> activeCashRegisters,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: StaggeredGrid.count(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            // 1. Facturación (2x2) - Destacada
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 2,
              child: MetricCard(
                title: 'Facturación',
                value: CurrencyHelper.formatCurrency(analytics.totalSales),
                icon: Icons.attach_money_rounded,
                color: const Color(0xFF059669),
                subtitle: 'Ingresos brutos',
                isZero: analytics.totalSales == 0,
              ),
            ),

            // 2. Ganancia (2x1)
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 1,
              child: MetricCard(
                title: 'Ganancia',
                value: CurrencyHelper.formatCurrency(analytics.totalProfit),
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF7C3AED),
                subtitle: 'Rentabilidad real',
                isZero: analytics.totalProfit == 0,
              ),
            ),

            // 3-4. Ventas y Ticket Promedio (1x1 cada una)
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: MetricCard(
                title: 'Ventas',
                value: analytics.totalTransactions.toString(),
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF2563EB),
                isZero: analytics.totalTransactions == 0,
              ),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: MetricCard(
                title: 'Ticket Prom.',
                value: CurrencyHelper.formatCurrency(
                    analytics.averageProfitPerTransaction),
                icon: Icons.analytics_rounded,
                color: const Color(0xFF0891B2),
                isZero: analytics.averageProfitPerTransaction == 0,
              ),
            ),

            // 5. Productos Vendidos (2x1)
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 1,
              child: ProductsMetricCard(
                totalProducts: analytics.totalProductsSold,
                topSellingProducts: analytics.topSellingProducts,
                color: const Color(0xFFD97706),
                isZero: analytics.totalProductsSold == 0,
                subtitle: 'Movimiento de inventario',
              ),
            ),

            // 6. Rentabilidad (2x1)
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 1,
              child: ProfitabilityMetricCard(
                totalProfit: analytics.totalProfit,
                mostProfitableProducts: analytics.mostProfitableProducts,
                color: const Color(0xFF10B981),
                isZero: analytics.mostProfitableProducts.isEmpty,
                subtitle: 'Productos más rentables',
              ),
            ),

            // 7. Ranking de Vendedores (2x1)
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 1,
              child: SellerRankingCard(
                salesBySeller: analytics.salesBySeller,
                color: const Color(0xFF8B5CF6),
                isZero: analytics.salesBySeller.isEmpty,
                subtitle: 'Desempeño del equipo',
              ),
            ),

            // 8. Horas Pico (2x1)
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 1,
              child: PeakHoursCard(
                salesByHour: analytics.salesByHour,
                peakHours: analytics.peakHours,
                color: const Color(0xFFF59E0B),
                isZero: analytics.peakHours.isEmpty,
                subtitle: 'Mayor actividad',
              ),
            ),

            // 9. Productos de Lenta Rotación (2x1)
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 1,
              child: SlowMovingProductsCard(
                slowMovingProducts: analytics.slowMovingProducts,
                color: const Color(0xFFEF4444),
                isZero: analytics.slowMovingProducts.isEmpty,
                subtitle: 'Requieren atención',
              ),
            ),

            // 10. Medios de Pago (2xFit)
            StaggeredGridTile.fit(
              crossAxisCellCount: 2,
              child: PaymentMethodsCard(
                paymentMethodsBreakdown: analytics.paymentMethodsBreakdown,
                totalSales: analytics.totalSales,
              ),
            ),

            // 11. Cajas Activas (2xFit) - Si existen
            if (activeCashRegisters.isNotEmpty)
              StaggeredGridTile.fit(
                crossAxisCellCount: 2,
                child: ActiveCashRegistersCard(
                  activeCashRegisters: activeCashRegisters,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Layout para desktop (≥ 900px)
  /// Grid de 6 columnas para máximo aprovechamiento
  Widget _buildDesktopLayout(
    BuildContext context,
    dynamic analytics,
    List<CashRegister> activeCashRegisters,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: StaggeredGrid.count(
          crossAxisCount: 6,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            // FILA 1: Métricas principales
            // 1. Facturación (2x2) - Destacada
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 2,
              child: MetricCard(
                title: 'Facturación',
                value: CurrencyHelper.formatCurrency(analytics.totalSales),
                icon: Icons.attach_money_rounded,
                color: const Color(0xFF059669),
                subtitle: 'Ingresos brutos',
                isZero: analytics.totalSales == 0,
              ),
            ),

            // 2. Ganancia (2x1)
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 1,
              child: MetricCard(
                title: 'Ganancia',
                value: CurrencyHelper.formatCurrency(analytics.totalProfit),
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF7C3AED),
                subtitle: 'Rentabilidad real',
                isZero: analytics.totalProfit == 0,
              ),
            ),

            // 3. Ventas (1x1)
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: MetricCard(
                title: 'Ventas',
                value: analytics.totalTransactions.toString(),
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF2563EB),
                isZero: analytics.totalTransactions == 0,
              ),
            ),

            // 4. Ticket Promedio (1x1)
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: MetricCard(
                title: 'Ticket Prom.',
                value: CurrencyHelper.formatCurrency(
                    analytics.averageProfitPerTransaction),
                icon: Icons.analytics_rounded,
                color: const Color(0xFF0891B2),
                isZero: analytics.averageProfitPerTransaction == 0,
              ),
            ),

            // FILA 2: Productos y Rentabilidad
            // 5. Productos Vendidos (2x1)
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 1,
              child: ProductsMetricCard(
                totalProducts: analytics.totalProductsSold,
                topSellingProducts: analytics.topSellingProducts,
                color: const Color(0xFFD97706),
                isZero: analytics.totalProductsSold == 0,
                subtitle: 'Movimiento de inventario',
              ),
            ),

            // 6. Rentabilidad (2x1)
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 1,
              child: ProfitabilityMetricCard(
                totalProfit: analytics.totalProfit,
                mostProfitableProducts: analytics.mostProfitableProducts,
                color: const Color(0xFF10B981),
                isZero: analytics.mostProfitableProducts.isEmpty,
                subtitle: 'Productos más rentables',
              ),
            ),

            // FILA 3: Análisis secundarios
            // 7. Ranking de Vendedores (2x1)
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 1,
              child: SellerRankingCard(
                salesBySeller: analytics.salesBySeller,
                color: const Color(0xFF8B5CF6),
                isZero: analytics.salesBySeller.isEmpty,
                subtitle: 'Desempeño del equipo',
              ),
            ),

            // 8. Horas Pico (2x1)
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 1,
              child: PeakHoursCard(
                salesByHour: analytics.salesByHour,
                peakHours: analytics.peakHours,
                color: const Color(0xFFF59E0B),
                isZero: analytics.peakHours.isEmpty,
                subtitle: 'Mayor actividad',
              ),
            ),

            // 9. Productos de Lenta Rotación (2x1)
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 1,
              child: SlowMovingProductsCard(
                slowMovingProducts: analytics.slowMovingProducts,
                color: const Color(0xFFEF4444),
                isZero: analytics.slowMovingProducts.isEmpty,
                subtitle: 'Requieren atención',
              ),
            ),

            // FILA 4: Tarjetas con contenido dinámico
            // 10. Medios de Pago (3xFit)
            StaggeredGridTile.fit(
              crossAxisCellCount: 3,
              child: PaymentMethodsCard(
                paymentMethodsBreakdown: analytics.paymentMethodsBreakdown,
                totalSales: analytics.totalSales,
              ),
            ),

            // 11. Cajas Activas (3xFit) - Si existen
            if (activeCashRegisters.isNotEmpty)
              StaggeredGridTile.fit(
                crossAxisCellCount: 3,
                child: ActiveCashRegistersCard(
                  activeCashRegisters: activeCashRegisters,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Construye el AppBar personalizado
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final salesProvider = context.read<SalesProvider>();

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

  /// Verifica si dos timestamps pertenecen a meses diferentes
  bool _isDifferentMonth(Timestamp date1, Timestamp date2) {
    final dt1 = date1.toDate();
    final dt2 = date2.toDate();
    return dt1.year != dt2.year || dt1.month != dt2.month;
  }

  /// Genera una clave única para un mes (formato: "YYYY-MM")
  String _getMonthKey(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Obtiene el label del mes y año para mostrar en el divisor
  String _getMonthYearLabel(Timestamp timestamp) {
    final date = timestamp.toDate();
    final months = [
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

  /// Cuenta transacciones en un mes específico
  int _countTransactionsInMonth(
      List<TicketModel> transactions, int startIndex) {
    if (startIndex >= transactions.length) return 0;

    final startDate = transactions[startIndex].creation;
    int count = 1;

    for (int i = startIndex + 1; i < transactions.length; i++) {
      if (_isDifferentMonth(startDate, transactions[i].creation)) {
        break;
      }
      count++;
    }

    return count;
  }

  /// Calcula los ingresos totales de un mes específico
  double _calculateMonthRevenue(
      List<TicketModel> transactions, int startIndex) {
    if (startIndex >= transactions.length) return 0.0;

    final startDate = transactions[startIndex].creation;
    double revenue = transactions[startIndex].priceTotal;

    for (int i = startIndex + 1; i < transactions.length; i++) {
      if (_isDifferentMonth(startDate, transactions[i].creation)) {
        break;
      }
      revenue += transactions[i].priceTotal;
    }

    return revenue;
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
              // El diálogo ya se cierra automáticamente desde ticket_detail_dialog.dart
              // No necesitamos hacer Navigator.pop() aquí

              // Anular el ticket usando CashRegisterProvider
              final success = await cashRegisterProvider.annullTicket(
                accountId: accountId,
                ticket: transaction,
              );

              if (success) {
                // Mostrar mensaje de éxito
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Ticket anulado exitosamente'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );

                // Las analíticas se actualizarán automáticamente con el listener en tiempo real
              } else {
                // Mostrar mensaje de error
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
