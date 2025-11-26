import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cash_register_repository.dart';

/// Parámetros para GetTransactionsByDateRangeUseCase
class GetTransactionsByDateRangeParams {
  final String accountId;
  final DateTime startDate;
  final DateTime endDate;

  const GetTransactionsByDateRangeParams({
    required this.accountId,
    required this.startDate,
    required this.endDate,
  });
}

/// Caso de uso: Obtener transacciones por rango de fechas
///
/// **Responsabilidad:**
/// - Obtiene transacciones filtradas por rango de fechas
/// - Valida que la fecha inicial no sea posterior a la final
/// - Delega la operación al repositorio
@lazySingleton
class GetTransactionsByDateRangeUseCase extends UseCase<List<Map<String, dynamic>>, GetTransactionsByDateRangeParams> {
  final CashRegisterRepository _repository;

  GetTransactionsByDateRangeUseCase(this._repository);

  /// Ejecuta la obtención de transacciones
  ///
  /// Retorna [Right(List<Map<String, dynamic>>)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(GetTransactionsByDateRangeParams params) async {
    // Validación de negocio
    if (params.startDate.isAfter(params.endDate)) {
      return Left(ValidationFailure('La fecha inicial no puede ser posterior a la fecha final'));
    }

    try {
      final transactions = await _repository.getTransactionsByDateRange(
        accountId: params.accountId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
      return Right(transactions);
    } catch (e) {
      return Left(ServerFailure('Error al obtener transacciones: ${e.toString()}'));
    }
  }
}
