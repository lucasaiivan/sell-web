import 'package:injectable/injectable.dart';
import '../repositories/auth_repository.dart';
import '../entities/auth_profile.dart';

/// Caso de uso: Iniciar sesión como invitado (anónimo)
///
/// **Responsabilidad:**
/// - Crea una sesión anónima en Firebase
/// - Permite acceso limitado sin cuenta real
/// - Delega la operación al repositorio
@lazySingleton
class SignInAnonymouslyUseCase {
  final AuthRepository _repository;

  SignInAnonymouslyUseCase(this._repository);

  /// Ejecuta el inicio de sesión anónimo
  ///
  /// Retorna [AuthProfile] con isAnonymous=true si es exitoso, null si falla
  Future<AuthProfile?> call() async {
    return await _repository.signInAnonymously();
  }
}
