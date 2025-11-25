import '../entities/auth_profile.dart';

/// Contrato del repositorio de autenticación
///
/// Define las operaciones de autenticación disponibles en el sistema.
/// Esta es una interfaz pura sin implementación.
///
/// **Responsabilidad:**
/// - Define contratos para operaciones de autenticación
/// - No contiene lógica de negocio ni implementación
/// - Es implementado por AuthRepositoryImpl en la capa de datos
///
/// **Operaciones:**
/// - `signInWithGoogle`: Inicio de sesión con Google OAuth
/// - `signInSilently`: Inicio de sesión silencioso (sin UI)
/// - `signInAnonymously`: Inicio de sesión como invitado
/// - `signOut`: Cerrar sesión
/// - `user`: Stream del usuario autenticado actual
abstract class AuthRepository {
  /// Inicia sesión con Google OAuth
  ///
  /// Retorna el perfil del usuario autenticado o null si falla
  Future<AuthProfile?> signInWithGoogle();

  /// Intenta iniciar sesión silenciosamente sin mostrar UI
  ///
  /// Útil para auto-login si el usuario ya autorizó previamente
  /// Retorna el perfil del usuario o null si no hay sesión guardada
  Future<AuthProfile?> signInSilently();

  /// Inicia sesión anónima/invitado en Firebase
  ///
  /// Permite acceso limitado sin cuenta real
  /// Retorna el perfil del usuario anónimo o null si falla
  Future<AuthProfile?> signInAnonymously();

  /// Cierra la sesión del usuario actual
  ///
  /// Limpia tokens y credenciales de autenticación
  Future<void> signOut();

  /// Stream que emite el usuario autenticado actual
  ///
  /// Emite null cuando no hay usuario autenticado
  /// Permite escuchar cambios en el estado de autenticación en tiempo real
  Stream<AuthProfile?> get user;
}
