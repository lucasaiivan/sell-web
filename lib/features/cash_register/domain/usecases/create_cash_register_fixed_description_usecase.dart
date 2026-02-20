import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/cash_register/domain/repositories/cash_register_repository.dart';

/// Crea una descripción fija para nombres de caja registradora
///
/// RESPONSABILIDAD: Crear plantilla de nombre
/// - Validar descripción no vacía
/// - Persistir en Firebase
@lazySingleton
class CreateCashRegisterFixedDescriptionUseCase
    implements UseCase<void, CreateCashRegisterFixedDescriptionParams> {
  final CashRegisterRepository _repository;

  CreateCashRegisterFixedDescriptionUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(
      CreateCashRegisterFixedDescriptionParams params) async {
    try {
      if (params.accountId.trim().isEmpty) {
        return Left(ValidationFailure('El ID de cuenta no puede estar vacío'));
      }

      if (params.description.trim().isEmpty) {
        return Left(ValidationFailure('La descripción no puede estar vacía'));
      }

      await _repository.createCashRegisterFixedDescription(
        params.accountId,
        params.description,
      );

      return Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al crear descripción fija: $e'));
    }
  }
}

class CreateCashRegisterFixedDescriptionParams {
  final String accountId;
  final String description;

  CreateCashRegisterFixedDescriptionParams({
    required this.accountId,
    required this.description,
  });
}
