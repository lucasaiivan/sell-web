import 'package:equatable/equatable.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

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
    );
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
      ];
}
