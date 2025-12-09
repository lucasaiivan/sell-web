import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/analytics/domain/entities/analytics_card_definition.dart';
import 'package:sellweb/features/analytics/domain/entities/date_filter.dart';
import 'package:sellweb/features/analytics/domain/entities/sales_analytics.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';

import '../cards/widgets.dart';
import '../modals/widgets.dart';
import '../../providers/analytics_provider.dart';

/// Registro centralizado de todas las tarjetas de analíticas disponibles
///
/// **Responsabilidad:**
/// - Mantener lista maestra de definiciones de tarjetas
/// - Crear instancias de widgets de tarjetas dinámicamente
/// - Facilitar categorización y búsqueda de tarjetas
///
/// **Uso:**
/// ```dart
/// // Obtener todas las tarjetas
/// final allCards = AnalyticsCardRegistry.allCards;
///
/// // Construir una tarjeta específica
/// final billingCard = AnalyticsCardRegistry.buildCard(
///   'billing',
///   analytics,
///   activeCashRegisters,
/// );
///
/// // Obtener tarjetas por categoría
/// final metricsCards = AnalyticsCardRegistry.getCardsByCategory(
///   AnalyticsCardCategory.metrics,
/// );
/// ```
class AnalyticsCardRegistry {
  // Evitar instanciación
  AnalyticsCardRegistry._();

  /// Lista maestra de todas las tarjetas disponibles
  ///
  /// **IMPORTANTE:** Solo UNA tarjeta debe tener `isDefault: true`
  static final List<AnalyticsCardDefinition> allCards = [
    // ========== MÉTRICAS PRINCIPALES ==========
    const AnalyticsCardDefinition(
      id: 'billing',
      title: 'Facturación',
      description: 'Ingresos brutos totales del período',
      icon: Icons.attach_money_rounded,
      category: AnalyticsCardCategory.metrics,
      color: AnalyticsColors.billing,
      isDefault: true, // Tarjeta por defecto
    ),
    const AnalyticsCardDefinition(
      id: 'profit',
      title: 'Ganancia',
      description: 'Rentabilidad neta del período',
      icon: Icons.trending_up_rounded,
      category: AnalyticsCardCategory.financial,
      color: AnalyticsColors.profit,
    ),
    const AnalyticsCardDefinition(
      id: 'sales',
      title: 'Ventas',
      description: 'Número total de transacciones',
      icon: Icons.receipt_long_rounded,
      category: AnalyticsCardCategory.metrics,
      color: AnalyticsColors.sales,
      isDefault: true, // Tarjeta por defecto
    ),
    const AnalyticsCardDefinition(
      id: 'averageTicket',
      title: 'Ticket Promedio',
      description: 'Valor promedio por transacción',
      icon: Icons.analytics_rounded,
      category: AnalyticsCardCategory.metrics,
      color: AnalyticsColors.averageTicket,
    ),

    // ========== PRODUCTOS ==========
    const AnalyticsCardDefinition(
      id: 'products',
      title: 'Productos Vendidos',
      description: 'Total de productos y top ventas',
      icon: Icons.shopping_bag_rounded,
      category: AnalyticsCardCategory.products,
      color: AnalyticsColors.products,
    ),
    const AnalyticsCardDefinition(
      id: 'profitability',
      title: 'Rentabilidad',
      description: 'Productos más rentables',
      icon: Icons.attach_money_rounded,
      category: AnalyticsCardCategory.financial,
      color: AnalyticsColors.profitability,
    ),
    const AnalyticsCardDefinition(
      id: 'slowMoving',
      title: 'Lenta Rotación',
      description: 'Productos con baja rotación',
      icon: Icons.inventory_2_rounded,
      category: AnalyticsCardCategory.products,
      color: AnalyticsColors.slowMoving,
    ),
    const AnalyticsCardDefinition(
      id: 'categoryDist',
      title: 'Categorías',
      description: 'Distribución de ventas por categoría',
      icon: Icons.category_rounded,
      category: AnalyticsCardCategory.products,
      color: AnalyticsColors.categories,
    ),

    // ========== RENDIMIENTO ==========
    const AnalyticsCardDefinition(
      id: 'peakHours',
      title: 'Horas Pico',
      description: 'Horarios de mayor actividad',
      icon: Icons.access_time_rounded,
      category: AnalyticsCardCategory.performance,
      color: AnalyticsColors.peakHours,
    ),
    const AnalyticsCardDefinition(
      id: 'weekdaySales',
      title: 'Días de Venta',
      description: 'Rendimiento por día de la semana',
      icon: Icons.calendar_today_rounded,
      category: AnalyticsCardCategory.performance,
      color: AnalyticsColors.weekdaySales,
    ),
    const AnalyticsCardDefinition(
      id: 'salesTrend',
      title: 'Tendencia de Ventas',
      description: 'Evolución temporal de ventas',
      icon: Icons.show_chart_rounded,
      category: AnalyticsCardCategory.performance,
      color: AnalyticsColors.salesTrend,
    ),

    // ========== EQUIPO ==========
    const AnalyticsCardDefinition(
      id: 'sellerRanking',
      title: 'Ranking de Vendedores',
      description: 'Desempeño del equipo de ventas',
      icon: Icons.emoji_events_rounded,
      category: AnalyticsCardCategory.team,
      color: AnalyticsColors.sellerRanking,
    ),

    // ========== FINANCIERO ==========
    const AnalyticsCardDefinition(
      id: 'paymentMethods',
      title: 'Medios de Pago',
      description: 'Distribución de métodos de pago',
      icon: Icons.payment_rounded,
      category: AnalyticsCardCategory.financial,
      color: AnalyticsColors.paymentMethods,
    ),

    // ========== OPERACIONES ==========
    const AnalyticsCardDefinition(
      id: 'cashRegisters',
      title: 'Cajas Activas',
      description: 'Estado de cajas registradoras',
      icon: Icons.point_of_sale_rounded,
      category: AnalyticsCardCategory.operations,
      color: AnalyticsColors.cashRegisters,
    ),
  ];

  /// Construye el widget de una tarjeta específica
  ///
  /// **Parámetros:**
  /// - `context`: BuildContext para mostrar modales
  /// - `cardId`: ID único de la tarjeta (de `AnalyticsCardDefinition.id`)
  /// - `analytics`: Datos de analíticas
  /// - `activeCashRegisters`: Lista de cajas activas (opcional)
  /// - `analyticsProvider`: Provider de analíticas (para calcular tendencias)
  /// - `currentFilter`: Filtro de fecha actual (para calcular comparaciones correctas)
  /// - `onSalesTap`: Callback especial para la tarjeta de ventas (abre dialog fullscreen)
  ///
  /// **Retorna:**
  /// - Widget de la tarjeta o null si el ID no existe
  static Widget? buildCard(
    BuildContext context,
    String cardId,
    SalesAnalytics analytics,
    List<CashRegister> activeCashRegisters,
    AnalyticsProvider analyticsProvider, {
    required DateFilter currentFilter,
    VoidCallback? onSalesTap,
  }) {
    // Obtener definición para usar colores consistentes
    final def = getCardById(cardId);
    final color = def?.color ?? Colors.grey;

    // Totales del período actual (excluyen el período anterior usado solo para comparación)
    final periodTotals = analytics.getTotalsForFilter(currentFilter);

    switch (cardId) {
      case 'billing': // Facturación
        final hasData = periodTotals.totalSales > 0;
        return MetricCard(
          key: const ValueKey('billing'),
          title: 'Facturación',
          value: CurrencyHelper.formatCurrency(periodTotals.totalSales),
          icon: Icons.attach_money_rounded,
          color: color,
          isZero: periodTotals.totalSales == 0,
          moreInformation: false,
          showActionIndicator: hasData,
          onTap: null,
          comparisonData: analytics.getPeriodComparison(
            currentFilter,
            (data) => data['totalSales'] as double? ?? 0.0,
          ),
        );

      case 'profit': // Ganancia
        final hasData = periodTotals.totalProfit > 0;
        final profitMargin = periodTotals.totalSales > 0
            ? (periodTotals.totalProfit / periodTotals.totalSales * 100)
            : 0.0;
        return MetricCard(
          key: const ValueKey('profit'),
          title: 'Ganancia',
          value: CurrencyHelper.formatCurrency(periodTotals.totalProfit),
          icon: Icons.trending_up_rounded,
          color: color,
          subtitle: 'Rentabilidad real',
          isZero: periodTotals.totalProfit == 0,
          showActionIndicator: hasData,
          onTap: hasData
              ? () => showProfitModal(context, analytics, filter: currentFilter)
              : null,
          percentageInfo: hasData
              ? '${NumberHelper.formatPercentage(profitMargin)} margen'
              : null,
        );

      case 'sales': // Ventas
        final hasTransactions = periodTotals.totalTransactions > 0;
        return MetricCard(
          key: const ValueKey('sales'),
          title: 'Ventas',
          value: NumberHelper.formatNumber(periodTotals.totalTransactions),
          icon: Icons.receipt_long_rounded,
          color: color,
          isZero: periodTotals.totalTransactions == 0,
          onTap: onSalesTap,
          showActionIndicator: hasTransactions && onSalesTap != null,
          comparisonData: analytics.getPeriodComparison(
            currentFilter,
            (data) => (data['transactionCount'] as int? ?? 0).toDouble(),
          ),
        );

      case 'averageTicket': // Ticket Promedio
        final hasData = periodTotals.averageTicket > 0;
        return MetricCard(
          key: const ValueKey('averageTicket'),
          title: 'Ticket Promedio',
          value: CurrencyHelper.formatCurrency(periodTotals.averageTicket),
          icon: Icons.analytics_rounded,
          color: color,
          isZero: periodTotals.averageTicket == 0,
          showActionIndicator: hasData,
          subtitle:
              '${NumberHelper.formatNumber(periodTotals.totalTransactions)} transacciones',
          onTap: hasData
              ? () => showAverageTicketModal(context, analytics, currentFilter)
              : null,
        );

      case 'products': // Productos
        // Usar datos del período filtrado
        final filteredProducts =
            analytics.getTopSellingProductsForFilter(currentFilter);
        final totalProductsFiltered = filteredProducts.fold<int>(
            0, (sum, p) => sum + (p['quantitySold'] as int));
        final hasProductsData = periodTotals.totalTransactions > 0;
        return ProductsMetricCard(
          key: const ValueKey('products'),
          totalProducts: totalProductsFiltered,
          topSellingProducts: filteredProducts,
          color: color,
          subtitle: 'Movimiento de inventario',
          isZero: !hasProductsData,
        );

      case 'profitability': // Rentabilidad
        // Usar datos del período filtrado
        final filteredProfitableProducts =
            analytics.getMostProfitableProductsForFilter(currentFilter);
        final hasProfitData = periodTotals.totalTransactions > 0;
        return ProfitabilityMetricCard(
          key: const ValueKey('profitability'),
          mostProfitableProducts: filteredProfitableProducts,
          color: color,
          subtitle: 'Producto más rentable',
          isZero: !hasProfitData || filteredProfitableProducts.isEmpty,
        );

      case 'slowMoving': // Lenta Rotación
        return SlowMovingProductsCard(
          key: const ValueKey('slowMoving'),
          slowMovingProducts: analytics.slowMovingProducts,
          color: color,
          isZero: analytics.slowMovingProducts.isEmpty,
        );

      case 'categoryDist': // Categorías
        // Usar datos del período filtrado
        final filteredCategories =
            analytics.getSalesByCategoryForFilter(currentFilter);
        final hasCategoryData = periodTotals.totalTransactions > 0;
        return CategoryDistributionCard(
          key: const ValueKey('categoryDist'),
          salesByCategory: filteredCategories,
          totalSales: periodTotals.totalSales,
          color: color,
          subtitle: 'Ventas por categoría',
          isZero: !hasCategoryData || filteredCategories.isEmpty,
        );

      case 'peakHours': // Horas Pico
        // Usar datos del período filtrado
        final filteredSalesByHour =
            analytics.getSalesByHourForFilter(currentFilter);
        final filteredPeakHours =
            analytics.getPeakHoursForFilter(currentFilter);
        final hasPeakData = periodTotals.totalTransactions > 0;
        return PeakHoursCard(
          key: const ValueKey('peakHours'),
          salesByHour: filteredSalesByHour,
          peakHours: filteredPeakHours,
          color: color,
          subtitle: 'Mayor actividad por hora',
          isZero: !hasPeakData || filteredPeakHours.isEmpty,
        );

      case 'weekdaySales': // Días de Venta
        final filteredWeekdaySales =
            analytics.getSalesByWeekdayForFilter(currentFilter);

        // Verificación adaptativa según tipo de filtro
        // - Hoy/Ayer: Busca datos en cualquiera de los 7 días cargados
        // - Otros: Usa total de transacciones del período
        final hasWeekdayData = (currentFilter == DateFilter.today ||
                currentFilter == DateFilter.yesterday)
            ? filteredWeekdaySales.values
                .any((day) => (day['transactionCount'] as int? ?? 0) > 0)
            : periodTotals.totalTransactions > 0;

        return WeekdaySalesCard(
          key: const ValueKey('weekdaySales'),
          salesByWeekday: filteredWeekdaySales,
          color: color,
          subtitle: 'Rendimiento por día',
          isZero: !hasWeekdayData,
          currentFilter: currentFilter,
        );

      case 'salesTrend': // Tendencia de Ventas
        // Calcular datos de tendencia con granularidad adaptativa
        final trendData = analyticsProvider.calculateTrendData();
        final hasTrendData = periodTotals.totalTransactions > 0;
        return SalesTrendCard(
          key: const ValueKey('salesTrend'),
          trendData: trendData,
          color: color,
          subtitle: 'Evolución temporal',
          isZero: !hasTrendData || !trendData.hasData,
        );

      case 'sellerRanking': // Ranking de Vendedores
        // Usar datos del período filtrado
        final filteredSalesBySeller =
            analytics.getSalesBySellerForFilter(currentFilter);
        final hasSellerData = periodTotals.totalTransactions > 0;
        return SellerRankingCard(
          key: const ValueKey('sellerRanking'),
          salesBySeller: filteredSalesBySeller,
          color: color,
          subtitle: 'Desempeño del equipo',
          isZero: !hasSellerData || filteredSalesBySeller.isEmpty,
        );

      case 'paymentMethods': // Medios de Pago
        // Usar datos del período filtrado (aplicar filtro de fecha)
        final filteredPaymentMethods =
            analytics.getPaymentMethodsForFilter(currentFilter);
        final hasPaymentData = periodTotals.totalTransactions > 0 &&
            filteredPaymentMethods.isNotEmpty;
        return PaymentMethodsCard(
          key: const ValueKey('paymentMethods'),
          paymentMethodsBreakdown: filteredPaymentMethods,
          totalSales: periodTotals.totalSales,
          color: color,
          showActionIndicator: hasPaymentData,
          onTap: hasPaymentData
              ? () => showPaymentMethodsModal(context, analytics, currentFilter)
              : null,
        );

      case 'cashRegisters': // Cajas Registradoras
        // Esta tarjeta es OPERACIONAL: muestra el estado actual, no depende del filtro de fecha
        if (activeCashRegisters.isEmpty) return null;
        return ActiveCashRegistersCard(
          key: const ValueKey('cashRegisters'),
          activeCashRegisters: activeCashRegisters,
          color: color,
        );

      default:
        return null;
    }
  }

  /// Obtiene todas las tarjetas de una categoría específica
  static List<AnalyticsCardDefinition> getCardsByCategory(
    AnalyticsCardCategory category,
  ) {
    return allCards.where((card) => card.category == category).toList();
  }

  /// Obtiene la definición de una tarjeta por ID
  static AnalyticsCardDefinition? getCardById(String id) {
    try {
      return allCards.firstWhere((card) => card.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene todas las tarjetas por defecto
  static List<AnalyticsCardDefinition> getDefaultCards() {
    return allCards.where((card) => card.isDefault).toList();
  }

  /// Obtiene IDs de las tarjetas por defecto
  static List<String> getDefaultCardIds() {
    return getDefaultCards().map((card) => card.id).toList();
  }

  /// Agrupa tarjetas por categoría
  ///
  /// **Retorna:** `Map<AnalyticsCardCategory, List<AnalyticsCardDefinition>>`
  static Map<AnalyticsCardCategory, List<AnalyticsCardDefinition>>
      getCardsByCategories() {
    final Map<AnalyticsCardCategory, List<AnalyticsCardDefinition>> grouped =
        {};

    for (final card in allCards) {
      grouped.putIfAbsent(card.category, () => []).add(card);
    }

    return grouped;
  }
}
