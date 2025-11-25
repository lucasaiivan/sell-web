import 'package:injectable/injectable.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: Cerrar sesión
///
/// **Responsabilidad:**
/// - Cierra la sesión del usuario actual
/// - Limpia tokens y credenciales de autenticación
/// - Delega la operación al repositorio
@lazySingleton
class SignOutUseCase {
  final AuthRepository _repository;

  SignOutUseCase(this._repository);

  /// Ejecuta el cierre de sesión
  Future<void> call() async {
    await _repository.signOut();
  }
}
