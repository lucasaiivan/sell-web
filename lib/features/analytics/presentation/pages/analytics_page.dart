import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/core/utils/helpers/currency_helper.dart';
import 'package:sellweb/core/presentation/widgets/navigation/drawer.dart';
import 'package:sellweb/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import '../../domain/entities/date_filter.dart';
import '../providers/analytics_provider.dart';
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

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [

          // Grid de Métricas Principales
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.3,
              ),
              delegate: SliverChildListDelegate([
                // 1. Transacciones
                MetricCard(
                  title: 'Transacciones',
                  value: analytics.totalTransactions.toString(),
                  icon: Icons.receipt_long,
                  color: Colors.orange,
                ),
                // 2. Facturación (Ventas Totales)
                MetricCard(
                  title: 'Facturación',
                  value: CurrencyHelper.formatCurrency(analytics.totalSales),
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
                // 3. Ganancia
                MetricCard(
                  title: 'Ganancia',
                  value: CurrencyHelper.formatCurrency(analytics.totalProfit),
                  icon: Icons.trending_up,
                  color: Colors.blue,
                ),
                // 4. Ticket Promedio
                MetricCard(
                  title: 'Ticket Promedio',
                  value: CurrencyHelper.formatCurrency(analytics.averageProfitPerTransaction),
                  icon: Icons.analytics,
                  color: Colors.purple,
                ),
                // 5. Productos Vendidos
                MetricCard(
                  title: 'Productos Vendidos',
                  value: analytics.totalProductsSold.toString(),
                  icon: Icons.inventory_2,
                  color: Colors.teal,
                ),
              ]),
            ),
          ),

          // Sección: Medios de Pago
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverToBoxAdapter(
              child: PaymentMethodsCard(
                paymentMethodsBreakdown: analytics.paymentMethodsBreakdown,
                totalSales: analytics.totalSales,
              ),
            ),
          ),

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
                    final isLast = index == analytics.transactions.length - 1;
                    return Column(
                      children: [
                        TransactionListItem(
                          ticket: transaction,
                          onTap: () => _showTransactionDetail(context, transaction),
                        ),
                        if (!isLast)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                      ],
                    );
                  },
                  childCount: analytics.transactions.length,
                ),
              ),
            ),
        ],
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
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
      context: context,
      ticket: transaction,
      businessName: salesProvider.profileAccountSelected.name.isNotEmpty
          ? salesProvider.profileAccountSelected.name
          : 'PUNTO DE VENTA',
      title: 'Detalle de Transacción',
      onTicketAnnulled: transaction.annulled ? null : () async {
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
              content: Text('Error al anular el ticket. Inténtalo nuevamente'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }
}
