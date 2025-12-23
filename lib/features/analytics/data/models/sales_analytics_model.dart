import 'package:sellweb/core/constants/payment_methods.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import '../../domain/entities/sales_analytics.dart';

/// Model: Analíticas de Ventas
///
/// **Responsabilidad:**
/// - Extender [SalesAnalytics] con métodos de construcción
/// - Pre-calcular TODAS las métricas desde lista de tickets (una sola vez)
/// - Evitar recálculos O(n*m) pasando datos pre-calculados al Entity
class SalesAnalyticsModel extends SalesAnalytics {
  const SalesAnalyticsModel({
    required super.totalTransactions,
    required super.totalProfit,
    required super.totalSales,
    required super.totalProductsSold,
    required super.calculatedAt,
    super.transactions,
    super.paymentMethodsBreakdown,
    super.paymentMethodsCount,
    super.topSellingProducts,
    super.mostProfitableProducts,
    super.salesBySeller,
    super.salesByHour,
    super.peakHours,
    super.slowMovingProducts,
    super.salesByDay,
    super.salesByCategory,
    super.salesByWeekday,
  });

  /// Construye el modelo desde una lista de tickets
  ///
  /// Pre-calcula TODAS las métricas una sola vez para evitar
  /// recálculos O(n*m) en cada acceso desde la UI
  factory SalesAnalyticsModel.fromTickets(List<TicketModel> tickets) {
    // Ordenar por fecha de creación (más reciente primero)
    final sortedTickets = List<TicketModel>.from(tickets)
      ..sort((a, b) => b.creation.compareTo(a.creation));

    // Filtrar tickets válidos (no anulados) para métricas
    final validTickets = sortedTickets.where((t) => !t.annulled).toList();

    // === Métricas básicas ===
    final totalTransactions = validTickets.length;
    double totalProfit = 0.0;
    double totalSales = 0.0;
    double totalProductsSold = 0.0; // Cambiado a double para soportar fraccionarios
    final Map<String, double> paymentMethodsBreakdown = {};
    final Map<String, int> paymentMethodsCount = {};

    // === Estructuras para métricas derivadas ===
    final Map<String, Map<String, dynamic>> productStats = {};
    final Map<String, Map<String, dynamic>> profitableProductStats = {};
    final Map<String, Map<String, dynamic>> sellerStats = {};
    final Map<int, Map<String, dynamic>> hourStats = {};
    final Map<String, Map<String, dynamic>> slowProductStats = {};
    final Map<String, Map<String, dynamic>> dailyStats =
        {}; // Tendencia por día
    final Map<String, Map<String, dynamic>> categoryStats = {}; // Por categoría
    final Map<int, Map<String, dynamic>> weekdayStats = {}; // Por día de semana

    // Inicializar horas (0-23)
    for (int i = 0; i < 24; i++) {
      hourStats[i] = {'hour': i, 'totalSales': 0.0, 'transactionCount': 0};
    }

    // Inicializar días de la semana (1=Lunes ... 7=Domingo)
    final weekdayNames = [
      '',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    for (int i = 1; i <= 7; i++) {
      weekdayStats[i] = {
        'dayOfWeek': i,
        'dayName': weekdayNames[i],
        'totalSales': 0.0,
        'transactionCount': 0,
        'totalProfit': 0.0,
      };
    }

    // === Un solo recorrido para calcular todo ===
    for (final ticket in validTickets) {
      totalProfit += ticket.getProfit;
      totalSales += ticket.priceTotal;

      // Medios de pago
      final rawPayMode = ticket.payMode.isEmpty ? '' : ticket.payMode;
      final normalizedPayMode = PaymentMethod.migrateLegacyCode(rawPayMode);
      final payMode = normalizedPayMode.isEmpty ? '' : normalizedPayMode;
      paymentMethodsBreakdown[payMode] =
          (paymentMethodsBreakdown[payMode] ?? 0.0) + ticket.priceTotal;
      paymentMethodsCount[payMode] = (paymentMethodsCount[payMode] ?? 0) + 1;

      // Ventas por hora
      final hour = ticket.creation.toDate().hour;
      hourStats[hour]!['totalSales'] =
          (hourStats[hour]!['totalSales'] as double) + ticket.priceTotal;
      hourStats[hour]!['transactionCount'] =
          (hourStats[hour]!['transactionCount'] as int) + 1;

      // Tendencia de ventas por día (para gráfico de línea)
      final ticketDate = ticket.creation.toDate();
      final dayKey =
          '${ticketDate.year}-${ticketDate.month.toString().padLeft(2, '0')}-${ticketDate.day.toString().padLeft(2, '0')}';
      if (!dailyStats.containsKey(dayKey)) {
        dailyStats[dayKey] = {
          'date': dayKey,
          'totalSales': 0.0,
          'transactionCount': 0,
          'totalProfit': 0.0,
        };
      }
      dailyStats[dayKey]!['totalSales'] =
          (dailyStats[dayKey]!['totalSales'] as double) + ticket.priceTotal;
      dailyStats[dayKey]!['transactionCount'] =
          (dailyStats[dayKey]!['transactionCount'] as int) + 1;
      dailyStats[dayKey]!['totalProfit'] =
          (dailyStats[dayKey]!['totalProfit'] as double) + ticket.getProfit;

      // Ventas por día de la semana (1=Lunes ... 7=Domingo)
      final weekday = ticketDate.weekday; // 1=Mon, 7=Sun
      weekdayStats[weekday]!['totalSales'] =
          (weekdayStats[weekday]!['totalSales'] as double) + ticket.priceTotal;
      weekdayStats[weekday]!['transactionCount'] =
          (weekdayStats[weekday]!['transactionCount'] as int) + 1;
      weekdayStats[weekday]!['totalProfit'] =
          (weekdayStats[weekday]!['totalProfit'] as double) + ticket.getProfit;

      // Ventas por vendedor
      final sellerId = ticket.sellerId.isEmpty ? 'unknown' : ticket.sellerId;
      final sellerName =
          ticket.sellerName.isEmpty ? 'Sin vendedor' : ticket.sellerName;
      if (!sellerStats.containsKey(sellerId)) {
        sellerStats[sellerId] = {
          'sellerId': sellerId,
          'sellerName': sellerName,
          'totalSales': 0.0,
          'transactionCount': 0,
        };
      }
      sellerStats[sellerId]!['totalSales'] =
          (sellerStats[sellerId]!['totalSales'] as double) + ticket.priceTotal;
      sellerStats[sellerId]!['transactionCount'] =
          (sellerStats[sellerId]!['transactionCount'] as int) + 1;

      // Productos
      for (final product in ticket.products) {
        final productId = product.id;
        totalProductsSold += product.quantity;

        // Top selling products
        if (!productStats.containsKey(productId)) {
          productStats[productId] = {
            'product': product,
            'quantitySold': 0.0,
            'totalRevenue': 0.0,
          };
        }
        productStats[productId]!['quantitySold'] =
            (productStats[productId]!['quantitySold'] as double) +
                product.quantity;
        productStats[productId]!['totalRevenue'] =
            (productStats[productId]!['totalRevenue'] as double) +
                (product.salePrice * product.quantity);

        // Ventas por categoría
        final categoryName = product.nameCategory.isNotEmpty
            ? product.nameCategory
            : 'Sin categoría';
        if (!categoryStats.containsKey(categoryName)) {
          categoryStats[categoryName] = {
            'category': categoryName,
            'totalSales': 0.0,
            'transactionCount': 0,
            'quantitySold': 0.0,
          };
        }
        categoryStats[categoryName]!['totalSales'] =
            (categoryStats[categoryName]!['totalSales'] as double) +
                (product.salePrice * product.quantity);
        categoryStats[categoryName]!['quantitySold'] =
            (categoryStats[categoryName]!['quantitySold'] as double) +
                product.quantity;

        // Most profitable products
        final profitPerUnit = product.salePrice - product.purchasePrice;
        if (profitPerUnit > 0) {
          final totalSalesProduct = product.salePrice * product.quantity;
          final totalCostProduct = product.purchasePrice * product.quantity;

          if (!profitableProductStats.containsKey(productId)) {
            profitableProductStats[productId] = {
              'product': product,
              'quantitySold': 0.0,
              'totalProfit': 0.0,
              'totalSales': 0.0,
              'totalCost': 0.0,
              'profitPerUnit': profitPerUnit,
            };
          }
          profitableProductStats[productId]!['quantitySold'] =
              (profitableProductStats[productId]!['quantitySold'] as double) +
                  product.quantity;
          profitableProductStats[productId]!['totalProfit'] =
              (profitableProductStats[productId]!['totalProfit'] as double) +
                  (profitPerUnit * product.quantity);
          profitableProductStats[productId]!['totalSales'] =
              (profitableProductStats[productId]!['totalSales'] as double) +
                  totalSalesProduct;
          profitableProductStats[productId]!['totalCost'] =
              (profitableProductStats[productId]!['totalCost'] as double) +
                  totalCostProduct;
        }

        // Slow moving products
        if (!slowProductStats.containsKey(productId)) {
          slowProductStats[productId] = {
            'product': product,
            'quantitySold': 0.0,
            'totalRevenue': 0.0,
            'lastSoldDate': ticket.creation.toDate(),
          };
        }
        slowProductStats[productId]!['quantitySold'] =
            (slowProductStats[productId]!['quantitySold'] as double) +
                product.quantity;
        slowProductStats[productId]!['totalRevenue'] =
            (slowProductStats[productId]!['totalRevenue'] as double) +
                (product.salePrice * product.quantity);
        final currentDate =
            slowProductStats[productId]!['lastSoldDate'] as DateTime;
        final ticketDate = ticket.creation.toDate();
        if (ticketDate.isAfter(currentDate)) {
          slowProductStats[productId]!['lastSoldDate'] = ticketDate;
        }
      }
    }

    // === Procesar y ordenar resultados ===

    // Top selling products (ordenar por cantidad)
    final topSellingProducts = productStats.values.toList()
      ..sort((a, b) =>
          (b['quantitySold'] as double).compareTo(a['quantitySold'] as double));

    // Most profitable products (ordenar por ganancia)
    final mostProfitableProducts = profitableProductStats.values.toList()
      ..sort((a, b) =>
          (b['totalProfit'] as double).compareTo(a['totalProfit'] as double));

    // Sellers (calcular ticket promedio y ordenar)
    for (final stats in sellerStats.values) {
      final totalSalesVal = stats['totalSales'] as double;
      final count = stats['transactionCount'] as int;
      stats['averageTicket'] = count > 0 ? totalSalesVal / count : 0.0;
    }
    final salesBySeller = sellerStats.values.toList()
      ..sort((a, b) =>
          (b['totalSales'] as double).compareTo(a['totalSales'] as double));

    // Peak hours (top 5 con ventas)
    final peakHours = hourStats.values
        .where((h) => (h['transactionCount'] as int) > 0)
        .toList()
      ..sort((a, b) =>
          (b['totalSales'] as double).compareTo(a['totalSales'] as double));

    // Slow moving products (vendidos <= 5 veces)
    final slowMovingProducts = slowProductStats.values
        .where((p) => (p['quantitySold'] as double) <= 5.0)
        .toList()
      ..sort((a, b) =>
          (a['quantitySold'] as double).compareTo(b['quantitySold'] as double));

    // Ventas por categoría (ordenar por ventas y calcular porcentaje)
    final salesByCategory = categoryStats.values.toList()
      ..sort((a, b) =>
          (b['totalSales'] as double).compareTo(a['totalSales'] as double));
    // Calcular porcentajes
    for (final cat in salesByCategory) {
      cat['percentage'] = totalSales > 0
          ? (cat['totalSales'] as double) / totalSales * 100
          : 0.0;
    }

    // Tendencia de ventas por día (ordenar por fecha)
    final salesByDay = Map<String, Map<String, dynamic>>.fromEntries(
      dailyStats.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    // Calcular promedio por día de semana
    for (final stats in weekdayStats.values) {
      final count = stats['transactionCount'] as int;
      stats['averageSales'] =
          count > 0 ? (stats['totalSales'] as double) / count : 0.0;
    }

    return SalesAnalyticsModel(
      totalTransactions: totalTransactions,
      totalProfit: totalProfit,
      totalSales: totalSales,
      totalProductsSold: totalProductsSold,
      calculatedAt: DateTime.now(),
      transactions: sortedTickets, // Incluye anulados para visualización
      paymentMethodsBreakdown: paymentMethodsBreakdown,
      paymentMethodsCount: paymentMethodsCount,
      topSellingProducts: topSellingProducts,
      mostProfitableProducts: mostProfitableProducts,
      salesBySeller: salesBySeller,
      salesByHour: hourStats,
      peakHours: peakHours.take(5).toList(),
      slowMovingProducts: slowMovingProducts,
      salesByDay: salesByDay,
      salesByCategory: salesByCategory,
      salesByWeekday: weekdayStats,
    );
  }

  /// Convierte el modelo a Entity
  SalesAnalytics toEntity() {
    return SalesAnalytics(
      totalTransactions: totalTransactions,
      totalProfit: totalProfit,
      totalSales: totalSales,
      totalProductsSold: totalProductsSold,
      calculatedAt: calculatedAt,
      transactions: transactions,
      paymentMethodsBreakdown: paymentMethodsBreakdown,
      paymentMethodsCount: paymentMethodsCount,
      topSellingProducts: topSellingProducts,
      mostProfitableProducts: mostProfitableProducts,
      salesBySeller: salesBySeller,
      salesByHour: salesByHour,
      peakHours: peakHours,
      slowMovingProducts: slowMovingProducts,
      salesByDay: salesByDay,
      salesByCategory: salesByCategory,
      salesByWeekday: salesByWeekday,
    );
  }

  /// Constructor vacío
  factory SalesAnalyticsModel.empty() {
    return SalesAnalyticsModel(
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
}
