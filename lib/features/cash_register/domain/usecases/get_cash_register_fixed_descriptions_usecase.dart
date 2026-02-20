import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/cash_register/domain/repositories/cash_register_repository.dart';

/// Obtiene las descripciones fijas para nombres de caja registradora
///
/// RESPONSABILIDAD: Consultar plantillas de nombres
/// - Validar accountId
/// - Retornar lista de descripciones
@lazySingleton
class GetCashRegisterFixedDescriptionsUseCase
    implements
        UseCase<List<Map<String, dynamic>>,
            GetCashRegisterFixedDescriptionsParams> {
  final CashRegisterRepository _repository;

  GetCashRegisterFixedDescriptionsUseCase(this._repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(
      GetCashRegisterFixedDescriptionsParams params) async {
    try {
      if (params.accountId.trim().isEmpty) {
        return Left(ValidationFailure('El ID de cuenta no puede estar vacío'));
      }

      final descriptions = await _repository.getCashRegisterFixedDescriptions(
        params.accountId,
      );

      return Right(descriptions);
    } catch (e) {
      return Left(ServerFailure('Error al obtener descripciones fijas: $e'));
    }
  }
}

class GetCashRegisterFixedDescriptionsParams {
  final String accountId;

  GetCashRegisterFixedDescriptionsParams({
    required this.accountId,
  });
}
