import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/core/presentation/widgets/navigation/drawer.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import '../providers/analytics_provider.dart';
import '../widgets/date_filter_chips.dart';
import '../widgets/metric_card.dart';
import '../widgets/payment_methods_card.dart';
import '../widgets/transaction_list_item.dart';

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
          return Column(
            children: [
              // Filtros de fecha
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: DateFilterChips(
                  selectedFilter: provider.selectedFilter,
                  onFilterChanged: (filter) => provider.setDateFilter(filter),
                ),
              ),
              // Contenido principal
              Expanded(
                child: _buildContent(context, provider),
              ),
            ],
          );
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
    final currencyFormat = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 2,
    );

    return RefreshIndicator(
      onRefresh: () => _refreshAnalytics(context),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Indicador de carga y última actualización
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (provider.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const SizedBox(width: 16),
                  Text(
                    'Actualizado: ${DateFormat('HH:mm:ss').format(analytics.calculatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          // Grid de Métricas Principales
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.count(
              crossAxisCount: _calculateCrossAxisCount(context),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                // 1. Facturación (Ventas Totales)
                MetricCard(
                  title: 'Facturación',
                  value: currencyFormat.format(analytics.totalSales),
                  icon: Icons.attach_money,
                  color: Colors.green,
                  subtitle: 'Ventas brutas',
                ),
                // 2. Ganancia
                MetricCard(
                  title: 'Ganancia',
                  value: currencyFormat.format(analytics.totalProfit),
                  icon: Icons.trending_up,
                  color: Colors.blue,
                  subtitle: 'Beneficio neto',
                ),
                // 3. Transacciones
                MetricCard(
                  title: 'Transacciones',
                  value: analytics.totalTransactions.toString(),
                  icon: Icons.receipt_long,
                  color: Colors.orange,
                  subtitle: 'Tickets generados',
                ),
                // 4. Ticket Promedio
                MetricCard(
                  title: 'Ticket Promedio',
                  value: currencyFormat.format(analytics.averageProfitPerTransaction),
                  icon: Icons.analytics,
                  color: Colors.purple,
                  subtitle: 'Promedio por venta',
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Sección: Medios de Pago
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 300, // Altura fija para el card de medios de pago
                child: PaymentMethodsCard(
                  paymentMethodsBreakdown: analytics.paymentMethodsBreakdown,
                  totalSales: analytics.totalSales,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Título de Lista
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Últimas Transacciones',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Lista de Transacciones
          if (analytics.transactions.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: Text('No hay transacciones en este período')),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final transaction = analytics.transactions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TransactionListItem(ticket: transaction),
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

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 2;
    return 1; // Móvil
  }

  /// Construye el AppBar personalizado
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final salesProvider = context.read<SalesProvider>();

    return AppBar(
      toolbarHeight: 70,
      titleSpacing: 0,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Container(),
      flexibleSpace: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(
            top: 20.0,
            bottom: 12,
            left: 12,
            right: 12,
          ),
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
              const SizedBox(width: 16),
              // Título
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Analíticas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Consumer<AnalyticsProvider>(
                      builder: (context, provider, _) {
                        if (provider.analytics != null) {
                          return Text(
                            '${provider.analytics!.totalTransactions} transacciones',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              // Botón de refrescar
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Actualizar',
                onPressed: () => _refreshAnalytics(context),
              ),
            ],
          ),
        ),
      ),
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
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _refreshAnalytics(context),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
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

  /// Refresca las analíticas
  Future<void> _refreshAnalytics(BuildContext context) async {
    final salesProvider = context.read<SalesProvider>();
    final analyticsProvider = context.read<AnalyticsProvider>();
    final accountId = salesProvider.profileAccountSelected.id;

    if (accountId.isNotEmpty) {
      await analyticsProvider.refresh(accountId);
    }
  }
}
