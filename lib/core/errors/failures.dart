import 'package:equatable/equatable.dart';

/// Clase base sealed para todos los fallos de dominio
///
/// **Patrón:** Sealed Class (Dart 3.x) para garantizar exhaustividad en pattern matching
/// **Beneficio:** El compilador fuerza manejar todos los casos en switch/when
///
/// Usa [sealed] para que el compilador detecte casos no manejados:
/// ```dart
/// switch (failure) {
///   case ServerFailure(): handleServerError();
///   case NetworkFailure(): handleNetworkError();
///   // Si falta un caso, error de compilación
/// }
/// ```
sealed class Failure extends Equatable {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const Failure(
    this.message, {
    this.code,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, code];
}

// ==========================================
// INFRASTRUCTURE FAILURES
// ==========================================

/// Fallo de servidor/backend
final class ServerFailure extends Failure {
  const ServerFailure(
    super.message, {
    super.code = 'server-error',
    super.stackTrace,
  });
}

/// Fallo de caché local
final class CacheFailure extends Failure {
  const CacheFailure(
    super.message, {
    super.code = 'cache-error',
    super.stackTrace,
  });
}

/// Fallo de conexión a red
final class NetworkFailure extends Failure {
  const NetworkFailure(
    super.message, {
    super.code = 'network-error',
    super.stackTrace,
  });
}

// ==========================================
// FIREBASE-SPECIFIC FAILURES
// ==========================================

/// Fallo de Firestore (lectura/escritura)
final class FirestoreFailure extends Failure {
  const FirestoreFailure(
    super.message, {
    super.code = 'firestore-error',
    super.stackTrace,
  });
}

/// Fallo de autenticación Firebase
final class AuthFailure extends Failure {
  const AuthFailure(
    super.message, {
    super.code = 'auth-error',
    super.stackTrace,
  });
}

/// Fallo de Firebase Storage
final class StorageFailure extends Failure {
  const StorageFailure(
    super.message, {
    super.code = 'storage-error',
    super.stackTrace,
  });
}

// ==========================================
// DOMAIN FAILURES
// ==========================================

/// Fallo de validación de datos
final class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure(
    super.message, {
    this.fieldErrors,
    super.code = 'validation-error',
    super.stackTrace,
  });

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

/// Fallo de permisos (usuario no autorizado)
final class PermissionFailure extends Failure {
  const PermissionFailure(
    super.message, {
    super.code = 'permission-denied',
    super.stackTrace,
  });
}

/// Fallo de recurso no encontrado
final class NotFoundFailure extends Failure {
  const NotFoundFailure(
    super.message, {
    super.code = 'not-found',
    super.stackTrace,
  });
}

/// Fallo desconocido/inesperado
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(
    super.message, {
    super.code = 'unexpected-error',
    super.stackTrace,
  });
}
