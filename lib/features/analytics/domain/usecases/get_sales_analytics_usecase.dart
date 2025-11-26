import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sellweb/core/errors/failures.dart';
import '../entities/date_filter.dart';
import '../entities/sales_analytics.dart';
import '../repositories/analytics_repository.dart';

/// Parámetros para el UseCase de Analíticas
class AnalyticsParams {
  final String accountId;
  final DateFilter? dateFilter;

  const AnalyticsParams({
    required this.accountId,
    this.dateFilter,
  });
}

/// UseCase: Obtener Analíticas de Ventas
///
/// **Responsabilidad:**
/// - Obtener métricas de ventas para una cuenta específica
/// - Soportar filtrado por rango de fechas
/// - Delegar la obtención de datos al repositorio
///
/// **Dependencias:** [AnalyticsRepository]
/// **Inyección DI:** @lazySingleton
@lazySingleton
class GetSalesAnalyticsUseCase {
  final AnalyticsRepository _repository;

  GetSalesAnalyticsUseCase(this._repository);

  /// Ejecuta el caso de uso con actualización en tiempo real
  ///
  /// [params] Parámetros con accountId y filtro de fecha opcional
  /// Retorna un [Stream] que emite [SalesAnalytics] o [Failure]
  Stream<Either<Failure, SalesAnalytics>> call(AnalyticsParams params) {
    return _repository.getTransactions(
      params.accountId,
      dateFilter: params.dateFilter,
    );
  }
}
