import 'package:injectable/injectable.dart';
import '../repositories/auth_repository.dart';
import '../entities/auth_profile.dart';

/// Caso de uso: Iniciar sesión con Google OAuth
///
/// **Responsabilidad:**
/// - Coordina el inicio de sesión con Google
/// - Delega la operación al repositorio
/// - Retorna el perfil del usuario autenticado
@lazySingleton
class SignInWithGoogleUseCase {
  final AuthRepository _repository;

  SignInWithGoogleUseCase(this._repository);

  /// Ejecuta el inicio de sesión con Google
  ///
  /// Retorna [AuthProfile] si el inicio de sesión es exitoso, null si falla
  Future<AuthProfile?> call() async {
    return await _repository.signInWithGoogle();
  }
}
