/// Sistema de logging para errores y eventos de la aplicación
/// Proporciona logging local y remoto con diferentes niveles

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'error_handler.dart';

/// Niveles de logging
enum LogLevel {
  /// Información de debugging (solo en debug mode)
  debug,

  /// Información general
  info,

  /// Advertencias
  warning,

  /// Errores
  error,

  /// Errores críticos
  critical,
}

/// Entrada de log
class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
    this.metadata,
  });

  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? tag;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'message': message,
        if (tag != null) 'tag': tag,
        if (error != null) 'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
        if (metadata != null) 'metadata': metadata,
      };

  @override
  String toString() {
    final tagStr = tag != null ? '[$tag] ' : '';
    final errorStr = error != null ? ' - Error: $error' : '';
    return '${timestamp.toIso8601String()} [${level.name.toUpperCase()}] $tagStr$message$errorStr';
  }
}

/// Destino de logging
abstract class LogDestination {
  Future<void> log(LogEntry entry);
  Future<void> flush();
  Future<void> close();
}

/// Logger a consola/debug
class ConsoleLogDestination implements LogDestination {
  const ConsoleLogDestination({
    this.enableInRelease = false,
  });

  final bool enableInRelease;

  @override
  Future<void> log(LogEntry entry) async {
    if (kDebugMode || enableInRelease) {
      debugPrint(entry.toString());
      if (entry.stackTrace != null &&
          entry.level.index >= LogLevel.error.index) {
        debugPrint('StackTrace: ${entry.stackTrace}');
      }
    }
  }

  @override
  Future<void> flush() async {}

  @override
  Future<void> close() async {}
}

/// Logger a archivo local
class FileLogDestination implements LogDestination {
  FileLogDestination({
    this.maxFileSizeBytes = 1024 * 1024 * 5, // 5MB
    this.maxFiles = 5,
    this.fileName = 'app_logs.txt',
  });

  final int maxFileSizeBytes;
  final int maxFiles;
  final String fileName;

  File? _logFile;
  final List<LogEntry> _buffer = [];
  bool _isInitialized = false;

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      _logFile = File('${logsDir.path}/$fileName');
      _isInitialized = true;

      // Rotación de archivos si es necesario
      await _rotateLogsIfNeeded();
    } catch (e) {
      debugPrint('Error initializing file logging: $e');
    }
  }

  @override
  Future<void> log(LogEntry entry) async {
    await _initialize();

    _buffer.add(entry);

    // Flush automático cada 10 entradas o si es un error crítico
    if (_buffer.length >= 10 || entry.level.index >= LogLevel.error.index) {
      await flush();
    }
  }

  @override
  Future<void> flush() async {
    if (_buffer.isEmpty || _logFile == null) return;

    try {
      final logLines = _buffer.map((entry) => entry.toString()).join('\n');
      await _logFile!.writeAsString('$logLines\n', mode: FileMode.append);
      _buffer.clear();

      await _rotateLogsIfNeeded();
    } catch (e) {
      debugPrint('Error writing to log file: $e');
    }
  }

  @override
  Future<void> close() async {
    await flush();
  }

  Future<void> _rotateLogsIfNeeded() async {
    if (_logFile == null || !await _logFile!.exists()) return;

    final stat = await _logFile!.stat();
    if (stat.size < maxFileSizeBytes) return;

    try {
      final directory = _logFile!.parent;

      // Rotar archivos existentes
      for (int i = maxFiles - 1; i > 0; i--) {
        final oldFile = File('${directory.path}/${fileName}_$i');
        final newFile = File('${directory.path}/${fileName}_${i + 1}');

        if (await oldFile.exists()) {
          if (i == maxFiles - 1) {
            await oldFile.delete(); // Eliminar el más antiguo
          } else {
            await oldFile.rename(newFile.path);
          }
        }
      }

      // Mover el archivo actual
      await _logFile!.rename('${directory.path}/${fileName}_1');

      // Crear nuevo archivo
      _logFile = File('${directory.path}/$fileName');
    } catch (e) {
      debugPrint('Error rotating log files: $e');
    }
  }

  /// Obtiene los logs del archivo actual
  Future<List<String>> getLogs() async {
    await _initialize();

    if (_logFile == null || !await _logFile!.exists()) {
      return [];
    }

    try {
      final content = await _logFile!.readAsString();
      return content.split('\n').where((line) => line.isNotEmpty).toList();
    } catch (e) {
      debugPrint('Error reading log file: $e');
      return [];
    }
  }
}

/// Logger en memoria (para debugging o tests)
class MemoryLogDestination implements LogDestination {
  MemoryLogDestination({
    this.maxEntries = 1000,
  });

  final int maxEntries;
  final List<LogEntry> _entries = [];

  List<LogEntry> get entries => List.unmodifiable(_entries);

  @override
  Future<void> log(LogEntry entry) async {
    _entries.add(entry);

    // Mantener solo las últimas entradas
    if (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
  }

  @override
  Future<void> flush() async {}

  @override
  Future<void> close() async {
    _entries.clear();
  }

  /// Obtiene entradas filtradas por nivel
  List<LogEntry> getEntriesByLevel(LogLevel level) {
    return _entries.where((entry) => entry.level == level).toList();
  }

  /// Obtiene entradas por tag
  List<LogEntry> getEntriesByTag(String tag) {
    return _entries.where((entry) => entry.tag == tag).toList();
  }
}

/// Logger principal de la aplicación
class AppLogger {
  AppLogger._({
    this.destinations = const [],
    this.minLevel = LogLevel.debug,
  });

  static AppLogger? _instance;
  static AppLogger get instance => _instance ?? _defaultInstance;

  static final AppLogger _defaultInstance = AppLogger._(
    destinations: [
      const ConsoleLogDestination(),
    ],
  );

  /// Inicializa el logger con configuración personalizada
  static void initialize({
    List<LogDestination> destinations = const [],
    LogLevel minLevel = LogLevel.debug,
  }) {
    _instance = AppLogger._(
      destinations:
          destinations.isEmpty ? [const ConsoleLogDestination()] : destinations,
      minLevel: minLevel,
    );
  }

  final List<LogDestination> destinations;
  final LogLevel minLevel;

  /// Log de debugging (solo en modo debug)
  void debug(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _log(LogLevel.debug, message, tag, error, stackTrace, metadata);
  }

  /// Log de información
  void info(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _log(LogLevel.info, message, tag, error, stackTrace, metadata);
  }

  /// Log de advertencia
  void warning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _log(LogLevel.warning, message, tag, error, stackTrace, metadata);
  }

  /// Log de error
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _log(LogLevel.error, message, tag, error, stackTrace, metadata);
  }

  /// Log de error crítico
  void critical(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _log(LogLevel.critical, message, tag, error, stackTrace, metadata);
  }

  /// Log genérico
  void _log(
    LogLevel level,
    String message,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ) {
    // Filtrar por nivel mínimo
    if (level.index < minLevel.index) return;

    // Filtrar debug en release
    if (level == LogLevel.debug && kReleaseMode) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );

    // Enviar a todos los destinos
    for (final destination in destinations) {
      destination.log(entry).catchError((e) {
        debugPrint('Error logging to destination: $e');
      });
    }
  }

  /// Flush todos los destinos
  Future<void> flush() async {
    final futures = destinations.map((dest) => dest.flush());
    await Future.wait(futures);
  }

  /// Cierra todos los destinos
  Future<void> close() async {
    final futures = destinations.map((dest) => dest.close());
    await Future.wait(futures);
  }
}

/// Configuración predefinida para diferentes entornos
class LoggerConfig {
  /// Configuración para desarrollo
  static void development() {
    AppLogger.initialize(
      destinations: [
        const ConsoleLogDestination(enableInRelease: false),
        MemoryLogDestination(maxEntries: 500),
      ],
      minLevel: LogLevel.debug,
    );
  }

  /// Configuración para testing
  static void testing() {
    AppLogger.initialize(
      destinations: [
        MemoryLogDestination(maxEntries: 100),
      ],
      minLevel: LogLevel.info,
    );
  }

  /// Configuración para producción
  static void production() {
    AppLogger.initialize(
      destinations: [
        const ConsoleLogDestination(enableInRelease: false),
        FileLogDestination(
          maxFileSizeBytes: 1024 * 1024 * 2, // 2MB
          maxFiles: 3,
        ),
      ],
      minLevel: LogLevel.warning,
    );
  }
}

/// Integración con ErrorHandler
ErrorLogger createErrorLogger() {
  return (error, stackTrace, severity, context) {
    final level = _severityToLogLevel(severity);
    final tag = context?.screen ?? context?.action ?? 'ERROR';

    AppLogger.instance._log(
      level,
      error.toString(),
      tag,
      error,
      stackTrace,
      context?.toMap(),
    );
  };
}

LogLevel _severityToLogLevel(ErrorSeverity severity) {
  switch (severity) {
    case ErrorSeverity.info:
      return LogLevel.info;
    case ErrorSeverity.warning:
      return LogLevel.warning;
    case ErrorSeverity.error:
      return LogLevel.error;
    case ErrorSeverity.critical:
    case ErrorSeverity.fatal:
      return LogLevel.critical;
  }
}
