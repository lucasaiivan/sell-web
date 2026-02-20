import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// UseCase: Eliminar cuenta de usuario
///
/// **Acciones:**
/// - Elimina usuario, sus cuentas asociadas (si es dueño) y datos
@injectable
class DeleteUserAccountUseCase {
  final AuthRepository _repository;

  DeleteUserAccountUseCase(this._repository);

  Future<Either<Failure, void>> call() async {
    return await _repository.deleteUserAccount();
  }
}
