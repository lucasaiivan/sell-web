import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// UseCase: Salir de una cuenta de negocio
///
/// **Acciones:**
/// - Permite a un usuario (admin/empleado) desvincularse de un negocio
/// - No elimina el negocio ni sus datos
/// - Solo elimina la referencia en su perfil y en la lista de usuarios del negocio
@injectable
class LeaveBusinessAccountUseCase {
  final AuthRepository _repository;

  LeaveBusinessAccountUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String accountId,
    required String email,
  }) async {
    if (accountId.trim().isEmpty) {
      return Left(ValidationFailure('ID de cuenta inválido'));
    }
    if (email.trim().isEmpty) {
      return Left(ValidationFailure('Email inválido'));
    }
    return await _repository.leaveBusinessAccount(accountId, email);
  }
}
