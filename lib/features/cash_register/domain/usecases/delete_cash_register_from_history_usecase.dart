import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/features/cash_register/domain/repositories/cash_register_repository.dart';

/// Elimina un registro del historial de arqueos
///
/// RESPONSABILIDAD: Borrar arqueo del historial
/// - Validar caja
/// - Eliminar de Firebase
@lazySingleton
class DeleteCashRegisterFromHistoryUseCase
    implements UseCase<void, DeleteCashRegisterFromHistoryParams> {
  final CashRegisterRepository _repository;

  DeleteCashRegisterFromHistoryUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(
      DeleteCashRegisterFromHistoryParams params) async {
    try {
      if (params.accountId.trim().isEmpty) {
        return Left(
            ValidationFailure('El ID de cuenta no puede estar vacío'));
      }

      if (params.cashRegister.id.trim().isEmpty) {
        return Left(
            ValidationFailure('La caja debe tener un ID válido'));
      }

      await _repository.deleteCashRegisterFromHistory(
        params.accountId,
        params.cashRegister,
      );

      return Right(null);
    } catch (e) {
      return Left(
          ServerFailure('Error al eliminar caja del historial: $e'));
    }
  }
}

class DeleteCashRegisterFromHistoryParams {
  final String accountId;
  final CashRegister cashRegister;

  DeleteCashRegisterFromHistoryParams({
    required this.accountId,
    required this.cashRegister,
  });
}
