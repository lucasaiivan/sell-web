import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sellweb/features/analytics/domain/entities/analytics_card_definition.dart';
import 'package:sellweb/features/analytics/domain/entities/date_filter.dart';
import 'package:sellweb/features/analytics/domain/entities/sales_analytics.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'active_cash_registers_card.dart';
import 'average_ticket_modal.dart';
import 'billing_modal.dart';
import 'category_distribution_card.dart';
import 'metric_card.dart';
import 'payment_methods_card.dart';
import 'payment_methods_modal.dart';
import 'peak_hours_card.dart';
import 'products_metric_card.dart';
import 'profit_modal.dart';
import 'profitability_metric_card.dart';
import 'sales_trend_card.dart';
import 'seller_ranking_card.dart';
import 'slow_moving_products_card.dart';
import 'weekday_sales_card.dart';
import 'package:sellweb/core/core.dart';

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
      color: Color(0xFF059669),
      isDefault: true, // Tarjeta por defecto
    ),
    const AnalyticsCardDefinition(
      id: 'profit',
      title: 'Ganancia',
      description: 'Rentabilidad neta del período',
      icon: Icons.trending_up_rounded,
      category: AnalyticsCardCategory.financial,
      color: Color(0xFF7C3AED),
    ),
    const AnalyticsCardDefinition(
      id: 'sales',
      title: 'Ventas',
      description: 'Número total de transacciones',
      icon: Icons.receipt_long_rounded,
      category: AnalyticsCardCategory.metrics,
      color: Color(0xFF2563EB),
      isDefault: true, // Tarjeta por defecto
    ),
    const AnalyticsCardDefinition(
      id: 'averageTicket',
      title: 'Ticket Promedio',
      description: 'Valor promedio por transacción',
      icon: Icons.analytics_rounded,
      category: AnalyticsCardCategory.metrics,
      color: Color(0xFF0891B2),
    ),

    // ========== PRODUCTOS ==========
    const AnalyticsCardDefinition(
      id: 'products',
      title: 'Productos Vendidos',
      description: 'Total de productos y top ventas',
      icon: Icons.shopping_bag_rounded,
      category: AnalyticsCardCategory.products,
      color: Color(0xFFD97706),
    ),
    const AnalyticsCardDefinition(
      id: 'profitability',
      title: 'Rentabilidad',
      description: 'Productos más rentables',
      icon: Icons.attach_money_rounded,
      category: AnalyticsCardCategory.financial,
      color: Color(0xFF10B981),
    ),
    const AnalyticsCardDefinition(
      id: 'slowMoving',
      title: 'Lenta Rotación',
      description: 'Productos con baja rotación',
      icon: Icons.inventory_2_rounded,
      category: AnalyticsCardCategory.products,
      color: Color(0xFFEF4444),
    ),
    const AnalyticsCardDefinition(
      id: 'categoryDist',
      title: 'Categorías',
      description: 'Distribución de ventas por categoría',
      icon: Icons.category_rounded,
      category: AnalyticsCardCategory.products,
      color: Color(0xFFEC4899),
    ),

    // ========== RENDIMIENTO ==========
    const AnalyticsCardDefinition(
      id: 'peakHours',
      title: 'Horas Pico',
      description: 'Horarios de mayor actividad',
      icon: Icons.access_time_rounded,
      category: AnalyticsCardCategory.performance,
      color: Color(0xFFF59E0B),
    ),
    const AnalyticsCardDefinition(
      id: 'weekdaySales',
      title: 'Días de Venta',
      description: 'Rendimiento por día de la semana',
      icon: Icons.calendar_today_rounded,
      category: AnalyticsCardCategory.performance,
      color: Color(0xFF6366F1),
    ),
    const AnalyticsCardDefinition(
      id: 'salesTrend',
      title: 'Tendencia de Ventas',
      description: 'Evolución temporal de ventas',
      icon: Icons.show_chart_rounded,
      category: AnalyticsCardCategory.performance,
      color: Color(0xFF3B82F6),
    ),

    // ========== EQUIPO ==========
    const AnalyticsCardDefinition(
      id: 'sellerRanking',
      title: 'Ranking de Vendedores',
      description: 'Desempeño del equipo de ventas',
      icon: Icons.emoji_events_rounded,
      category: AnalyticsCardCategory.team,
      color: Color(0xFF8B5CF6),
    ),

    // ========== FINANCIERO ==========
    const AnalyticsCardDefinition(
      id: 'paymentMethods',
      title: 'Medios de Pago',
      description: 'Distribución de métodos de pago',
      icon: Icons.payment_rounded,
      category: AnalyticsCardCategory.financial,
      color: Color(0xFF0EA5E9),
    ),

    // ========== OPERACIONES ==========
    const AnalyticsCardDefinition(
      id: 'cashRegisters',
      title: 'Cajas Activas',
      description: 'Estado de cajas registradoras',
      icon: Icons.point_of_sale_rounded,
      category: AnalyticsCardCategory.operations,
      color: Color(0xFFF43F5E),
    ),
  ];

  /// Construye el widget de una tarjeta específica
  ///
  /// **Parámetros:**
  /// - `context`: BuildContext para mostrar modales
  /// - `cardId`: ID único de la tarjeta (de `AnalyticsCardDefinition.id`)
  /// - `analytics`: Datos de analíticas
  /// - `activeCashRegisters`: Lista de cajas activas (opcional)
  /// - `currentFilter`: Filtro de fecha actual (para calcular comparaciones correctas)
  /// - `onSalesTap`: Callback especial para la tarjeta de ventas (abre dialog fullscreen)
  ///
  /// **Retorna:**
  /// - Widget de la tarjeta o null si el ID no existe
  static Widget? buildCard(
    BuildContext context,
    String cardId,
    SalesAnalytics analytics,
    List<CashRegister> activeCashRegisters, {
    required DateFilter currentFilter,
    VoidCallback? onSalesTap,
  }) {
    // Obtener definición para usar colores consistentes
    final def = getCardById(cardId);
    final color = def?.color ?? Colors.grey;

    // Totales del período actual (excluyen el período anterior usado solo para comparación)
    final _PeriodTotals periodTotals = _calculateCurrentPeriodTotals(
      analytics.salesByDay,
      currentFilter,
    );

    switch (cardId) {
      case 'billing':
        final hasData = periodTotals.totalSales > 0;
        return MetricCard(
          key: const ValueKey('billing'),
          title: 'Facturación',
          value: CurrencyHelper.formatCurrency(periodTotals.totalSales),
          icon: Icons.attach_money_rounded,
          color: color,
          subtitle: 'Ingresos brutos',
          isZero: periodTotals.totalSales == 0,
          moreInformation: true,
          showActionIndicator: hasData,
          onTap: hasData ? () => showBillingModal(context, analytics) : null,
          comparisonData: _calculatePeriodComparison(
            analytics.salesByDay,
            currentFilter,
            (data) => data['totalSales'] as double? ?? 0.0,
          ),
        );

      case 'profit':
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
          onTap: hasData ? () => showProfitModal(context, analytics) : null,
          percentageInfo:
              hasData ? '${profitMargin.toStringAsFixed(1)}% margen' : null,
        );

      case 'sales':
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
          comparisonData: _calculatePeriodComparison(
            analytics.salesByDay,
            currentFilter,
            (data) => (data['transactionCount'] as int? ?? 0).toDouble(),
          ),
        );

      case 'averageTicket':
        final hasData = periodTotals.averageProfitPerTransaction > 0;
        return MetricCard(
          key: const ValueKey('averageTicket'),
          title: 'Ticket Prom.',
          value: CurrencyHelper.formatCurrency(
              periodTotals.averageProfitPerTransaction),
          icon: Icons.analytics_rounded,
          color: color,
          isZero: periodTotals.averageProfitPerTransaction == 0,
          showActionIndicator: hasData,
          onTap:
              hasData ? () => showAverageTicketModal(context, analytics) : null,
        );

      case 'products':
        return ProductsMetricCard(
          key: const ValueKey('products'),
          totalProducts: analytics.totalProductsSold,
          topSellingProducts: analytics.topSellingProducts,
          color: color,
          subtitle: 'Movimiento de inventario',
          isZero: analytics.totalProductsSold == 0,
        );

      case 'profitability':
        return ProfitabilityMetricCard(
          key: const ValueKey('profitability'),
          totalProfit: analytics.totalProfit,
          mostProfitableProducts: analytics.mostProfitableProducts,
          color: color,
          subtitle: 'Productos más rentables',
          isZero: analytics.mostProfitableProducts.isEmpty,
        );

      case 'slowMoving':
        return SlowMovingProductsCard(
          key: const ValueKey('slowMoving'),
          slowMovingProducts: analytics.slowMovingProducts,
          color: color,
          subtitle: 'Requieren atención',
          isZero: analytics.slowMovingProducts.isEmpty,
        );

      case 'categoryDist':
        return CategoryDistributionCard(
          key: const ValueKey('categoryDist'),
          salesByCategory: analytics.salesByCategory,
          totalSales: analytics.totalSales,
          color: color,
          subtitle: 'Ventas por categoría',
          isZero: analytics.salesByCategory.isEmpty,
        );

      case 'peakHours':
        return PeakHoursCard(
          key: const ValueKey('peakHours'),
          salesByHour: analytics.salesByHour,
          peakHours: analytics.peakHours,
          color: color,
          subtitle: 'Mayor actividad por hora',
          isZero: analytics.peakHours.isEmpty,
        );

      case 'weekdaySales':
        return WeekdaySalesCard(
          key: const ValueKey('weekdaySales'),
          salesByWeekday: analytics.salesByWeekday,
          color: color,
          subtitle: 'Rendimiento semanal',
          isZero: analytics.salesByWeekday.isEmpty,
        );

      case 'salesTrend':
        return SalesTrendCard(
          key: const ValueKey('salesTrend'),
          salesByDay: analytics.salesByDay,
          color: color,
          subtitle: 'Evolución temporal',
          isZero: analytics.salesByDay.isEmpty,
        );

      case 'sellerRanking':
        return SellerRankingCard(
          key: const ValueKey('sellerRanking'),
          salesBySeller: analytics.salesBySeller,
          color: color,
          subtitle: 'Desempeño del equipo',
          isZero: analytics.salesBySeller.isEmpty,
        );

      case 'paymentMethods':
        final hasData = analytics.paymentMethodsBreakdown.isNotEmpty;
        return PaymentMethodsCard(
          key: const ValueKey('paymentMethods'),
          paymentMethodsBreakdown: analytics.paymentMethodsBreakdown,
          totalSales: analytics.totalSales,
          color: color,
          showActionIndicator: hasData,
          onTap: hasData
              ? () => showPaymentMethodsModal(context, analytics)
              : null,
        );

      case 'cashRegisters':
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

  /// Calcula totales solo del período actual (excluye el período anterior usado para comparación)
  static _PeriodTotals _calculateCurrentPeriodTotals(
    Map<String, Map<String, dynamic>> salesByDay,
    DateFilter currentFilter,
  ) {
    if (salesByDay.isEmpty) return const _PeriodTotals();

    final now = DateTime.now();
    DateTime rangeStart;
    DateTime rangeEnd; // exclusivo

    switch (currentFilter) {
      case DateFilter.today:
        rangeStart = DateTime(now.year, now.month, now.day);
        rangeEnd = rangeStart.add(const Duration(days: 1));
        break;
      case DateFilter.yesterday:
        rangeEnd = DateTime(now.year, now.month, now.day);
        rangeStart = rangeEnd.subtract(const Duration(days: 1));
        break;
      case DateFilter.thisMonth:
        rangeStart = DateTime(now.year, now.month, 1);
        rangeEnd = DateTime(now.year, now.month + 1, 1);
        break;
      case DateFilter.lastMonth:
        rangeStart = DateTime(now.year, now.month - 1, 1);
        rangeEnd = DateTime(now.year, now.month, 1);
        break;
      case DateFilter.thisYear:
        rangeStart = DateTime(now.year, 1, 1);
        rangeEnd = DateTime(now.year + 1, 1, 1);
        break;
      case DateFilter.lastYear:
        rangeStart = DateTime(now.year - 1, 1, 1);
        rangeEnd = DateTime(now.year, 1, 1);
        break;
    }

    bool _inRange(DateTime d) =>
        !d.isBefore(rangeStart) && d.isBefore(rangeEnd);

    double totalSales = 0.0;
    double totalProfit = 0.0;
    int totalTransactions = 0;

    for (final entry in salesByDay.entries) {
      final dayDate = DateTime.parse(entry.key);
      if (!_inRange(dayDate)) continue;

      final data = entry.value;
      totalSales += data['totalSales'] as double? ?? 0.0;
      totalProfit += data['totalProfit'] as double? ?? 0.0;
      totalTransactions += data['transactionCount'] as int? ?? 0;
    }

    final avgProfitPerTx =
        totalTransactions > 0 ? totalProfit / totalTransactions : 0.0;

    return _PeriodTotals(
      totalSales: totalSales,
      totalProfit: totalProfit,
      totalTransactions: totalTransactions,
      averageProfitPerTransaction: avgProfitPerTx,
    );
  }

  /// Calcula la comparación con el período anterior según el filtro seleccionado
  ///
  /// **Parámetros:**
  /// - `salesByDay`: Mapa de ventas por día
  /// - `currentFilter`: Filtro de fecha actual
  /// - `valueExtractor`: Función para extraer el valor a comparar
  ///
  /// **Retorna:** Mapa con porcentaje de cambio y label del período, o null si no aplica
  ///
  /// **Nota:** No calcula comparación para filtros anuales (requeriría más consultas a Firebase)
  static Map<String, dynamic>? _calculatePeriodComparison(
    Map<String, Map<String, dynamic>> salesByDay,
    DateFilter currentFilter,
    double Function(Map<String, dynamic>) valueExtractor,
  ) {
    if (salesByDay.isEmpty) return null;

    // No calcular para filtros anuales (requeriría consultas adicionales)
    if (currentFilter == DateFilter.thisYear ||
        currentFilter == DateFilter.lastYear) {
      return null;
    }

    final sortedDays = salesByDay.keys.toList()..sort();
    if (sortedDays.isEmpty) return null;

    // Determinar el label del período de comparación
    String comparisonLabel;
    switch (currentFilter) {
      case DateFilter.today:
        comparisonLabel = 'ayer';
        break;
      case DateFilter.yesterday:
        comparisonLabel = 'anteayer';
        break;
      case DateFilter.thisMonth:
        comparisonLabel = 'mes anterior ';
        break;
      case DateFilter.lastMonth:
        comparisonLabel = 'mes anterior';
        break;
      default:
        comparisonLabel = 'anterior';
    }

    // Para filtros de día: comparar último día con penúltimo (solo si hay múltiples días)
    if (currentFilter == DateFilter.today ||
        currentFilter == DateFilter.yesterday) {
      // Si solo hay 1 día, no hay con qué comparar sin hacer consultas adicionales
      if (sortedDays.length < 2) return null;

      final lastDay = sortedDays.last;
      final previousDay = sortedDays[sortedDays.length - 2];

      final lastDayData = salesByDay[lastDay];
      final previousDayData = salesByDay[previousDay];

      if (lastDayData == null || previousDayData == null) return null;

      final currentValue = valueExtractor(lastDayData);
      final previousValue = valueExtractor(previousDayData);

      // Debug: verificar valores
      if (kDebugMode) {
        debugPrint('📊 Comparación ${currentFilter.name}: '
            'Día actual ($lastDay) = $currentValue, '
            'Día anterior ($previousDay) = $previousValue');
      }

      return _buildComparisonResult(
          currentValue, previousValue, comparisonLabel);
    }

    // Para filtros de mes: comparar mes objetivo vs mes anterior (totales completos)
    if (currentFilter == DateFilter.thisMonth ||
        currentFilter == DateFilter.lastMonth) {
      final now = DateTime.now();

      // Rango del mes objetivo (el seleccionado)
      final DateTime targetStart = currentFilter == DateFilter.thisMonth
          ? DateTime(now.year, now.month, 1)
          : DateTime(now.year, now.month - 1, 1);
      final DateTime targetEnd = currentFilter == DateFilter.thisMonth
          ? DateTime(now.year, now.month + 1, 1)
          : DateTime(now.year, now.month, 1);

      // Rango del mes anterior inmediato
      final DateTime prevStart = currentFilter == DateFilter.thisMonth
          ? DateTime(now.year, now.month - 1, 1)
          : DateTime(now.year, now.month - 2, 1);
      final DateTime prevEnd = currentFilter == DateFilter.thisMonth
          ? DateTime(now.year, now.month, 1)
          : DateTime(now.year, now.month - 1, 1);

      double targetTotal = 0.0;
      double previousTotal = 0.0;

      bool _inRange(DateTime d, DateTime start, DateTime end) {
        // end es exclusivo
        return !d.isBefore(start) && d.isBefore(end);
      }

      for (final dayKey in sortedDays) {
        final dayDate = DateTime.parse(dayKey);
        final data = salesByDay[dayKey];
        if (data == null) continue;

        if (_inRange(dayDate, targetStart, targetEnd)) {
          targetTotal += valueExtractor(data);
        } else if (_inRange(dayDate, prevStart, prevEnd)) {
          previousTotal += valueExtractor(data);
        }
      }

      // Si falta alguno de los períodos, no mostramos comparación
      if (targetTotal == 0 && previousTotal == 0) return null;
      if (previousTotal == 0) return null;

      if (kDebugMode) {
        debugPrint('📊 Comparación ${currentFilter.name}: '
            'Mes objetivo total: $targetTotal, Mes anterior total: $previousTotal');
      }

      return _buildComparisonResult(
          targetTotal, previousTotal, comparisonLabel);
    }

    return null;
  }

  /// Construye el resultado de comparación
  static Map<String, dynamic>? _buildComparisonResult(
    double currentValue,
    double previousValue,
    String label,
  ) {
    if (previousValue == 0) {
      return currentValue > 0
          ? {'percentage': 100.0, 'isPositive': true, 'label': label}
          : null;
    }

    final percentage = ((currentValue - previousValue) / previousValue) * 100;

    return {
      'percentage': percentage,
      'isPositive': percentage >= 0,
      'currentValue': currentValue,
      'previousValue': previousValue,
      'label': label,
    };
  }
}

/// Totales del período actual (excluye el período anterior usado para comparación)
class _PeriodTotals {
  final double totalSales;
  final double totalProfit;
  final int totalTransactions;
  final double averageProfitPerTransaction;

  const _PeriodTotals({
    this.totalSales = 0.0,
    this.totalProfit = 0.0,
    this.totalTransactions = 0,
    this.averageProfitPerTransaction = 0.0,
  });
}
