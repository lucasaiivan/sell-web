import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cash_register_repository.dart';
import '../entities/cash_register.dart';

/// Parámetros para GetCashRegisterByDateRangeUseCase
class GetCashRegisterByDateRangeParams {
  final String accountId;
  final DateTime startDate;
  final DateTime endDate;

  const GetCashRegisterByDateRangeParams({
    required this.accountId,
    required this.startDate,
    required this.endDate,
  });
}

/// Caso de uso: Obtener cajas por rango de fechas
///
/// **Responsabilidad:**
/// - Obtiene arqueos de caja filtrados por rango de fechas
/// - Valida que la fecha inicial no sea posterior a la final
/// - Delega la operación al repositorio
@lazySingleton
class GetCashRegisterByDateRangeUseCase extends UseCase<List<CashRegister>, GetCashRegisterByDateRangeParams> {
  final CashRegisterRepository _repository;

  GetCashRegisterByDateRangeUseCase(this._repository);

  /// Ejecuta la obtención de cajas por rango
  ///
  /// Retorna [Right(List<CashRegister>)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, List<CashRegister>>> call(GetCashRegisterByDateRangeParams params) async {
    // Validación de negocio
    if (params.startDate.isAfter(params.endDate)) {
      return Left(ValidationFailure('La fecha inicial no puede ser posterior a la fecha final'));
    }

    try {
      final cashRegisters = await _repository.getCashRegisterByDateRange(
        accountId: params.accountId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
      return Right(cashRegisters);
    } catch (e) {
      return Left(ServerFailure('Error al obtener cajas por rango: ${e.toString()}'));
    }
  }
}
