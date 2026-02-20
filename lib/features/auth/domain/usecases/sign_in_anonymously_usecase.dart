import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';
import '../entities/auth_profile.dart';

/// Caso de uso: Iniciar sesión como invitado (anónimo)
///
/// **Responsabilidad:**
/// - Crea una sesión anónima en Firebase
/// - Permite acceso limitado sin cuenta real
/// - Delega la operación al repositorio
@lazySingleton
class SignInAnonymouslyUseCase extends UseCase<AuthProfile, NoParams> {
  final AuthRepository _repository;

  SignInAnonymouslyUseCase(this._repository);

  /// Ejecuta el inicio de sesión anónimo
  ///
  /// Retorna [Right(AuthProfile)] con isAnonymous=true si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, AuthProfile>> call(NoParams params) async {
    return await _repository.signInAnonymously();
  }
}
