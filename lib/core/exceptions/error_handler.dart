/// Manejador centralizado de errores para la aplicación
/// Proporciona logging, notificación y manejo de excepciones

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_exceptions.dart';

/// Severidad del error para logging y manejo
enum ErrorSeverity {
  /// Errores informativos que no afectan la funcionalidad
  info,

  /// Advertencias que pueden requerir atención
  warning,

  /// Errores que afectan funcionalidad pero son recuperables
  error,

  /// Errores críticos que pueden causar crashes
  critical,

  /// Errores fatales que requieren reinicio de la app
  fatal,
}

/// Contexto adicional para el error
class ErrorContext {
  const ErrorContext({
    this.userId,
    this.sessionId,
    this.screen,
    this.action,
    this.metadata,
    this.stackTrace,
  });

  /// ID del usuario cuando ocurrió el error
  final String? userId;

  /// ID de la sesión actual
  final String? sessionId;

  /// Pantalla donde ocurrió el error
  final String? screen;

  /// Acción que se estaba ejecutando
  final String? action;

  /// Metadatos adicionales
  final Map<String, dynamic>? metadata;

  /// Stack trace del error
  final StackTrace? stackTrace;

  Map<String, dynamic> toMap() => {
        if (userId != null) 'userId': userId,
        if (sessionId != null) 'sessionId': sessionId,
        if (screen != null) 'screen': screen,
        if (action != null) 'action': action,
        if (metadata != null) 'metadata': metadata,
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      };
}

/// Resultado del manejo de error
class ErrorHandlingResult {
  const ErrorHandlingResult({
    required this.handled,
    this.userMessage,
    this.shouldRetry,
    this.retryDelay,
    this.shouldShowDialog,
    this.shouldLogout,
    this.shouldRestart,
  });

  /// Si el error fue manejado correctamente
  final bool handled;

  /// Mensaje para mostrar al usuario
  final String? userMessage;

  /// Si se debe permitir reintentar la operación
  final bool? shouldRetry;

  /// Delay antes de permitir retry
  final Duration? retryDelay;

  /// Si se debe mostrar un diálogo de error
  final bool? shouldShowDialog;

  /// Si se debe cerrar la sesión del usuario
  final bool? shouldLogout;

  /// Si se debe reiniciar la aplicación
  final bool? shouldRestart;
}

/// Callback para logging personalizado
typedef ErrorLogger = void Function(
  Object error,
  StackTrace? stackTrace,
  ErrorSeverity severity,
  ErrorContext? context,
);

/// Callback para notificaciones al usuario
typedef ErrorNotifier = void Function(String message, ErrorSeverity severity,
    {bool showDialog, Duration? duration});

/// Manejador centralizado de errores
class ErrorHandler {
  ErrorHandler._({
    this.logger,
    this.notifier,
    this.enableDebugLogging = kDebugMode,
  });

  static ErrorHandler? _instance;
  static ErrorHandler get instance => _instance ?? _defaultInstance;

  static final ErrorHandler _defaultInstance = ErrorHandler._();

  /// Inicializa el manejador de errores con configuración personalizada
  static void initialize({
    ErrorLogger? logger,
    ErrorNotifier? notifier,
    bool enableDebugLogging = kDebugMode,
  }) {
    _instance = ErrorHandler._(
      logger: logger,
      notifier: notifier,
      enableDebugLogging: enableDebugLogging,
    );
  }

  final ErrorLogger? logger;
  final ErrorNotifier? notifier;
  final bool enableDebugLogging;

  /// Maneja un error de forma centralizada
  ErrorHandlingResult handleError(
    Object error, {
    StackTrace? stackTrace,
    ErrorContext? context,
    ErrorSeverity? severity,
  }) {
    final determinedSeverity = severity ?? _determineSeverity(error);

    // Log del error
    _logError(error, stackTrace, determinedSeverity, context);

    // Determinar estrategia de manejo
    final result =
        _determineHandlingStrategy(error, determinedSeverity, context);

    // Notificar al usuario si es necesario
    if (result.userMessage != null) {
      _notifyUser(result.userMessage!, determinedSeverity,
          result.shouldShowDialog ?? false);
    }

    return result;
  }

  /// Maneja errores específicos de Flutter/Dart
  ErrorHandlingResult handleFlutterError(FlutterErrorDetails details) {
    return handleError(
      details.exception,
      stackTrace: details.stack,
      context: ErrorContext(
        screen: details.context?.toString(),
        metadata: {
          'library': details.library,
          'silent': details.silent,
        },
      ),
    );
  }

  /// Maneja errores de platform (iOS/Android)
  ErrorHandlingResult handlePlatformError(PlatformException error) {
    final appError = _convertPlatformException(error);
    return handleError(
      appError,
      context: ErrorContext(
        metadata: {
          'platform_code': error.code,
          'platform_message': error.message,
          'platform_details': error.details,
        },
      ),
    );
  }

  /// Determina la severidad basada en el tipo de error
  ErrorSeverity _determineSeverity(Object error) {
    if (error is AppException) {
      switch (error.runtimeType) {
        case ValidationException:
          return ErrorSeverity.warning;
        case NetworkException:
        case TimeoutException:
          return ErrorSeverity.error;
        case AuthException:
        case AuthorizationException:
          return ErrorSeverity.error;
        case DatabaseException:
          return ErrorSeverity.critical;
        case BusinessLogicException:
          return ErrorSeverity.error;
        case DeviceException:
          return ErrorSeverity.warning;
        case FileException:
          return ErrorSeverity.warning;
        case ParseException:
          return ErrorSeverity.warning;
        case ConfigurationException:
          return ErrorSeverity.critical;
        case NotFoundException:
          return ErrorSeverity.warning;
        case ConflictException:
          return ErrorSeverity.error;
        default:
          return ErrorSeverity.error;
      }
    }

    if (error is OutOfMemoryError || error is StackOverflowError) {
      return ErrorSeverity.fatal;
    }

    if (error is StateError || error is ArgumentError) {
      return ErrorSeverity.critical;
    }

    if (error is FormatException || error is TypeError) {
      return ErrorSeverity.error;
    }

    return ErrorSeverity.error;
  }

  /// Determina la estrategia de manejo para el error
  ErrorHandlingResult _determineHandlingStrategy(
    Object error,
    ErrorSeverity severity,
    ErrorContext? context,
  ) {
    if (error is AppException) {
      return _handleAppException(error, severity, context);
    }

    // Manejo por severidad para errores no AppException
    switch (severity) {
      case ErrorSeverity.info:
        return const ErrorHandlingResult(handled: true);

      case ErrorSeverity.warning:
        return ErrorHandlingResult(
          handled: true,
          userMessage: _getGenericMessage(error),
          shouldShowDialog: false,
        );

      case ErrorSeverity.error:
        return ErrorHandlingResult(
          handled: true,
          userMessage: _getGenericMessage(error),
          shouldShowDialog: true,
          shouldRetry: true,
          retryDelay: const Duration(seconds: 2),
        );

      case ErrorSeverity.critical:
        return ErrorHandlingResult(
          handled: true,
          userMessage:
              'Ha ocurrido un error crítico. La aplicación se reiniciará.',
          shouldShowDialog: true,
          shouldRestart: true,
        );

      case ErrorSeverity.fatal:
        return ErrorHandlingResult(
          handled: true,
          userMessage: 'Error fatal. La aplicación debe reiniciarse.',
          shouldShowDialog: true,
          shouldRestart: true,
        );
    }
  }

  /// Manejo específico para AppException
  ErrorHandlingResult _handleAppException(
    AppException error,
    ErrorSeverity severity,
    ErrorContext? context,
  ) {
    switch (error.runtimeType) {
      case ValidationException:
        return ErrorHandlingResult(
          handled: true,
          userMessage: error.message,
          shouldShowDialog: false,
        );

      case NetworkException:
        return ErrorHandlingResult(
          handled: true,
          userMessage: error.message,
          shouldShowDialog: true,
          shouldRetry: true,
          retryDelay: const Duration(seconds: 5),
        );

      case AuthException:
        return ErrorHandlingResult(
          handled: true,
          userMessage: error.message,
          shouldShowDialog: true,
          shouldLogout: error.code == 'INVALID_CREDENTIALS' ||
              error.code == 'ACCOUNT_DISABLED',
        );

      case AuthorizationException:
        return ErrorHandlingResult(
          handled: true,
          userMessage: 'No tienes permisos suficientes para esta acción.',
          shouldShowDialog: true,
        );

      case BusinessLogicException:
        return ErrorHandlingResult(
          handled: true,
          userMessage: error.message,
          shouldShowDialog: true,
        );

      case NotFoundException:
        return ErrorHandlingResult(
          handled: true,
          userMessage: error.message,
          shouldShowDialog: false,
        );

      default:
        return ErrorHandlingResult(
          handled: true,
          userMessage: error.message,
          shouldShowDialog: true,
        );
    }
  }

  /// Convierte PlatformException a AppException
  AppException _convertPlatformException(PlatformException error) {
    switch (error.code) {
      case 'network_error':
        return const NetworkException('Error de conectividad');
      case 'permission_denied':
        return const AuthorizationException('Permisos denegados');
      case 'file_not_found':
        return FileException('Archivo no encontrado',
            filePath: error.details?.toString());
      default:
        return ConfigurationException(error.message ?? 'Error de plataforma',
            code: error.code);
    }
  }

  /// Obtiene mensaje genérico para errores no AppException
  String _getGenericMessage(Object error) {
    if (error is StateError) {
      return 'Error de estado interno de la aplicación';
    }
    if (error is ArgumentError) {
      return 'Error en los parámetros de la operación';
    }
    if (error is FormatException) {
      return 'Error de formato en los datos';
    }
    if (error is TypeError) {
      return 'Error de tipo de datos';
    }

    return 'Ha ocurrido un error inesperado';
  }

  /// Log del error
  void _logError(
    Object error,
    StackTrace? stackTrace,
    ErrorSeverity severity,
    ErrorContext? context,
  ) {
    if (logger != null) {
      logger!(error, stackTrace, severity, context);
    } else if (enableDebugLogging) {
      final prefix = '[ERROR ${severity.name.toUpperCase()}]';
      debugPrint('$prefix $error');
      if (stackTrace != null && severity.index >= ErrorSeverity.error.index) {
        debugPrint('StackTrace: $stackTrace');
      }
      if (context != null) {
        debugPrint('Context: ${context.toMap()}');
      }
    }
  }

  /// Notifica al usuario
  void _notifyUser(String message, ErrorSeverity severity, bool showDialog) {
    if (notifier != null) {
      notifier!(message, severity, showDialog: showDialog);
    } else if (enableDebugLogging) {
      debugPrint('[USER NOTIFICATION] $message');
    }
  }
}

/// Extensión para manejo fácil de errores en funciones async
extension ErrorHandlerExtension on Future {
  /// Maneja errores automáticamente usando ErrorHandler
  Future<T> handleErrors<T>({
    ErrorContext? context,
    ErrorSeverity? severity,
  }) async {
    try {
      return await this as T;
    } catch (error, stackTrace) {
      final result = ErrorHandler.instance.handleError(
        error,
        stackTrace: stackTrace,
        context: context,
        severity: severity,
      );

      if (!result.handled) {
        rethrow;
      }

      throw error; // Re-lanza para que el llamador pueda manejar
    }
  }
}

/// Widget wrapper para manejo de errores en UI
/// Se puede usar para envolver widgets que pueden generar errores
class ErrorBoundary {
  /// Maneja errores en builders de widgets
  static Widget Function(BuildContext, Widget?) wrapBuilder(
    Widget Function(BuildContext) builder, {
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
    ErrorContext? errorContext,
  }) {
    return (context, child) {
      try {
        return builder(context);
      } catch (error, stackTrace) {
        ErrorHandler.instance.handleError(
          error,
          stackTrace: stackTrace,
          context: errorContext,
        );

        if (errorBuilder != null) {
          return errorBuilder(context, error, stackTrace);
        }

        return const SizedBox.shrink();
      }
    };
  }
}
