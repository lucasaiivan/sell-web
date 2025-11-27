import 'package:sellweb/core/constants/payment_methods.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import '../../domain/entities/sales_analytics.dart';

/// Model: Analíticas de Ventas
///
/// **Responsabilidad:**
/// - Extender [SalesAnalytics] con métodos de construcción
/// - Calcular métricas desde lista de tickets
///
/// **Nota:** No usa fromFirestore porque las métricas se calculan en memoria
class SalesAnalyticsModel extends SalesAnalytics {
  const SalesAnalyticsModel({
    required super.totalTransactions,
    required super.totalProfit,
    required super.calculatedAt,
    super.transactions,
    super.paymentMethodsBreakdown,
    super.paymentMethodsCount,
  });

  /// Construye el modelo desde una lista de tickets
  ///
  /// Calcula:
  /// - Total de transacciones: cantidad de tickets
  /// - Ganancia total: suma de [TicketModel.getProfit] de cada ticket
  /// - Desglose por medio de pago
  factory SalesAnalyticsModel.fromTickets(List<TicketModel> tickets) {
    // Ordenar por fecha de creación (más reciente primero)
    final sortedTickets = List<TicketModel>.from(tickets)
      ..sort((a, b) => b.creation.compareTo(a.creation));

    final totalTransactions = sortedTickets.length;
    double totalProfit = 0.0;
    final Map<String, double> paymentMethodsBreakdown = {};
    final Map<String, int> paymentMethodsCount = {};

    for (var ticket in sortedTickets) {
      totalProfit += ticket.getProfit;
      
      // Normalizar payMode con códigos legacy (mercadopago → transfer, etc)
      final rawPayMode = ticket.payMode.isEmpty ? '' : ticket.payMode;
      final normalizedPayMode = PaymentMethod.migrateLegacyCode(rawPayMode);
      final payMode = normalizedPayMode.isEmpty ? 'Desconocido' : normalizedPayMode;
      
      // Acumular total vendido por medio de pago
      paymentMethodsBreakdown[payMode] = (paymentMethodsBreakdown[payMode] ?? 0.0) + ticket.priceTotal;
      
      // Contar transacciones por medio de pago
      paymentMethodsCount[payMode] = (paymentMethodsCount[payMode] ?? 0) + 1;
    }

    return SalesAnalyticsModel(
      totalTransactions: totalTransactions,
      totalProfit: totalProfit,
      calculatedAt: DateTime.now(),
      transactions: sortedTickets,
      paymentMethodsBreakdown: paymentMethodsBreakdown,
      paymentMethodsCount: paymentMethodsCount,
    );
  }

  /// Convierte el modelo a Entity
  SalesAnalytics toEntity() {
    return SalesAnalytics(
      totalTransactions: totalTransactions,
      totalProfit: totalProfit,
      calculatedAt: calculatedAt,
      transactions: transactions,
      paymentMethodsBreakdown: paymentMethodsBreakdown,
      paymentMethodsCount: paymentMethodsCount,
    );
  }

  /// Constructor vacío
  factory SalesAnalyticsModel.empty() {
    return SalesAnalyticsModel(
      totalTransactions: 0,
      totalProfit: 0.0,
      calculatedAt: DateTime.now(),
      transactions: const [],
      paymentMethodsBreakdown: const {},
      paymentMethodsCount: const {},
    );
  }
}
