import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cash_register_repository.dart';
import '../entities/cash_register.dart';

/// Parámetros para GetCashRegisterHistoryUseCase
class GetCashRegisterHistoryParams {
  final String accountId;

  const GetCashRegisterHistoryParams(this.accountId);
}

/// Caso de uso: Obtener historial de cajas
///
/// **Responsabilidad:**
/// - Obtiene el historial completo de cajas registradoras
/// - Delega la operación al repositorio
@lazySingleton
class GetCashRegisterHistoryUseCase extends UseCase<List<CashRegister>, GetCashRegisterHistoryParams> {
  final CashRegisterRepository _repository;

  GetCashRegisterHistoryUseCase(this._repository);

  /// Ejecuta la obtención del historial
  ///
  /// Retorna [Right(List<CashRegister>)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, List<CashRegister>>> call(GetCashRegisterHistoryParams params) async {
    try {
      final history = await _repository.getCashRegisterHistory(params.accountId);
      return Right(history);
    } catch (e) {
      return Left(ServerFailure('Error al obtener historial: ${e.toString()}'));
    }
  }
}
