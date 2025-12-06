import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/core/presentation/widgets/navigation/drawer.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import '../../domain/entities/date_filter.dart';
import '../../domain/entities/sales_analytics.dart';
import '../providers/analytics_provider.dart';
import '../widgets/analytics_card_registry.dart';
import '../widgets/analytics_skeleton.dart';
import '../widgets/customize_cards_dialog.dart';
import '../widgets/reorderable_analytics_grid.dart';
import '../widgets/transactions_dialog.dart';

/// Página: Analíticas
///
/// **Responsabilidad:**
/// - Mostrar métricas de ventas del negocio
/// - Filtrar transacciones por período de tiempo
/// - Permitir PERSONALIZACIÓN de tarjetas visibles
/// - Gestionar estados: loading, error, success
///
/// **Dashboard Personalizable:**
/// - Por defecto solo muestra "Facturación"
/// - El usuario agrega más tarjetas desde el botón de personalización
/// - Las preferencias se persisten localmente
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
      floatingActionButton: Consumer<AnalyticsProvider>(
        builder: (context, provider, _) {
          return FloatingActionButton(
            onPressed: () => _showCustomizeDialog(context, provider),
            tooltip: 'Agregar tarjetas',
            child: const Icon(Icons.add_rounded),
          );
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

  /// Construye el estado de éxito con las métricas
  Widget _buildSuccessState(BuildContext context, AnalyticsProvider provider) {
    final analytics = provider.analytics!;
    final cashRegisterProvider = context.watch<CashRegisterProvider>();
    final activeCashRegisters = cashRegisterProvider.activeCashRegisters;

    // Si no hay tarjetas visibles, mostrar mensaje para añadir
    if (provider.visibleCardIds.isEmpty) {
      return _buildNoCardsState(context, provider);
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Grid de Métricas y Tarjetas (Responsive Layout)
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;

                // DISEÑO COMPACTO VERTICAL (pantallas muy pequeñas < 600px)
                if (screenWidth < 600) {
                  return _buildResponsiveLayout(
                    context: context,
                    analytics: analytics,
                    activeCashRegisters: activeCashRegisters,
                    provider: provider,
                    layoutType: 'mobile',
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    maxWidth: null,
                  );
                }
                // DISEÑO TABLET (600px - 900px)
                else if (screenWidth < 900) {
                  return _buildResponsiveLayout(
                    context: context,
                    analytics: analytics,
                    activeCashRegisters: activeCashRegisters,
                    provider: provider,
                    layoutType: 'tablet',
                    crossAxisCount: 3,
                    childAspectRatio: 1.2,
                    maxWidth: 900,
                  );
                }
                // DISEÑO DESKTOP (≥ 900px)
                else {
                  return _buildResponsiveLayout(
                    context: context,
                    analytics: analytics,
                    activeCashRegisters: activeCashRegisters,
                    provider: provider,
                    layoutType: 'desktop',
                    crossAxisCount: 4,
                    childAspectRatio: 1.3,
                    maxWidth: 1400,
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Construye el layout responsivo usando el registro de tarjetas
  Widget _buildResponsiveLayout({
    required BuildContext context,
    required SalesAnalytics analytics,
    required List<CashRegister> activeCashRegisters,
    required AnalyticsProvider provider,
    required String layoutType,
    required int crossAxisCount,
    required double childAspectRatio,
    double? maxWidth,
  }) {
    final salesProvider = context.read<SalesProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final gap = layoutType == 'mobile'
        ? (screenWidth * 0.025).clamp(8.0, 16.0)
        : layoutType == 'tablet'
            ? (screenWidth * 0.015).clamp(8.0, 12.0)
            : (screenWidth * 0.01).clamp(10.0, 14.0);

    // Construir tarjetas dinámicamente desde el registro
    // NOTA: Todas las tarjetas usan datos filtrados de 'analytics',
    // EXCEPTO 'cashRegisters' que usa 'activeCashRegisters' (estado operacional actual)
    final List<Widget> cards = _buildCardsFromRegistry(
      context: context,
      provider: provider,
      visibleCardIds: provider.visibleCardIds,
      analytics: analytics,
      activeCashRegisters: activeCashRegisters,
    );

    return ReorderableAnalyticsGrid(
      layoutType: layoutType,
      crossAxisCount: crossAxisCount,
      gap: gap,
      maxWidth: maxWidth,
      childAspectRatio: childAspectRatio,
      enableReordering: true,
      onReorder: (reorderedIndices) {
        // reorderedIndices contiene los índices en el nuevo orden
        // Mapear los índices a los IDs de tarjetas correspondientes
        final currentCardIds = provider.visibleCardIds;
        final reorderedCardIds = reorderedIndices
            .where((index) => index >= 0 && index < currentCardIds.length)
            .map((index) => currentCardIds[index])
            .toList();

        // Guardar el nuevo orden si es válido
        if (reorderedCardIds.length == currentCardIds.length) {
          provider.saveVisibleCards(
            salesProvider.profileAccountSelected.id,
            reorderedCardIds,
          );
        }
      },
      children: cards,
    );
  }

  /// Construye las tarjetas visibles desde el registro
  List<Widget> _buildCardsFromRegistry({
    required BuildContext context,
    required AnalyticsProvider provider,
    required List<String> visibleCardIds,
    required SalesAnalytics analytics,
    required List<CashRegister> activeCashRegisters,
  }) {
    final List<Widget> cards = [];

    for (final cardId in visibleCardIds) {
      final card = AnalyticsCardRegistry.buildCard(
        context,
        cardId,
        analytics,
        activeCashRegisters,
        currentFilter: provider.selectedFilter,
        onSalesTap: () => showTransactionsDialog(
          context: context,
          transactions: analytics.transactions,
          currentFilter: provider.selectedFilter,
          onTransactionTap: (transaction) =>
              _showTransactionDetail(context, transaction),
        ),
      );

      if (card != null) {
        cards.add(card);
      }
    }

    return cards;
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

  /// Muestra el diálogo de personalización de tarjetas
  Future<void> _showCustomizeDialog(
    BuildContext context,
    AnalyticsProvider provider,
  ) async {
    final salesProvider = context.read<SalesProvider>();

    final result = await showCustomizeCardsDialog(
      context,
      provider.visibleCardIds,
    );

    if (result != null && context.mounted) {
      // Guardar preferencias de tarjetas visibles
      await provider.saveVisibleCards(
        salesProvider.profileAccountSelected.id,
        result,
      );
    }
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

  /// Construye el estado cuando no hay tarjetas seleccionadas
  Widget _buildNoCardsState(BuildContext context, AnalyticsProvider provider) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono decorativo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.dashboard_customize_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            // Título
            Text(
              'Sin tarjetas seleccionadas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Descripción
            Text(
              'Personaliza tu dashboard agregando las tarjetas de analíticas que más te interesen',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Botón para añadir tarjetas
            FilledButton.icon(
              onPressed: () => _showCustomizeDialog(context, provider),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar Tarjetas'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra el diálogo de detalle de transacción
  void _showTransactionDetail(BuildContext context, TicketModel transaction) {
    final salesProvider = context.read<SalesProvider>();
    final cashRegisterProvider = context.read<CashRegisterProvider>();

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
