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

  /// Total de productos vendidos (soporta cantidades fraccionarias)
  final double totalProductsSold;

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
  /// Estructura: [{ 'category': String, 'totalSales': double, 'percentage': double, 'quantitySold': double, 'transactionCount': int }]
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
  /// Helper: Obtiene el rango de fechas para un filtro
  ({DateTime start, DateTime end}) _getDateRangeForFilter(DateFilter filter) {
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

    return (start: rangeStart, end: rangeEnd);
  }

  /// Obtiene las transacciones filtradas por rango de fechas (solo efectivas, NO anuladas)
  /// Usar para métricas donde las anuladas NO deben contar
  List<TicketModel> getFilteredTransactions(DateFilter filter) {
    final range = _getDateRangeForFilter(filter);
    bool inRange(DateTime d) =>
        !d.isBefore(range.start) && d.isBefore(range.end);

    return transactions.where((ticket) {
      if (ticket.annulled) return false;
      final ticketDate = ticket.creation.toDate();
      return inRange(ticketDate);
    }).toList();
  }

  /// Obtiene TODAS las transacciones filtradas por rango de fechas (incluyendo anuladas)
  /// Usar para visualización de historial donde el usuario debe ver todas las transacciones
  /// Las transacciones anuladas se muestran con indicador visual pero NO afectan métricas
  List<TicketModel> getAllTransactionsForFilter(DateFilter filter) {
    final range = _getDateRangeForFilter(filter);
    bool inRange(DateTime d) =>
        !d.isBefore(range.start) && d.isBefore(range.end);

    return transactions.where((ticket) {
      final ticketDate = ticket.creation.toDate();
      return inRange(ticketDate);
    }).toList();
  }

  /// Obtiene el desglose de métodos de pago filtrado por rango de fechas
  Map<String, double> getPaymentMethodsForFilter(DateFilter filter) {
    final filteredTransactions = getFilteredTransactions(filter);
    final filteredPaymentMethods = <String, double>{};

    for (final ticket in filteredTransactions) {
      final payMode = ticket.payMode.isEmpty ? '' : ticket.payMode;
      filteredPaymentMethods[payMode] =
          (filteredPaymentMethods[payMode] ?? 0.0) + ticket.priceTotal;
    }

    return filteredPaymentMethods;
  }

  /// Obtiene productos más vendidos filtrados por rango de fechas
  List<Map<String, dynamic>> getTopSellingProductsForFilter(DateFilter filter) {
    final filteredTransactions = getFilteredTransactions(filter);
    final productStats = <String, Map<String, dynamic>>{};

    for (final ticket in filteredTransactions) {
      for (final product in ticket.products) {
        final productId = product.id;
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
      }
    }

    final sortedProducts = productStats.values.toList()
      ..sort((a, b) =>
          (b['quantitySold'] as double).compareTo(a['quantitySold'] as double));

    return sortedProducts;
  }

  /// Obtiene productos más rentables filtrados por rango de fechas
  List<Map<String, dynamic>> getMostProfitableProductsForFilter(
      DateFilter filter) {
    final filteredTransactions = getFilteredTransactions(filter);
    final profitableStats = <String, Map<String, dynamic>>{};

    for (final ticket in filteredTransactions) {
      for (final product in ticket.products) {
        final productId = product.id;
        final profit =
            (product.salePrice - product.purchasePrice) * product.quantity;

        if (!profitableStats.containsKey(productId)) {
          profitableStats[productId] = {
            'product': product, // obj
            'totalProfit': 0.0, // total ganancia
            'quantitySold': 0.0, // cantidad vendida (soporta fraccionarios)
            'profitPerUnit': (product.salePrice -
                product.purchasePrice), // ganancia por unidad
          };
        }
        profitableStats[productId]!['totalProfit'] =
            (profitableStats[productId]!['totalProfit'] as double) + profit;
        profitableStats[productId]!['quantitySold'] =
            (profitableStats[productId]!['quantitySold'] as double) +
                product.quantity;
      }
    }

    final sortedProducts = profitableStats.values.toList()
      ..sort((a, b) =>
          (b['totalProfit'] as double).compareTo(a['totalProfit'] as double));

    return sortedProducts;
  }

  /// Obtiene distribución de ventas por categoría filtrada por rango de fechas
  List<Map<String, dynamic>> getSalesByCategoryForFilter(DateFilter filter) {
    final filteredTransactions = getFilteredTransactions(filter);
    final categoryStats = <String, Map<String, dynamic>>{};
    double totalSales = 0.0;

    for (final ticket in filteredTransactions) {
      for (final product in ticket.products) {
        final category = product.nameCategory.isEmpty
            ? 'Sin categoría'
            : product.nameCategory;
        final sales = product.salePrice * product.quantity;

        if (!categoryStats.containsKey(category)) {
          categoryStats[category] = {
            'category': category,
            'totalSales': 0.0,
            'quantitySold': 0.0,
            'transactionCount': 0,
          };
        }
        categoryStats[category]!['totalSales'] =
            (categoryStats[category]!['totalSales'] as double) + sales;
        categoryStats[category]!['quantitySold'] =
            (categoryStats[category]!['quantitySold'] as double) +
                product.quantity;
        totalSales += sales;
      }
    }

    // Agregar porcentajes
    final result = categoryStats.values.map((stat) {
      final sales = stat['totalSales'] as double;
      stat['percentage'] = totalSales > 0 ? (sales / totalSales * 100) : 0.0;
      return stat;
    }).toList()
      ..sort((a, b) =>
          (b['totalSales'] as double).compareTo(a['totalSales'] as double));

    return result;
  }

  /// Obtiene tendencia de ventas por día filtrada por rango de fechas
  Map<String, Map<String, dynamic>> getSalesByDayForFilter(DateFilter filter) {
    final range = _getDateRangeForFilter(filter);
    bool inRange(DateTime d) =>
        !d.isBefore(range.start) && d.isBefore(range.end);

    final filteredDailySales = <String, Map<String, dynamic>>{};

    for (final entry in salesByDay.entries) {
      final dayDate = DateTime.parse(entry.key);
      if (inRange(dayDate)) {
        filteredDailySales[entry.key] = entry.value;
      }
    }

    return filteredDailySales;
  }

  /// Obtiene ventas por hora filtradas por rango de fechas
  Map<int, Map<String, dynamic>> getSalesByHourForFilter(DateFilter filter) {
    final filteredTransactions = getFilteredTransactions(filter);
    final hourStats = <int, Map<String, dynamic>>{};

    // Inicializar todas las horas (0-23)
    for (int i = 0; i < 24; i++) {
      hourStats[i] = {'hour': i, 'totalSales': 0.0, 'transactionCount': 0};
    }

    // Acumular ventas por hora
    for (final ticket in filteredTransactions) {
      final hour = ticket.creation.toDate().hour;
      hourStats[hour]!['totalSales'] =
          (hourStats[hour]!['totalSales'] as double) + ticket.priceTotal;
      hourStats[hour]!['transactionCount'] =
          (hourStats[hour]!['transactionCount'] as int) + 1;
    }

    return hourStats;
  }

  /// Obtiene horas pico filtradas por rango de fechas
  List<Map<String, dynamic>> getPeakHoursForFilter(DateFilter filter) {
    final hourStats = getSalesByHourForFilter(filter);

    // Filtrar solo horas con transacciones y ordenar por ventas
    final peakHours = hourStats.values
        .where((stat) => (stat['transactionCount'] as int) > 0)
        .toList()
      ..sort((a, b) =>
          (b['totalSales'] as double).compareTo(a['totalSales'] as double));

    return peakHours.take(5).toList();
  }

  /// Ventas por día de la semana con estrategias según filtro
  ///
  /// **Filtros `hoy/ayer`:** Map con índices 0-6, últimos 7 días cronológicos
  /// - `shortLabel`: Inicial del día (L, M, X, J, V, S, D)
  /// - `isHighlighted`: Marca el día del filtro seleccionado
  /// - Datos calculados desde todas las transacciones disponibles
  ///
  /// **Otros filtros:** Map con claves 1-7 (lunes-domingo), agregación general
  Map<int, Map<String, dynamic>> getSalesByWeekdayForFilter(DateFilter filter) {
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

    // Para filtros "hoy" y "ayer": retornar últimos 7 días cronológicos
    if (filter == DateFilter.today || filter == DateFilter.yesterday) {
      final now = DateTime.now();

      // Calcular los 7 días a visualizar
      final last7Days = <DateTime>[];

      if (filter == DateFilter.today) {
        // "Hoy": [hace6, hace5, hace4, hace3, hace2, hace1, HOY]
        final today = DateTime(now.year, now.month, now.day);
        for (int i = 6; i >= 0; i--) {
          last7Days.add(today.subtract(Duration(days: i)));
        }
      } else {
        // "Ayer": [hace5, hace4, hace3, hace2, hace1, AYER, hoy]
        final yesterday = DateTime(now.year, now.month, now.day - 1);
        for (int i = 5; i >= -1; i--) {
          last7Days.add(yesterday.subtract(Duration(days: i)));
        }
      }

      // Día de referencia a destacar (con isHighlighted=true)
      final referenceDate = filter == DateFilter.today
          ? DateTime(now.year, now.month, now.day)
          : DateTime(now.year, now.month, now.day - 1);

      // Construir mapa con índice 0-6 para días cronológicos
      // Calcular desde todas las transacciones disponibles
      final chronologicalDays = <int, Map<String, dynamic>>{};

      for (int i = 0; i < last7Days.length; i++) {
        final date = last7Days[i];
        final weekday = date.weekday; // 1=Mon, 7=Sun
        final isTargetDay = date.day == referenceDate.day &&
            date.month == referenceDate.month &&
            date.year == referenceDate.year;

        // Calcular métricas para este día desde todas las transacciones cargadas
        // (datasource carga 7 días completos para permitir esta visualización)
        double totalSales = 0.0;
        int transactionCount = 0;
        double totalProfit = 0.0;

        for (final ticket in transactions) {
          if (ticket.annulled) continue;

          final ticketDate = ticket.creation.toDate();
          if (ticketDate.year == date.year &&
              ticketDate.month == date.month &&
              ticketDate.day == date.day) {
            totalSales += ticket.priceTotal;
            transactionCount++;
            totalProfit += ticket.getProfit;
          }
        }

        // Obtener inicial del día (L, M, X, J, V, S, D)
        String shortDayName;
        switch (weekday) {
          case 1:
            shortDayName = 'L';
            break;
          case 2:
            shortDayName = 'M';
            break;
          case 3:
            shortDayName = 'X';
            break;
          case 4:
            shortDayName = 'J';
            break;
          case 5:
            shortDayName = 'V';
            break;
          case 6:
            shortDayName = 'S';
            break;
          case 7:
            shortDayName = 'D';
            break;
          default:
            shortDayName = '?';
        }

        final dayKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        chronologicalDays[i] = {
          'index': i, // Posición en array (0-6)
          'date': date, // DateTime completo
          'dateKey': dayKey, // yyyy-MM-dd para agrupación
          'dayOfWeek': weekday, // 1=Lun ... 7=Dom
          'dayName': weekdayNames[weekday], // "Lunes", "Martes", etc.
          'dayLabel':
              '${weekdayNames[weekday].substring(0, 3)} ${date.day}', // "Lun 10"
          'shortLabel': shortDayName, // "L", "M", "X", etc.
          'totalSales': totalSales, // Total vendido ese día
          'transactionCount': transactionCount, // Número de tickets
          'totalProfit': totalProfit, // Ganancia neta
          'isToday': filter == DateFilter.today && isTargetDay, // ¿Es hoy?
          'isYesterday':
              filter == DateFilter.yesterday && isTargetDay, // ¿Es ayer?
          'isHighlighted': isTargetDay, // Día a destacar visualmente
        };
      }

      return chronologicalDays;
    }

    // Para otros filtros: análisis general por día de semana (1-7)
    final weekdayStats = <int, Map<String, dynamic>>{};
    for (int i = 1; i <= 7; i++) {
      weekdayStats[i] = {
        'dayOfWeek': i,
        'dayName': weekdayNames[i],
        'dayNumber': i,
        'totalSales': 0.0,
        'transactionCount': 0,
        'totalProfit': 0.0,
      };
    }

    final filteredTransactions = getFilteredTransactions(filter);

    // Acumular ventas por día de la semana
    for (final ticket in filteredTransactions) {
      final weekday = ticket.creation.toDate().weekday; // 1=Mon, 7=Sun
      weekdayStats[weekday]!['totalSales'] =
          (weekdayStats[weekday]!['totalSales'] as double) + ticket.priceTotal;
      weekdayStats[weekday]!['transactionCount'] =
          (weekdayStats[weekday]!['transactionCount'] as int) + 1;
      weekdayStats[weekday]!['totalProfit'] =
          (weekdayStats[weekday]!['totalProfit'] as double) + ticket.getProfit;
    }

    return weekdayStats;
  }

  /// Obtiene ventas por vendedor filtradas por rango de fechas
  List<Map<String, dynamic>> getSalesBySellerForFilter(DateFilter filter) {
    final filteredTransactions = getFilteredTransactions(filter);
    final sellerStats = <String, Map<String, dynamic>>{};

    for (final ticket in filteredTransactions) {
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
    }

    // Calcular promedio de ticket por vendedor
    final sortedSellers = sellerStats.values.map((seller) {
      final totalSales = seller['totalSales'] as double;
      final transactionCount = seller['transactionCount'] as int;
      seller['averageTicket'] =
          transactionCount > 0 ? totalSales / transactionCount : 0.0;
      return seller;
    }).toList()
      ..sort((a, b) =>
          (b['totalSales'] as double).compareTo(a['totalSales'] as double));

    return sortedSellers;
  }

  /// Retorna un Record con los valores agregados
  ({
    double totalSales,
    double totalProfit,
    int totalTransactions,
    double averageProfitPerTransaction,
    double averageTicket
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

    bool inRange(DateTime d) => !d.isBefore(rangeStart) && d.isBefore(rangeEnd);

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
    final avgTicket =
        totalTransactions > 0 ? totalSales / totalTransactions : 0.0;

    return (
      totalSales: totalSales,
      totalProfit: totalProfit,
      totalTransactions: totalTransactions,
      averageProfitPerTransaction: avgProfitPerTx,
      averageTicket: avgTicket,
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
