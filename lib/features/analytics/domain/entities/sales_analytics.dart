import 'package:equatable/equatable.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'date_filter.dart';

/// Entity: Analíticas de Ventas
///
/// **Responsabilidad:**
/// - Representar métricas calculadas de ventas de forma inmutable
/// - Almacenar datos pre-calculados para evitar recálculos O(n*m)
///
/// **Optimización:** Métricas derivadas se calculan una sola vez en el Model
/// y se pasan como campos finales para evitar recálculos en cada render.
class SalesAnalytics extends Equatable {
  /// Total de transacciones (no anuladas)
  final int totalTransactions;

  /// Ganancia total de todas las ventas
  final double totalProfit;

  /// Total de ventas (suma de priceTotal)
  final double totalSales;

  /// Total de productos vendidos
  final int totalProductsSold;

  /// Momento en que se calcularon las métricas
  final DateTime calculatedAt;

  /// Lista de transacciones (tickets) para visualización en UI
  final List<TicketModel> transactions;

  /// Desglose de ventas por medio de pago (Método -> Total Vendido)
  final Map<String, double> paymentMethodsBreakdown;

  /// Conteo de transacciones por medio de pago (Método -> Cantidad)
  final Map<String, int> paymentMethodsCount;

  // === Métricas pre-calculadas (evita recálculos O(n*m) en cada acceso) ===

  /// Productos más vendidos ordenados por cantidad
  final List<Map<String, dynamic>> topSellingProducts;

  /// Productos más rentables ordenados por ganancia
  final List<Map<String, dynamic>> mostProfitableProducts;

  /// Ventas agrupadas por vendedor
  final List<Map<String, dynamic>> salesBySeller;

  /// Ventas agrupadas por hora del día (0-23)
  final Map<int, Map<String, dynamic>> salesByHour;

  /// Horas pico (top 5 con más ventas)
  final List<Map<String, dynamic>> peakHours;

  /// Productos con baja rotación
  final List<Map<String, dynamic>> slowMovingProducts;

  /// Tendencia de ventas por día (fecha -> {totalSales, transactionCount, profit})
  /// Para gráfico de línea temporal
  final Map<String, Map<String, dynamic>> salesByDay;

  /// Distribución de ventas por categoría de producto
  /// Estructura: [{ 'category': String, 'totalSales': double, 'percentage': double, 'transactionCount': int }]
  final List<Map<String, dynamic>> salesByCategory;

  /// Ventas agrupadas por día de la semana (1=Lunes ... 7=Domingo)
  /// Estructura: { dayOfWeek: { 'dayName': String, 'totalSales': double, 'transactionCount': int, 'averageSales': double } }
  final Map<int, Map<String, dynamic>> salesByWeekday;

  const SalesAnalytics({
    required this.totalTransactions,
    required this.totalProfit,
    required this.totalSales,
    required this.totalProductsSold,
    required this.calculatedAt,
    this.transactions = const [],
    this.paymentMethodsBreakdown = const {},
    this.paymentMethodsCount = const {},
    this.topSellingProducts = const [],
    this.mostProfitableProducts = const [],
    this.salesBySeller = const [],
    this.salesByHour = const {},
    this.peakHours = const [],
    this.slowMovingProducts = const [],
    this.salesByDay = const {},
    this.salesByCategory = const [],
    this.salesByWeekday = const {},
  });

  /// Ganancia promedio por transacción
  double get averageProfitPerTransaction {
    if (totalTransactions == 0) return 0.0;
    return totalProfit / totalTransactions;
  }

  /// Constructor vacío para estado inicial
  factory SalesAnalytics.empty() {
    return SalesAnalytics(
      totalTransactions: 0,
      totalProfit: 0.0,
      totalSales: 0.0,
      totalProductsSold: 0,
      calculatedAt: DateTime.now(),
      transactions: const [],
      paymentMethodsBreakdown: const {},
      paymentMethodsCount: const {},
      topSellingProducts: const [],
      mostProfitableProducts: const [],
      salesBySeller: const [],
      salesByHour: const {},
      peakHours: const [],
      slowMovingProducts: const [],
      salesByDay: const {},
      salesByCategory: const [],
      salesByWeekday: const {},
    );
  }


  /// Totales calculados para un rango de fechas específico
  /// Retorna un Record con los valores agregados
  ({
    double totalSales,
    double totalProfit,
    int totalTransactions,
    double averageProfitPerTransaction
  }) getTotalsForFilter(DateFilter filter) {
    // Determinar rango de fechas
    final now = DateTime.now();
    DateTime rangeStart;
    DateTime rangeEnd; // Exclusivo

    switch (filter) {
      case DateFilter.today:
        rangeStart = DateTime(now.year, now.month, now.day);
        rangeEnd = rangeStart.add(const Duration(days: 1));
        break;
      case DateFilter.yesterday:
        rangeStart = DateTime(now.year, now.month, now.day - 1);
        rangeEnd = DateTime(now.year, now.month, now.day);
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

    double totalSales = 0.0;
    double totalProfit = 0.0;
    int totalTransactions = 0;

    bool inRange(DateTime d) =>
        !d.isBefore(rangeStart) && d.isBefore(rangeEnd);

    for (final entry in salesByDay.entries) {
      final dayDate = DateTime.parse(entry.key);
      if (!inRange(dayDate)) continue;

      final data = entry.value;
      totalSales += data['totalSales'] as double? ?? 0.0;
      totalProfit += data['totalProfit'] as double? ?? 0.0;
      totalTransactions += data['transactionCount'] as int? ?? 0;
    }

    final avgProfitPerTx =
        totalTransactions > 0 ? totalProfit / totalTransactions : 0.0;

    return (
      totalSales: totalSales,
      totalProfit: totalProfit,
      totalTransactions: totalTransactions,
      averageProfitPerTransaction: avgProfitPerTx,
    );
  }

  /// Calcula la comparación con el periodo anterior
  /// Retorna un map con el porcentaje y label, o null si no aplica
  Map<String, dynamic>? getPeriodComparison(
    DateFilter currentFilter,
    double Function(Map<String, dynamic>) valueExtractor,
  ) {
    if (salesByDay.isEmpty) return null;

    // No calcular para filtros anuales
    if (currentFilter == DateFilter.thisYear ||
        currentFilter == DateFilter.lastYear) {
      return null;
    }

    final sortedDays = salesByDay.keys.toList()..sort();
    if (sortedDays.isEmpty) return null;

    String comparisonLabel;
    switch (currentFilter) {
      case DateFilter.today:
        comparisonLabel = 'ayer';
        break;
      case DateFilter.yesterday:
        comparisonLabel = 'anteayer';
        break;
      case DateFilter.thisMonth:
        comparisonLabel = 'el mes pasado';
        break;
      case DateFilter.lastMonth:
        comparisonLabel = 'el mes anterior';
        break;
      default:
        comparisonLabel = 'antes';
    }

    // Lógica para días (today/yesterday)
    if (currentFilter == DateFilter.today ||
        currentFilter == DateFilter.yesterday) {
      if (sortedDays.length < 2) return null;

      final lastDay = sortedDays.last;
      final previousDay = sortedDays[sortedDays.length - 2];

      final lastDayData = salesByDay[lastDay];
      final previousDayData = salesByDay[previousDay];

      if (lastDayData == null || previousDayData == null) return null;

      final currentValue = valueExtractor(lastDayData);
      final previousValue = valueExtractor(previousDayData);

      return _buildComparisonResult(
          currentValue, previousValue, comparisonLabel);
    }

    // Lógica para meses (thisMonth/lastMonth)
    if (currentFilter == DateFilter.thisMonth ||
        currentFilter == DateFilter.lastMonth) {
      final now = DateTime.now();

      final DateTime targetStart = currentFilter == DateFilter.thisMonth
          ? DateTime(now.year, now.month, 1)
          : DateTime(now.year, now.month - 1, 1);
      final DateTime targetEnd = currentFilter == DateFilter.thisMonth
          ? DateTime(now.year, now.month + 1, 1)
          : DateTime(now.year, now.month, 1);

      final DateTime prevStart = currentFilter == DateFilter.thisMonth
          ? DateTime(now.year, now.month - 1, 1)
          : DateTime(now.year, now.month - 2, 1);
      final DateTime prevEnd = currentFilter == DateFilter.thisMonth
          ? DateTime(now.year, now.month, 1)
          : DateTime(now.year, now.month - 1, 1);

      double targetTotal = 0.0;
      double previousTotal = 0.0;

      bool inRange(DateTime d, DateTime start, DateTime end) =>
          !d.isBefore(start) && d.isBefore(end);

      for (final dayKey in sortedDays) {
        final dayDate = DateTime.parse(dayKey);
        final data = salesByDay[dayKey];
        if (data == null) continue;

        if (inRange(dayDate, targetStart, targetEnd)) {
          targetTotal += valueExtractor(data);
        } else if (inRange(dayDate, prevStart, prevEnd)) {
          previousTotal += valueExtractor(data);
        }
      }

      if (previousTotal == 0) return null;

      return _buildComparisonResult(
          targetTotal, previousTotal, comparisonLabel);
    }

    return null;
  }

  Map<String, dynamic>? _buildComparisonResult(
    double currentValue,
    double previousValue,
    String label,
  ) {
    if (previousValue == 0) return null;

    final percentage = ((currentValue - previousValue) / previousValue) * 100;
    
    return {
      'percentage': percentage,
      'label': label,
      'isPositive': percentage >= 0,
    };
  }

  @override
  List<Object?> get props => [
        totalTransactions,
        totalProfit,
        totalSales,
        totalProductsSold,
        calculatedAt,
        transactions,
        paymentMethodsBreakdown,
        paymentMethodsCount,
        topSellingProducts,
        mostProfitableProducts,
        salesBySeller,
        peakHours,
        slowMovingProducts,
        salesByDay,
        salesByCategory,
        salesByWeekday,
      ];
}

