import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/cash_register/domain/repositories/cash_register_repository.dart';

/// Elimina una transacción del historial
///
/// RESPONSABILIDAD: Borrar transacción
/// - Validar IDs
/// - Eliminar de Firebase
@lazySingleton
class DeleteTransactionUseCase
    implements UseCase<void, DeleteTransactionParams> {
  final CashRegisterRepository _repository;

  DeleteTransactionUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(
      DeleteTransactionParams params) async {
    try {
      if (params.accountId.trim().isEmpty) {
        return Left(
            ValidationFailure('El ID de cuenta no puede estar vacío'));
      }

      if (params.transactionId.trim().isEmpty) {
        return Left(ValidationFailure(
            'El ID de transacción no puede estar vacío'));
      }

      await _repository.deleteTransaction(
        accountId: params.accountId,
        transactionId: params.transactionId,
      );

      return Right(null);
    } catch (e) {
      return Left(
          ServerFailure('Error al eliminar transacción: $e'));
    }
  }
}

class DeleteTransactionParams {
  final String accountId;
  final String transactionId;

  DeleteTransactionParams({
    required this.accountId,
    required this.transactionId,
  });
}
