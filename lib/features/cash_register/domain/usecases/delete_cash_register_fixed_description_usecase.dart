import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/cash_register/domain/repositories/cash_register_repository.dart';

/// Elimina una descripción fija para nombres de caja registradora
///
/// RESPONSABILIDAD: Borrar plantilla de nombre
/// - Validar IDs
/// - Eliminar de Firebase
@lazySingleton
class DeleteCashRegisterFixedDescriptionUseCase
    implements UseCase<void, DeleteCashRegisterFixedDescriptionParams> {
  final CashRegisterRepository _repository;

  DeleteCashRegisterFixedDescriptionUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(
      DeleteCashRegisterFixedDescriptionParams params) async {
    try {
      if (params.accountId.trim().isEmpty) {
        return Left(
            ValidationFailure('El ID de cuenta no puede estar vacío'));
      }

      if (params.descriptionId.trim().isEmpty) {
        return Left(ValidationFailure(
            'El ID de descripción no puede estar vacío'));
      }

      await _repository.deleteCashRegisterFixedDescription(
        params.accountId,
        params.descriptionId,
      );

      return Right(null);
    } catch (e) {
      return Left(ServerFailure(
          'Error al eliminar descripción fija: $e'));
    }
  }
}

class DeleteCashRegisterFixedDescriptionParams {
  final String accountId;
  final String descriptionId;

  DeleteCashRegisterFixedDescriptionParams({
    required this.accountId,
    required this.descriptionId,
  });
}
