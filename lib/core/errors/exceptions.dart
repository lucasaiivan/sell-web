/// Excepción base sealed para la capa de datos
/// 
/// **Patrón:** Todas las excepciones de infraestructura heredan de aquí
/// **Mapeo:** DataSource lanza estas → Repository las convierte a [Failure]
sealed class DataException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const DataException(
    this.message, {
    this.code,
    this.stackTrace,
  });

  @override
  String toString() => 'DataException: $message (code: $code)';
}

// ==========================================
// INFRASTRUCTURE EXCEPTIONS
// ==========================================

/// Excepción de servidor/backend
final class ServerException extends DataException {
  const ServerException(
    super.message, {
    super.code = 'server-error',
    super.stackTrace,
  });
}

/// Excepción de caché local
final class CacheException extends DataException {
  const CacheException(
    super.message, {
    super.code = 'cache-error',
    super.stackTrace,
  });
}

/// Excepción de red/conectividad
final class NetworkException extends DataException {
  const NetworkException(
    super.message, {
    super.code = 'network-error',
    super.stackTrace,
  });
}

// ==========================================
// FIREBASE EXCEPTIONS
// ==========================================

/// Excepción de Firestore
final class FirestoreException extends DataException {
  const FirestoreException(
    super.message, {
    super.code = 'firestore-error',
    super.stackTrace,
  });
}

/// Excepción de autenticación Firebase
final class FirebaseAuthException extends DataException {
  const FirebaseAuthException(
    super.message, {
    super.code = 'auth-error',
    super.stackTrace,
  });
}

/// Excepción de Firebase Storage
final class FirebaseStorageException extends DataException {
  const FirebaseStorageException(
    super.message, {
    super.code = 'storage-error',
    super.stackTrace,
  });
}
