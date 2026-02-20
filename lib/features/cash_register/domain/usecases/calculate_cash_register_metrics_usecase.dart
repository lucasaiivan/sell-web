import 'package:injectable/injectable.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register_metrics.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

/// UseCase para calcular métricas de caja registradora.
///
/// **Responsabilidad:**
/// - Encapsular la lógica de cálculo de métricas
/// - Proveer un punto de entrada único para obtener [CashRegisterMetrics]
///
/// **Uso:**
/// ```dart
/// final metrics = _calculateMetricsUseCase(
///   cashRegister: activeCashRegister,
///   tickets: ticketsList,
/// );
/// ```
@lazySingleton
class CalculateCashRegisterMetricsUseCase {
  /// Calcula métricas completas desde [CashRegister] y [tickets].
  ///
  /// Retorna [CashRegisterMetrics] con todas las métricas pre-calculadas.
  CashRegisterMetrics call({
    required CashRegister cashRegister,
    required List<TicketModel> tickets,
  }) {
    return CashRegisterMetrics.calculate(
      cashRegister: cashRegister,
      tickets: tickets,
    );
  }

  /// Calcula métricas desde [CashRegister] con lista de tickets vacía.
  ///
  /// Útil cuando solo tenemos datos de caja pero no hemos cargado tickets.
  CashRegisterMetrics fromCashRegisterOnly(CashRegister cashRegister) {
    return CashRegisterMetrics.calculate(
      cashRegister: cashRegister,
      tickets: const [],
    );
  }
}
