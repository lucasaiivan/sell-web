import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/features/cash_register/domain/repositories/cash_register_repository.dart';

/// Obtiene los arqueos de caja de los últimos N días
///
/// RESPONSABILIDAD: Consultar historial por días
/// - Validar número de días
/// - Retornar lista de arqueos
@lazySingleton
class GetCashRegisterByDaysUseCase
    implements UseCase<List<CashRegister>, GetCashRegisterByDaysParams> {
  final CashRegisterRepository _repository;

  GetCashRegisterByDaysUseCase(this._repository);

  @override
  Future<Either<Failure, List<CashRegister>>> call(
      GetCashRegisterByDaysParams params) async {
    try {
      if (params.accountId.trim().isEmpty) {
        return Left(
            ValidationFailure('El ID de cuenta no puede estar vacío'));
      }

      if (params.days <= 0) {
        return Left(
            ValidationFailure('El número de días debe ser mayor a 0'));
      }

      final cashRegisters = await _repository.getCashRegisterByDays(
        params.accountId,
        params.days,
      );

      return Right(cashRegisters);
    } catch (e) {
      return Left(ServerFailure('Error al obtener arqueos por días: $e'));
    }
  }
}

class GetCashRegisterByDaysParams {
  final String accountId;
  final int days;

  GetCashRegisterByDaysParams({
    required this.accountId,
    required this.days,
  });
}
