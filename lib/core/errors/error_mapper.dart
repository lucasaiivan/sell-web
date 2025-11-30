import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart' as storage;
import 'exceptions.dart';
import 'failures.dart';

/// Utilidad para mapear excepciones de Firebase a [DataException] y [Failure]
///
/// **Responsabilidad:**
/// - Traducir excepciones técnicas de Firebase a excepciones de dominio
/// - Preservar información de debug (stack trace, códigos)
/// - Proveer mensajes user-friendly en español
///
/// **Uso en Repositories:**
/// ```dart
/// try {
///   await firestore.collection('users').doc(id).get();
/// } on FirebaseException catch (e, stack) {
///   throw ErrorMapper.mapFirebaseException(e, stack);
/// }
/// ```
///
/// **Complejidad:** O(1) - Mapeo directo por código de error
class ErrorMapper {
  ErrorMapper._();

  // ==========================================
  // FIREBASE EXCEPTIONS → DATA EXCEPTIONS
  // ==========================================

  /// Mapea FirebaseException genérica a DataException específica
  static DataException mapFirebaseException(
    dynamic exception,
    StackTrace stackTrace,
  ) {
    if (exception is firestore.FirebaseException) {
      return _mapFirestoreException(exception, stackTrace);
    }

    if (exception is auth.FirebaseAuthException) {
      return _mapAuthException(exception, stackTrace);
    }

    if (exception is storage.FirebaseException) {
      return _mapStorageException(exception, stackTrace);
    }

    return ServerException(
      'Error inesperado del servidor',
      code: 'unknown',
      stackTrace: stackTrace,
    );
  }

  /// Mapea errores de Firestore
  static FirestoreException _mapFirestoreException(
    firestore.FirebaseException e,
    StackTrace stack,
  ) {
    final message = switch (e.code) {
      'permission-denied' => 'No tienes permisos para realizar esta operación',
      'not-found' => 'El recurso solicitado no existe',
      'already-exists' => 'El recurso ya existe',
      'resource-exhausted' => 'Has excedido la cuota de operaciones',
      'failed-precondition' => 'Operación rechazada por el estado actual',
      'aborted' => 'Operación abortada por conflicto de concurrencia',
      'out-of-range' => 'Operación fuera de rango válido',
      'unimplemented' => 'Operación no implementada',
      'internal' => 'Error interno del servidor',
      'unavailable' => 'Servicio temporalmente no disponible',
      'data-loss' => 'Pérdida de datos detectada',
      'unauthenticated' => 'Debes iniciar sesión para continuar',
      _ => 'Error de base de datos: ${e.message}',
    };

    return FirestoreException(
      message,
      code: e.code,
      stackTrace: stack,
    );
  }

  /// Mapea errores de Firebase Auth
  static FirebaseAuthException _mapAuthException(
    auth.FirebaseAuthException e,
    StackTrace stack,
  ) {
    final message = switch (e.code) {
      'user-not-found' => 'Usuario no encontrado',
      'wrong-password' => 'Contraseña incorrecta',
      'email-already-in-use' => 'El email ya está registrado',
      'invalid-email' => 'Email inválido',
      'weak-password' => 'La contraseña es muy débil',
      'user-disabled' => 'Usuario deshabilitado',
      'operation-not-allowed' => 'Operación no permitida',
      'account-exists-with-different-credential' =>
        'Cuenta existente con diferente método de inicio',
      'invalid-credential' => 'Credenciales inválidas',
      'invalid-verification-code' => 'Código de verificación inválido',
      'invalid-verification-id' => 'ID de verificación inválido',
      'too-many-requests' => 'Demasiados intentos, intenta más tarde',
      _ => 'Error de autenticación: ${e.message}',
    };

    return FirebaseAuthException(
      message,
      code: e.code,
      stackTrace: stack,
    );
  }

  /// Mapea errores de Firebase Storage
  static FirebaseStorageException _mapStorageException(
    storage.FirebaseException e,
    StackTrace stack,
  ) {
    final message = switch (e.code) {
      'object-not-found' => 'Archivo no encontrado',
      'bucket-not-found' => 'Almacenamiento no encontrado',
      'project-not-found' => 'Proyecto no encontrado',
      'quota-exceeded' => 'Cuota de almacenamiento excedida',
      'unauthenticated' => 'Debes iniciar sesión para subir archivos',
      'unauthorized' => 'No tienes permisos para esta operación',
      'retry-limit-exceeded' => 'Demasiados intentos fallidos',
      'invalid-checksum' => 'El archivo está corrupto',
      'canceled' => 'Operación cancelada',
      _ => 'Error de almacenamiento: ${e.message}',
    };

    return FirebaseStorageException(
      message,
      code: e.code,
      stackTrace: stack,
    );
  }

  // ==========================================
  // DATA EXCEPTIONS → DOMAIN FAILURES
  // ==========================================

  /// Convierte [DataException] a [Failure] para el dominio
  ///
  /// **Uso en Repositories:**
  /// ```dart
  /// return Left(ErrorMapper.exceptionToFailure(exception));
  /// ```
  static Failure exceptionToFailure(DataException exception) {
    return switch (exception) {
      ServerException() => ServerFailure(
          exception.message,
          code: exception.code,
          stackTrace: exception.stackTrace,
        ),
      NetworkException() => NetworkFailure(
          exception.message,
          code: exception.code,
          stackTrace: exception.stackTrace,
        ),
      CacheException() => CacheFailure(
          exception.message,
          code: exception.code,
          stackTrace: exception.stackTrace,
        ),
      FirestoreException() => FirestoreFailure(
          exception.message,
          code: exception.code,
          stackTrace: exception.stackTrace,
        ),
      FirebaseAuthException() => AuthFailure(
          exception.message,
          code: exception.code,
          stackTrace: exception.stackTrace,
        ),
      FirebaseStorageException() => StorageFailure(
          exception.message,
          code: exception.code,
          stackTrace: exception.stackTrace,
        ),
    };
  }

  /// Wrapper completo: Exception raw → Failure
  ///
  /// Combina mapeo de Firebase + conversión a Failure
  ///
  /// **Uso simplificado:**
  /// ```dart
  /// try {
  ///   final result = await firestore.collection('users').get();
  ///   return Right(result);
  /// } catch (e, stack) {
  ///   return Left(ErrorMapper.handleException(e, stack));
  /// }
  /// ```
  static Failure handleException(dynamic exception, StackTrace stackTrace) {
    if (exception is DataException) {
      return exceptionToFailure(exception);
    }

    // Mapear Firebase y luego convertir
    final dataException = mapFirebaseException(exception, stackTrace);
    return exceptionToFailure(dataException);
  }
}
