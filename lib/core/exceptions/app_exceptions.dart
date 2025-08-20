/// Sistema de excepciones personalizado para la aplicación
/// Proporciona manejo centralizado de errores con contexto específico

/// Excepción base para todas las excepciones personalizadas de la app
abstract class AppException implements Exception {
  const AppException(this.message, this.code);
  
  /// Mensaje descriptivo del error
  final String message;
  
  /// Código único del error para logging/debugging
  final String code;
  
  @override
  String toString() => 'AppException($code): $message';
}

/// Excepción para errores de validación
class ValidationException extends AppException {
  const ValidationException(
    String message, {
    String code = 'VALIDATION_ERROR',
    this.field,
    this.value,
  }) : super(message, code);
  
  /// Campo que falló la validación
  final String? field;
  
  /// Valor que causó el error
  final dynamic value;
  
  @override
  String toString() => 'ValidationException($code): $message${field != null ? ' (Campo: $field)' : ''}';
}

/// Excepción para errores de red/conectividad
class NetworkException extends AppException {
  const NetworkException(
    String message, {
    String code = 'NETWORK_ERROR',
    this.statusCode,
    this.endpoint,
  }) : super(message, code);
  
  /// Código de estado HTTP (si aplica)
  final int? statusCode;
  
  /// Endpoint que falló (si aplica)
  final String? endpoint;
  
  @override
  String toString() => 'NetworkException($code): $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Excepción para errores de base de datos
class DatabaseException extends AppException {
  const DatabaseException(
    String message, {
    String code = 'DATABASE_ERROR',
    this.operation,
    this.collection,
  }) : super(message, code);
  
  /// Operación que falló (read, write, delete, etc.)
  final String? operation;
  
  /// Colección/tabla afectada
  final String? collection;
  
  @override
  String toString() => 'DatabaseException($code): $message${operation != null ? ' (Operación: $operation)' : ''}';
}

/// Excepción para errores de autenticación
class AuthException extends AppException {
  const AuthException(
    String message, {
    String code = 'AUTH_ERROR',
    this.authType,
  }) : super(message, code);
  
  /// Tipo de autenticación (email, google, etc.)
  final String? authType;
  
  @override
  String toString() => 'AuthException($code): $message${authType != null ? ' (Tipo: $authType)' : ''}';
}

/// Excepción para errores de autorización
class AuthorizationException extends AppException {
  const AuthorizationException(
    String message, {
    String code = 'AUTHORIZATION_ERROR',
    this.requiredPermission,
    this.userRole,
  }) : super(message, code);
  
  /// Permiso requerido que falta
  final String? requiredPermission;
  
  /// Rol actual del usuario
  final String? userRole;
  
  @override
  String toString() => 'AuthorizationException($code): $message';
}

/// Excepción para errores de archivo/storage
class FileException extends AppException {
  const FileException(
    String message, {
    String code = 'FILE_ERROR',
    this.filePath,
    this.operation,
  }) : super(message, code);
  
  /// Path del archivo que causó el error
  final String? filePath;
  
  /// Operación que falló (read, write, delete, upload, etc.)
  final String? operation;
  
  @override
  String toString() => 'FileException($code): $message${filePath != null ? ' (Archivo: $filePath)' : ''}';
}

/// Excepción para errores de parsing/formato
class ParseException extends AppException {
  const ParseException(
    String message, {
    String code = 'PARSE_ERROR',
    this.expectedFormat,
    this.actualValue,
  }) : super(message, code);
  
  /// Formato esperado
  final String? expectedFormat;
  
  /// Valor que se intentó parsear
  final dynamic actualValue;
  
  @override
  String toString() => 'ParseException($code): $message';
}

/// Excepción para errores de configuración
class ConfigurationException extends AppException {
  const ConfigurationException(
    String message, {
    String code = 'CONFIG_ERROR',
    this.configKey,
    this.configValue,
  }) : super(message, code);
  
  /// Clave de configuración problemática
  final String? configKey;
  
  /// Valor de configuración problemático
  final dynamic configValue;
  
  @override
  String toString() => 'ConfigurationException($code): $message';
}

/// Excepción para errores de estado/lógica de negocio
class BusinessLogicException extends AppException {
  const BusinessLogicException(
    String message, {
    String code = 'BUSINESS_LOGIC_ERROR',
    this.context,
  }) : super(message, code);
  
  /// Contexto donde ocurrió el error
  final Map<String, dynamic>? context;
  
  @override
  String toString() => 'BusinessLogicException($code): $message';
}

/// Excepción para timeouts
class TimeoutException extends AppException {
  const TimeoutException(
    String message, {
    String code = 'TIMEOUT_ERROR',
    this.timeoutDuration,
    this.operation,
  }) : super(message, code);
  
  /// Duración del timeout
  final Duration? timeoutDuration;
  
  /// Operación que hizo timeout
  final String? operation;
  
  @override
  String toString() => 'TimeoutException($code): $message${timeoutDuration != null ? ' (Timeout: ${timeoutDuration!.inSeconds}s)' : ''}';
}

/// Excepción para errores de recursos no encontrados
class NotFoundException extends AppException {
  const NotFoundException(
    String message, {
    String code = 'NOT_FOUND_ERROR',
    this.resourceType,
    this.resourceId,
  }) : super(message, code);
  
  /// Tipo de recurso no encontrado
  final String? resourceType;
  
  /// ID del recurso no encontrado
  final String? resourceId;
  
  @override
  String toString() => 'NotFoundException($code): $message${resourceType != null ? ' (Tipo: $resourceType)' : ''}';
}

/// Excepción para conflictos (ej: duplicate keys)
class ConflictException extends AppException {
  const ConflictException(
    String message, {
    String code = 'CONFLICT_ERROR',
    this.conflictingValue,
    this.existingValue,
  }) : super(message, code);
  
  /// Valor que causó el conflicto
  final dynamic conflictingValue;
  
  /// Valor existente que entra en conflicto
  final dynamic existingValue;
  
  @override
  String toString() => 'ConflictException($code): $message';
}

/// Excepción para errores de hardware/dispositivo
class DeviceException extends AppException {
  const DeviceException(
    String message, {
    String code = 'DEVICE_ERROR',
    this.deviceType,
    this.deviceId,
  }) : super(message, code);
  
  /// Tipo de dispositivo (impresora, cámara, etc.)
  final String? deviceType;
  
  /// ID o nombre del dispositivo
  final String? deviceId;
  
  @override
  String toString() => 'DeviceException($code): $message${deviceType != null ? ' (Dispositivo: $deviceType)' : ''}';
}

/// Factory para crear excepciones comunes con mensajes predefinidos
class AppExceptions {
  
  // Validación
  static ValidationException requiredField(String fieldName) => ValidationException(
    'El campo $fieldName es requerido',
    field: fieldName,
    code: 'REQUIRED_FIELD',
  );
  
  static ValidationException invalidFormat(String fieldName, String expectedFormat) => ValidationException(
    'El formato de $fieldName es inválido. Se esperaba: $expectedFormat',
    field: fieldName,
    code: 'INVALID_FORMAT',
  );
  
  static ValidationException valueOutOfRange(String fieldName, dynamic min, dynamic max) => ValidationException(
    'El valor de $fieldName debe estar entre $min y $max',
    field: fieldName,
    code: 'VALUE_OUT_OF_RANGE',
  );
  
  // Red
  static NetworkException connectionFailed() => const NetworkException(
    'No se pudo establecer conexión con el servidor',
    code: 'CONNECTION_FAILED',
  );
  
  static NetworkException timeout() => const NetworkException(
    'La operación tardó demasiado tiempo en completarse',
    code: 'NETWORK_TIMEOUT',
  );
  
  static NetworkException serverError(int statusCode) => NetworkException(
    'Error del servidor',
    statusCode: statusCode,
    code: 'SERVER_ERROR',
  );
  
  // Base de datos
  static DatabaseException documentNotFound(String collection, String id) => DatabaseException(
    'Documento no encontrado',
    operation: 'read',
    collection: collection,
    code: 'DOCUMENT_NOT_FOUND',
  );
  
  static DatabaseException permissionDenied(String operation, String collection) => DatabaseException(
    'Permisos insuficientes para la operación',
    operation: operation,
    collection: collection,
    code: 'PERMISSION_DENIED',
  );
  
  // Autenticación
  static AuthException invalidCredentials() => const AuthException(
    'Credenciales inválidas',
    code: 'INVALID_CREDENTIALS',
  );
  
  static AuthException accountDisabled() => const AuthException(
    'La cuenta está deshabilitada',
    code: 'ACCOUNT_DISABLED',
  );
  
  static AuthException tooManyRequests() => const AuthException(
    'Demasiados intentos de inicio de sesión. Intenta más tarde',
    code: 'TOO_MANY_REQUESTS',
  );
  
  // Archivo
  static FileException fileNotFound(String filePath) => FileException(
    'Archivo no encontrado',
    filePath: filePath,
    code: 'FILE_NOT_FOUND',
  );
  
  static FileException uploadFailed(String fileName) => FileException(
    'Error al subir el archivo',
    filePath: fileName,
    operation: 'upload',
    code: 'UPLOAD_FAILED',
  );
  
  static FileException fileTooLarge(String fileName, int maxSize) => FileException(
    'El archivo es demasiado grande. Tamaño máximo: ${maxSize}MB',
    filePath: fileName,
    code: 'FILE_TOO_LARGE',
  );
  
  // Lógica de negocio
  static BusinessLogicException insufficientStock(String productName, int available, int requested) => BusinessLogicException(
    'Stock insuficiente para $productName. Disponible: $available, Solicitado: $requested',
    code: 'INSUFFICIENT_STOCK',
    context: {
      'product': productName,
      'available': available,
      'requested': requested,
    },
  );
  
  static BusinessLogicException invalidOperation(String operation, String reason) => BusinessLogicException(
    'Operación $operation no válida: $reason',
    code: 'INVALID_OPERATION',
    context: {
      'operation': operation,
      'reason': reason,
    },
  );
  
  // Dispositivos
  static DeviceException printerNotConnected() => const DeviceException(
    'Impresora no conectada o no disponible',
    deviceType: 'printer',
    code: 'PRINTER_NOT_CONNECTED',
  );
  
  static DeviceException cameraPermissionDenied() => const DeviceException(
    'Permisos de cámara denegados',
    deviceType: 'camera',
    code: 'CAMERA_PERMISSION_DENIED',
  );
  
  // Genéricos
  static ConfigurationException unknownError([String? details]) => ConfigurationException(
    'Ha ocurrido un error inesperado${details != null ? ': $details' : ''}',
    code: 'UNKNOWN_ERROR',
  );
  
  static NotFoundException resourceNotFound(String resourceType, String resourceId) => NotFoundException(
    '$resourceType no encontrado',
    resourceType: resourceType,
    resourceId: resourceId,
    code: 'RESOURCE_NOT_FOUND',
  );
}
