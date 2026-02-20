import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_profile.dart';
import '../entities/account_profile.dart';

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
  /// Retorna [Right(AuthProfile)] si es exitoso, [Left(Failure)] si falla
  Future<Either<Failure, AuthProfile>> signInWithGoogle();

  /// Intenta iniciar sesión silenciosamente sin mostrar UI
  ///
  /// Útil para auto-login si el usuario ya autorizó previamente
  /// Retorna [Right(AuthProfile)] si hay sesión guardada, [Left(Failure)] si no
  Future<Either<Failure, AuthProfile>> signInSilently();

  /// Inicia sesión anónima/invitado en Firebase
  ///
  /// Permite acceso limitado sin cuenta real
  /// Retorna [Right(AuthProfile)] con isAnonymous=true si es exitoso, [Left(Failure)] si falla
  Future<Either<Failure, AuthProfile>> signInAnonymously();

  /// Cierra la sesión del usuario actual
  ///
  /// Limpia tokens y credenciales de autenticación
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  Future<Either<Failure, void>> signOut();

  /// Verifica si un username ya existe en el sistema
  ///
  /// **Parámetros:**
  /// - `username`: Username a verificar (debe estar en minúsculas)
  ///
  /// **Retorna:**
  /// - [Right(true)] si el username ya existe
  /// - [Right(false)] si el username está disponible
  /// - [Left(Failure)] si hay un error en la consulta
  Future<Either<Failure, bool>> checkUsernameExists(String username);

  /// Crea una nueva cuenta comercio
  ///
  /// **Parámetros:**
  /// - `account`: Perfil de cuenta a crear (username debe estar validado)
  ///
  /// **Retorna:**
  /// - [Right(AccountProfile)] con la cuenta creada (incluye el ID generado)
  /// - [Left(Failure)] si hay un error en la creación
  Future<Either<Failure, AccountProfile>> createBusinessAccount(
      AccountProfile account);

  /// Actualiza una cuenta comercio existente
  ///
  /// **Parámetros:**
  /// - `account`: Perfil de cuenta con los cambios a aplicar
  ///
  /// **Retorna:**
  /// - [Right(void)] si la actualización es exitosa
  /// - [Left(Failure)] si hay un error en la actualización
  Future<Either<Failure, void>> updateBusinessAccount(AccountProfile account);

  /// Elimina una cuenta de negocio y todos sus datos asociados
  ///
  /// **Acciones:**
  /// 1. Elimina recursivamente todas las subcolecciones (Catalog, Sales, etc)
  /// 2. Elimina referencias en perfiles de usuarios administradores
  /// 3. Elimina el documento principal de la cuenta
  /// 4. Elimina imágenes en Storage asociadas
  Future<Either<Failure, void>> deleteBusinessAccount(String accountId);

  /// Elimina la cuenta del usuario actual y todos sus datos
  ///
  /// **Acciones:**
  /// 1. Busca todas las cuentas de negocio propiedad del usuario
  /// 2. Ejecuta [deleteBusinessAccount] para cada una
  /// 3. Elimina el documento de perfil de usuario /USERS/{email}
  /// 4. Elimina la cuenta de autenticación de Firebase (Auth)
  Future<Either<Failure, void>> deleteUserAccount();

  /// Desvincula al usuario de la cuenta de negocio
  ///
  /// **Acciones:**
  /// 1. Elimina referencia en /USERS/{email}/ACCOUNTS/{accountId}
  /// 2. Elimina usuario en /ACCOUNTS/{accountId}/USERS/{email}
  Future<Either<Failure, void>> leaveBusinessAccount(String accountId, String email);

  /// Stream que emite el usuario autenticado actual
  ///
  /// Emite null cuando no hay usuario autenticado
  /// Permite escuchar cambios en el estado de autenticación en tiempo real
  Stream<AuthProfile?> get user;
}
