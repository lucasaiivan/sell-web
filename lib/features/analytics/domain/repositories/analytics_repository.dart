import 'package:fpdart/fpdart.dart';
import 'package:sellweb/core/errors/failures.dart';
import '../entities/date_filter.dart';
import '../entities/sales_analytics.dart';

/// Repository Contract: Analíticas
///
/// **Responsabilidad:**
/// - Definir contrato para obtener métricas de ventas
/// - Abstracción para la capa de dominio
///
/// **Implementación:** [AnalyticsRepositoryImpl]
abstract class AnalyticsRepository {
  /// Obtiene las analíticas de transacciones para una cuenta
  ///
  /// [accountId] ID de la cuenta
  /// [dateFilter] Filtro de fecha opcional (null = todas las transacciones)
  /// Retorna [SalesAnalytics] con métricas calculadas o [Failure] en caso de error
  Future<Either<Failure, SalesAnalytics>> getTransactions(
    String accountId, {
    DateFilter? dateFilter,
  });
}
