import 'package:equatable/equatable.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

/// Entidad inmutable que centraliza todas las métricas de una caja registradora.
///
/// **Responsabilidad:**
/// - Calcular y almacenar métricas derivadas de [CashRegister] y [TicketModel]
/// - Proveer datos pre-calculados para evitar recálculos O(n) en cada render
/// - Ser la única fuente de verdad para métricas financieras de caja
///
/// **Arquitectura:**
/// - Inmutable (Equatable) para optimizar comparaciones en Selectors
/// - Factory constructor que realiza todos los cálculos
/// - Getters de conveniencia para métricas derivadas
///
/// **Uso:**
/// ```dart
/// final metrics = CashRegisterMetrics.calculate(
///   cashRegister: activeCashRegister,
///   tickets: ticketsList,
/// );
/// print(metrics.expectedBalance); // Balance esperado
/// print(metrics.netProfit);       // Ganancia neta
/// ```
class CashRegisterMetrics extends Equatable {
  // ==========================================
  // DATOS DE ORIGEN
  // ==========================================

  /// Caja registradora de origen
  final CashRegister cashRegister;

  /// Lista de tickets asociados a esta caja
  final List<TicketModel> tickets;

  // ==========================================
  // MÉTRICAS DE VENTAS (calculadas desde tickets)
  // ==========================================

  /// Facturación total: suma de priceTotal de tickets activos (NO anulados)
  /// NOTA: priceTotal ya incluye descuentos aplicados
  final double totalBilling;

  /// Ganancia bruta: suma de (precioVenta - precioCosto) * cantidad
  /// de todos los productos en tickets activos, menos descuentos
  final double totalProfit;

  /// Total de descuentos aplicados en tickets activos
  final double totalDiscount;

  /// Cantidad de ventas efectivas (tickets NO anulados)
  final int effectiveSalesCount;

  /// Cantidad de tickets anulados
  final int annulledCount;

  // ==========================================
  // MÉTRICAS DE FLUJO DE CAJA
  // ==========================================

  /// Monto inicial de apertura de caja
  final double initialCash;

  /// Total de ingresos manuales (entradas de efectivo)
  final double totalInflows;

  /// Total de egresos manuales (salidas de efectivo) - valor absoluto
  final double totalOutflows;

  // ==========================================
  // MÉTRICAS CONSOLIDADAS
  // ==========================================

  /// Balance esperado en caja: initialCash + billing + inflows - outflows
  /// Fórmula: Lo que DEBERÍA haber físicamente en la caja
  final double expectedBalance;

  /// Desglose de métodos de pago: {método -> monto total}
  final Map<String, double> paymentMethodsBreakdown;

  /// Desglose de métodos de pago: {método -> cantidad de transacciones}
  final Map<String, int> paymentMethodsCount;

  /// Timestamp de cuando se calcularon las métricas
  final DateTime calculatedAt;

  // ==========================================
  // CONSTRUCTOR PRIVADO
  // ==========================================

  const CashRegisterMetrics._({
    required this.cashRegister,
    required this.tickets,
    required this.totalBilling,
    required this.totalProfit,
    required this.totalDiscount,
    required this.effectiveSalesCount,
    required this.annulledCount,
    required this.initialCash,
    required this.totalInflows,
    required this.totalOutflows,
    required this.expectedBalance,
    required this.paymentMethodsBreakdown,
    required this.paymentMethodsCount,
    required this.calculatedAt,
  });

  // ==========================================
  // FACTORY CONSTRUCTOR - CÁLCULO CENTRALIZADO
  // ==========================================

  /// Calcula todas las métricas desde [CashRegister] y [tickets].
  ///
  /// **Optimización:** Realiza un solo recorrido O(n) de los tickets
  /// para calcular todas las métricas simultáneamente.
  factory CashRegisterMetrics.calculate({
    required CashRegister cashRegister,
    required List<TicketModel> tickets,
  }) {
    // Variables de acumulación
    double totalBilling = 0.0;
    double totalProfit = 0.0;
    double totalDiscount = 0.0;
    int effectiveSalesCount = 0;
    int annulledCount = 0;
    final Map<String, double> paymentMethodsBreakdown = {};
    final Map<String, int> paymentMethodsCount = {};

    // Un solo recorrido O(n) para calcular todo
    for (final ticket in tickets) {
      if (ticket.annulled) {
        annulledCount++;
        continue; // No incluir anulados en métricas
      }

      // Contadores
      effectiveSalesCount++;

      // Facturación (priceTotal ya tiene descuento aplicado)
      totalBilling += ticket.priceTotal;

      // Ganancia (el getter getProfit ya resta descuentos)
      totalProfit += ticket.getProfit;

      // Descuentos
      totalDiscount += ticket.getDiscountAmount;

      // Métodos de pago
      final payMode = ticket.getNamePayMode;
      paymentMethodsBreakdown[payMode] =
          (paymentMethodsBreakdown[payMode] ?? 0.0) + ticket.priceTotal;
      paymentMethodsCount[payMode] =
          (paymentMethodsCount[payMode] ?? 0) + 1;
    }

    // Métricas de flujo de caja (desde CashRegister)
    final initialCash = cashRegister.initialCash;
    final totalInflows = cashRegister.cashInFlow;
    final totalOutflows = cashRegister.cashOutFlow.abs();

    // Balance esperado: initialCash + billing + inflows - outflows
    // NOTA: cashOutFlow en CashRegister ya es negativo, por eso usamos abs()
    final expectedBalance =
        initialCash + totalBilling + totalInflows - totalOutflows;

    return CashRegisterMetrics._(
      cashRegister: cashRegister,
      tickets: tickets,
      totalBilling: totalBilling,
      totalProfit: totalProfit,
      totalDiscount: totalDiscount,
      effectiveSalesCount: effectiveSalesCount,
      annulledCount: annulledCount,
      initialCash: initialCash,
      totalInflows: totalInflows,
      totalOutflows: totalOutflows,
      expectedBalance: expectedBalance,
      paymentMethodsBreakdown: paymentMethodsBreakdown,
      paymentMethodsCount: paymentMethodsCount,
      calculatedAt: DateTime.now(),
    );
  }

  /// Constructor vacío para estado inicial
  factory CashRegisterMetrics.empty() {
    return CashRegisterMetrics._(
      cashRegister: CashRegister.initialData(),
      tickets: const [],
      totalBilling: 0.0,
      totalProfit: 0.0,
      totalDiscount: 0.0,
      effectiveSalesCount: 0,
      annulledCount: 0,
      initialCash: 0.0,
      totalInflows: 0.0,
      totalOutflows: 0.0,
      expectedBalance: 0.0,
      paymentMethodsBreakdown: const {},
      paymentMethodsCount: const {},
      calculatedAt: DateTime.now(),
    );
  }

  // ==========================================
  // GETTERS DE CONVENIENCIA
  // ==========================================

  /// Total de transacciones (efectivas + anuladas)
  int get totalTransactions => effectiveSalesCount + annulledCount;

  /// ¿Tiene ventas registradas?
  bool get hasSales => effectiveSalesCount > 0;

  /// ¿Tiene movimientos de caja (ingresos o egresos)?
  bool get hasCashMovements => totalInflows > 0 || totalOutflows > 0;

  /// Ticket promedio (facturación / ventas efectivas)
  double get averageTicket =>
      effectiveSalesCount > 0 ? totalBilling / effectiveSalesCount : 0.0;

  /// Ganancia promedio por venta
  double get averageProfitPerSale =>
      effectiveSalesCount > 0 ? totalProfit / effectiveSalesCount : 0.0;

  /// Porcentaje de margen sobre facturación
  double get profitMarginPercentage =>
      totalBilling > 0 ? (totalProfit / totalBilling) * 100 : 0.0;

  /// ¿Está la caja en estado válido para calcular métricas?
  bool get isValid => cashRegister.id.isNotEmpty;

  // ==========================================
  // EQUATABLE
  // ==========================================

  @override
  List<Object?> get props => [
        cashRegister.id,
        totalBilling,
        totalProfit,
        totalDiscount,
        effectiveSalesCount,
        annulledCount,
        initialCash,
        totalInflows,
        totalOutflows,
        expectedBalance,
        paymentMethodsBreakdown,
        paymentMethodsCount,
      ];
}
