import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/cash_register/domain/repositories/cash_register_repository.dart';

/// Elimina una caja registradora activa
///
/// RESPONSABILIDAD: Eliminar caja de lista de activas
/// - Validar IDs
/// - Eliminar de Firebase
@lazySingleton
class DeleteCashRegisterUseCase
    implements UseCase<void, DeleteCashRegisterParams> {
  final CashRegisterRepository _repository;

  DeleteCashRegisterUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(
      DeleteCashRegisterParams params) async {
    try {
      if (params.accountId.trim().isEmpty) {
        return Left(
            ValidationFailure('El ID de cuenta no puede estar vacío'));
      }

      if (params.cashRegisterId.trim().isEmpty) {
        return Left(
            ValidationFailure('El ID de caja no puede estar vacío'));
      }

      await _repository.deleteCashRegister(
        params.accountId,
        params.cashRegisterId,
      );

      return Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al eliminar caja registradora: $e'));
    }
  }
}

class DeleteCashRegisterParams {
  final String accountId;
  final String cashRegisterId;

  DeleteCashRegisterParams({
    required this.accountId,
    required this.cashRegisterId,
  });
}
