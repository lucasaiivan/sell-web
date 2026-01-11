import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// UseCase: Eliminar cuenta de negocio
///
/// **Acciones:**
/// - Valida que el ID no sea vacío
/// - Delega la eliminación profunda al repositorio
@injectable
class DeleteBusinessAccountUseCase {
  final AuthRepository _repository;

  DeleteBusinessAccountUseCase(this._repository);

  Future<Either<Failure, void>> call(String accountId) async {
    if (accountId.trim().isEmpty) {
      return Left(ValidationFailure('ID de cuenta inválido'));
    }
    return await _repository.deleteBusinessAccount(accountId);
  }
}
