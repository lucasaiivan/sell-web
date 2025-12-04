import 'package:equatable/equatable.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

/// Entity: Analíticas de Ventas
///
/// **Responsabilidad:**
/// - Representar métricas calculadas de ventas de forma inmutable
/// - Almacenar lista de transacciones para visualización
/// - Proporcionar getters computados para métricas derivadas
///
/// **Propiedades:**
/// - [totalTransactions]: Número total de ventas
/// - [totalProfit]: Ganancia total acumulada
/// - [calculatedAt]: Timestamp del cálculo
/// - [transactions]: Lista de tickets/transacciones
/// - [paymentMethodsBreakdown]: Desglose de ventas por medio de pago (Método -> Total Vendido)
/// - [paymentMethodsCount]: Conteo de transacciones por medio de pago (Método -> Cantidad)
class SalesAnalytics extends Equatable {
  /// Total de transacciones
  final int totalTransactions;

  /// Ganancia total de todas las ventas
  final double totalProfit;

  /// Momento en que se calcularon las métricas
  final DateTime calculatedAt;

  /// Lista de transacciones (tickets)
  final List<TicketModel> transactions;

  /// Desglose de ventas por medio de pago (Método -> Total Vendido)
  final Map<String, double> paymentMethodsBreakdown;

  /// Conteo de transacciones por medio de pago (Método -> Cantidad)
  final Map<String, int> paymentMethodsCount;

  const SalesAnalytics({
    required this.totalTransactions,
    required this.totalProfit,
    required this.calculatedAt,
    this.transactions = const [],
    this.paymentMethodsBreakdown = const {},
    this.paymentMethodsCount = const {},
  });

  /// Ganancia promedio por transacción
  /// Retorna 0 si no hay transacciones
  double get averageProfitPerTransaction {
    if (totalTransactions == 0) return 0.0;
    return totalProfit / totalTransactions;
  }

  /// Total de ventas (suma de priceTotal de todos los tickets)
  double get totalSales {
    return transactions.fold(0.0, (sum, t) => sum + t.priceTotal);
  }

  /// Total de productos vendidos (suma de cantidades de todos los productos)
  int get totalProductsSold {
    return transactions.fold(0, (sum, ticket) {
      return sum +
          ticket.products.fold(0, (productSum, product) {
            return productSum + product.quantity;
          });
    });
  }

  /// Obtiene los productos más vendidos ordenados por cantidad
  ///
  /// Retorna una lista de mapas con la siguiente estructura:
  /// ```dart
  /// {
  ///   'product': ProductCatalogue,  // Datos del producto
  ///   'quantitySold': int,          // Cantidad total vendida
  ///   'totalRevenue': double,       // Ingresos totales por este producto
  /// }
  /// ```
  List<Map<String, dynamic>> get topSellingProducts {
    // Filtrar tickets no anulados
    final validTransactions = transactions.where((t) => !t.annulled).toList();

    if (validTransactions.isEmpty) return [];

    // Agrupar productos por ID y acumular cantidades y revenue
    final Map<String, Map<String, dynamic>> productStats = {};

    for (final ticket in validTransactions) {
      for (final product in ticket.products) {
        final productId = product.id;

        if (!productStats.containsKey(productId)) {
          productStats[productId] = {
            'product': product,
            'quantitySold': 0,
            'totalRevenue': 0.0,
          };
        }

        productStats[productId]!['quantitySold'] =
            (productStats[productId]!['quantitySold'] as int) +
                product.quantity;
        productStats[productId]!['totalRevenue'] =
            (productStats[productId]!['totalRevenue'] as double) +
                (product.salePrice * product.quantity);
      }
    }

    // Convertir a lista y ordenar por cantidad vendida (descendente)
    final result = productStats.values.toList();
    result.sort((a, b) =>
        (b['quantitySold'] as int).compareTo(a['quantitySold'] as int));

    return result;
  }

  /// Obtiene los productos más rentables ordenados por ganancia total
  ///
  /// Retorna una lista de mapas con la siguiente estructura:
  /// ```dart
  /// {
  ///   'product': ProductCatalogue,  // Datos del producto
  ///   'quantitySold': int,          // Cantidad total vendida
  ///   'totalProfit': double,        // Ganancia total por este producto
  ///   'profitPerUnit': double,      // Ganancia por unidad
  /// }
  /// ```
  List<Map<String, dynamic>> get mostProfitableProducts {
    // Filtrar tickets no anulados
    final validTransactions = transactions.where((t) => !t.annulled).toList();

    if (validTransactions.isEmpty) return [];

    // Agrupar productos por ID y acumular ganancias
    final Map<String, Map<String, dynamic>> productStats = {};

    for (final ticket in validTransactions) {
      for (final product in ticket.products) {
        final productId = product.id;

        // Calcular ganancia por unidad (precio venta - precio compra)
        final profitPerUnit = product.salePrice - product.purchasePrice;

        // Solo incluir productos con ganancia positiva (tienen precio de compra)
        if (profitPerUnit <= 0) continue;

        if (!productStats.containsKey(productId)) {
          productStats[productId] = {
            'product': product,
            'quantitySold': 0,
            'totalProfit': 0.0,
            'profitPerUnit': profitPerUnit,
          };
        }

        productStats[productId]!['quantitySold'] =
            (productStats[productId]!['quantitySold'] as int) +
                product.quantity;
        productStats[productId]!['totalProfit'] =
            (productStats[productId]!['totalProfit'] as double) +
                (profitPerUnit * product.quantity);
      }
    }

    // Convertir a lista y ordenar por ganancia total (descendente)
    final result = productStats.values.toList();
    result.sort((a, b) =>
        (b['totalProfit'] as double).compareTo(a['totalProfit'] as double));

    return result;
  }

  /// Obtiene las ventas agrupadas por vendedor
  ///
  /// Retorna una lista de mapas ordenados por total vendido (descendente):
  /// ```dart
  /// {
  ///   'sellerId': String,         // ID del vendedor
  ///   'sellerName': String,       // Nombre del vendedor
  ///   'totalSales': double,       // Total vendido
  ///   'transactionCount': int,    // Número de transacciones
  ///   'averageTicket': double,    // Ticket promedio
  /// }
  /// ```
  List<Map<String, dynamic>> get salesBySeller {
    final validTransactions = transactions.where((t) => !t.annulled).toList();

    if (validTransactions.isEmpty) return [];

    final Map<String, Map<String, dynamic>> sellerStats = {};

    for (final ticket in validTransactions) {
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

    // Calcular ticket promedio para cada vendedor
    for (final stats in sellerStats.values) {
      final totalSales = stats['totalSales'] as double;
      final count = stats['transactionCount'] as int;
      stats['averageTicket'] = count > 0 ? totalSales / count : 0.0;
    }

    final result = sellerStats.values.toList();
    result.sort((a, b) =>
        (b['totalSales'] as double).compareTo(a['totalSales'] as double));

    return result;
  }

  /// Obtiene las ventas agrupadas por hora del día
  ///
  /// Retorna un mapa con la hora (0-23) como clave y los datos como valor:
  /// ```dart
  /// {
  ///   0: {'hour': 0, 'totalSales': double, 'transactionCount': int},
  ///   1: {'hour': 1, 'totalSales': double, 'transactionCount': int},
  ///   ...
  /// }
  /// ```
  Map<int, Map<String, dynamic>> get salesByHour {
    final validTransactions = transactions.where((t) => !t.annulled).toList();

    // Inicializar todas las horas con ceros
    final Map<int, Map<String, dynamic>> hourStats = {};
    for (int i = 0; i < 24; i++) {
      hourStats[i] = {
        'hour': i,
        'totalSales': 0.0,
        'transactionCount': 0,
      };
    }

    for (final ticket in validTransactions) {
      final hour = ticket.creation.toDate().hour;

      hourStats[hour]!['totalSales'] =
          (hourStats[hour]!['totalSales'] as double) + ticket.priceTotal;
      hourStats[hour]!['transactionCount'] =
          (hourStats[hour]!['transactionCount'] as int) + 1;
    }

    return hourStats;
  }

  /// Obtiene las horas pico (las 3 horas con más ventas)
  ///
  /// Retorna una lista ordenada de las horas con mayor actividad
  List<Map<String, dynamic>> get peakHours {
    final hourData = salesByHour;

    final hoursWithSales = hourData.values
        .where((h) => (h['transactionCount'] as int) > 0)
        .toList();

    hoursWithSales.sort((a, b) =>
        (b['totalSales'] as double).compareTo(a['totalSales'] as double));

    return hoursWithSales.take(5).toList();
  }

  /// Obtiene productos con baja rotación (vendidos pocas veces)
  ///
  /// Retorna una lista de mapas con productos vendidos 1-2 veces:
  /// ```dart
  /// {
  ///   'product': ProductCatalogue,
  ///   'quantitySold': int,
  ///   'totalRevenue': double,
  ///   'lastSoldDate': DateTime,
  /// }
  /// ```
  List<Map<String, dynamic>> get slowMovingProducts {
    final validTransactions = transactions.where((t) => !t.annulled).toList();

    if (validTransactions.isEmpty) return [];

    final Map<String, Map<String, dynamic>> productStats = {};

    for (final ticket in validTransactions) {
      for (final product in ticket.products) {
        final productId = product.id;

        if (!productStats.containsKey(productId)) {
          productStats[productId] = {
            'product': product,
            'quantitySold': 0,
            'totalRevenue': 0.0,
            'lastSoldDate': ticket.creation.toDate(),
          };
        }

        productStats[productId]!['quantitySold'] =
            (productStats[productId]!['quantitySold'] as int) +
                product.quantity;
        productStats[productId]!['totalRevenue'] =
            (productStats[productId]!['totalRevenue'] as double) +
                (product.salePrice * product.quantity);

        // Actualizar última fecha de venta si es más reciente
        final currentDate =
            productStats[productId]!['lastSoldDate'] as DateTime;
        final ticketDate = ticket.creation.toDate();
        if (ticketDate.isAfter(currentDate)) {
          productStats[productId]!['lastSoldDate'] = ticketDate;
        }
      }
    }

    // Filtrar productos con baja rotación (vendidos 5 o menos veces)
    final slowProducts = productStats.values
        .where((p) => (p['quantitySold'] as int) <= 5)
        .toList();

    // Ordenar por cantidad vendida (ascendente - los menos vendidos primero)
    slowProducts.sort((a, b) =>
        (a['quantitySold'] as int).compareTo(b['quantitySold'] as int));

    return slowProducts;
  }

  /// Constructor vacío para estado inicial
  factory SalesAnalytics.empty() {
    return SalesAnalytics(
      totalTransactions: 0,
      totalProfit: 0.0,
      calculatedAt: DateTime.now(),
      transactions: const [],
      paymentMethodsBreakdown: const {},
      paymentMethodsCount: const {},
    );
  }

  @override
  List<Object?> get props => [
        totalTransactions,
        totalProfit,
        calculatedAt,
        transactions,
        paymentMethodsBreakdown,
        paymentMethodsCount,
      ];
}
