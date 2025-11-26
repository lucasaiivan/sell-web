import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/features/cash_register/domain/repositories/cash_register_repository.dart';

/// Crea o actualiza una caja registradora activa
///
/// RESPONSABILIDAD: Operación CRUD de caja activa
/// - Crear nueva caja activa
/// - Actualizar caja existente
@lazySingleton
class SetCashRegisterUseCase
    implements UseCase<void, SetCashRegisterParams> {
  final CashRegisterRepository _repository;

  SetCashRegisterUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(SetCashRegisterParams params) async {
    try {
      if (params.accountId.trim().isEmpty) {
        return Left(
            ValidationFailure('El ID de cuenta no puede estar vacío'));
      }

      if (params.cashRegister.id.trim().isEmpty) {
        return Left(ValidationFailure(
            'La caja registradora debe tener un ID válido'));
      }

      await _repository.setCashRegister(
        params.accountId,
        params.cashRegister,
      );

      return Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al establecer caja registradora: $e'));
    }
  }
}

class SetCashRegisterParams {
  final String accountId;
  final CashRegister cashRegister;

  SetCashRegisterParams({
    required this.accountId,
    required this.cashRegister,
  });
}
