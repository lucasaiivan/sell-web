import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';
import '../entities/auth_profile.dart';

/// Caso de uso: Iniciar sesión con Google OAuth
///
/// **Responsabilidad:**
/// - Coordina el inicio de sesión con Google
/// - Delega la operación al repositorio
/// - Retorna el perfil del usuario autenticado
@lazySingleton
class SignInWithGoogleUseCase extends UseCase<AuthProfile, NoParams> {
  final AuthRepository _repository;

  SignInWithGoogleUseCase(this._repository);

  /// Ejecuta el inicio de sesión con Google
  ///
  /// Retorna [Right(AuthProfile)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, AuthProfile>> call(NoParams params) async {
    return await _repository.signInWithGoogle();
  }
}
