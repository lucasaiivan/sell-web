import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';
import '../entities/auth_profile.dart';

/// Caso de uso: Iniciar sesión silenciosamente
///
/// **Responsabilidad:**
/// - Intenta iniciar sesión sin mostrar UI de Google
/// - Útil para auto-login si el usuario ya autorizó previamente
/// - Delega la operación al repositorio
@lazySingleton
class SignInSilentlyUseCase extends UseCase<AuthProfile, NoParams> {
  final AuthRepository _repository;

  SignInSilentlyUseCase(this._repository);

  /// Ejecuta el inicio de sesión silencioso
  ///
  /// Retorna [Right(AuthProfile)] si hay una sesión guardada, [Left(Failure)] si no
  @override
  Future<Either<Failure, AuthProfile>> call(NoParams params) async {
    return await _repository.signInSilently();
  }
}
