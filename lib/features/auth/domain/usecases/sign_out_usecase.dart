import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: Cerrar sesión
///
/// **Responsabilidad:**
/// - Cierra la sesión del usuario actual
/// - Limpia tokens y credenciales de autenticación
/// - Delega la operación al repositorio
@lazySingleton
class SignOutUseCase extends UseCase<void, NoParams> {
  final AuthRepository _repository;

  SignOutUseCase(this._repository);

  /// Ejecuta el cierre de sesión
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await _repository.signOut();
  }
}
