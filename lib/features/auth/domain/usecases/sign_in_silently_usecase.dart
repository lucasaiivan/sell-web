import 'package:injectable/injectable.dart';
import '../repositories/auth_repository.dart';
import '../entities/auth_profile.dart';

/// Caso de uso: Iniciar sesión silenciosamente
///
/// **Responsabilidad:**
/// - Intenta iniciar sesión sin mostrar UI de Google
/// - Útil para auto-login si el usuario ya autorizó previamente
/// - Delega la operación al repositorio
@lazySingleton
class SignInSilentlyUseCase {
  final AuthRepository _repository;

  SignInSilentlyUseCase(this._repository);

  /// Ejecuta el inicio de sesión silencioso
  ///
  /// Retorna [AuthProfile] si hay una sesión guardada, null si no
  Future<AuthProfile?> call() async {
    return await _repository.signInSilently();
  }
}
