import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cash_register_repository.dart';
import '../entities/cash_register.dart';

/// Parámetros para GetTodayCashRegistersUseCase
class GetTodayCashRegistersParams {
  final String accountId;

  const GetTodayCashRegistersParams(this.accountId);
}

/// Caso de uso: Obtener cajas del día actual
///
/// **Responsabilidad:**
/// - Obtiene los arqueos de caja del día actual
/// - Delega la operación al repositorio
@lazySingleton
class GetTodayCashRegistersUseCase extends UseCase<List<CashRegister>, GetTodayCashRegistersParams> {
  final CashRegisterRepository _repository;

  GetTodayCashRegistersUseCase(this._repository);

  /// Ejecuta la obtención de cajas del día
  ///
  /// Retorna [Right(List<CashRegister>)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, List<CashRegister>>> call(GetTodayCashRegistersParams params) async {
    try {
      final cashRegisters = await _repository.getTodayCashRegisters(params.accountId);
      return Right(cashRegisters);
    } catch (e) {
      return Left(ServerFailure('Error al obtener cajas del día: ${e.toString()}'));
    }
  }
}
