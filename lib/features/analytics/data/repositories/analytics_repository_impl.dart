import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sellweb/core/errors/failures.dart';
import '../../domain/entities/date_filter.dart';
import '../../domain/entities/sales_analytics.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_remote_datasource.dart';

/// Repository Implementation: Analíticas
///
/// **Responsabilidad:**
/// - Implementar [AnalyticsRepository]
/// - Manejar conversión de Exceptions → Failures
/// - Coordinar acceso a datos desde datasource
///
/// **Dependencias:** [AnalyticsRemoteDataSource]
/// **Inyección DI:** @LazySingleton(as: AnalyticsRepository)
@LazySingleton(as: AnalyticsRepository)
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsRemoteDataSource _remoteDataSource;

  AnalyticsRepositoryImpl(this._remoteDataSource);

  @override
  Stream<Either<Failure, SalesAnalytics>> getTransactions(
    String accountId, {
    DateFilter? dateFilter,
  }) {
    try {
      return _remoteDataSource
          .getTransactions(
            accountId,
            dateFilter: dateFilter,
          )
          .map((analyticsModel) =>
              Right<Failure, SalesAnalytics>(analyticsModel.toEntity()))
          .handleError((error) => Left<Failure, SalesAnalytics>(ServerFailure(
              'Error al obtener analíticas: ${error.toString()}')));
    } catch (e) {
      return Stream.value(
          Left(ServerFailure('Error al obtener analíticas: ${e.toString()}')));
    }
  }
}
