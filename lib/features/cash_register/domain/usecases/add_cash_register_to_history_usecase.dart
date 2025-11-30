import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/features/cash_register/domain/repositories/cash_register_repository.dart';

/// Agrega un registro de arqueo al historial (cuando se cierra una caja)
///
/// RESPONSABILIDAD: Persistir arqueo en historial
/// - Validar caja
/// - Agregar a historial de Firebase
@lazySingleton
class AddCashRegisterToHistoryUseCase
    implements UseCase<void, AddCashRegisterToHistoryParams> {
  final CashRegisterRepository _repository;

  AddCashRegisterToHistoryUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(
      AddCashRegisterToHistoryParams params) async {
    try {
      if (params.accountId.trim().isEmpty) {
        return Left(ValidationFailure('El ID de cuenta no puede estar vacío'));
      }

      if (params.cashRegister.id.trim().isEmpty) {
        return Left(ValidationFailure('La caja debe tener un ID válido'));
      }

      await _repository.addCashRegisterToHistory(
        params.accountId,
        params.cashRegister,
      );

      return Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al agregar caja al historial: $e'));
    }
  }
}

class AddCashRegisterToHistoryParams {
  final String accountId;
  final CashRegister cashRegister;

  AddCashRegisterToHistoryParams({
    required this.accountId,
    required this.cashRegister,
  });
}
