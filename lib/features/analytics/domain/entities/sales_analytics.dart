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
      return sum + ticket.products.fold(0, (productSum, product) {
        return productSum + product.quantity;
      });
    });
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
