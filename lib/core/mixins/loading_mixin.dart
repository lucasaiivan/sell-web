import 'package:flutter/material.dart';

/// Mixin que proporciona funcionalidad de loading states
/// para widgets que necesitan mostrar estados de carga
mixin LoadingMixin<T extends StatefulWidget> on State<T> {
  // ==========================================
  // PROPIEDADES PRIVADAS
  // ==========================================

  bool _isLoading = false;
  String? _loadingMessage;

  // ==========================================
  // GETTERS PÚBLICOS
  // ==========================================

  /// Indica si actualmente se está cargando algo
  bool get isLoading => _isLoading;

  /// Mensaje actual de loading
  String? get loadingMessage => _loadingMessage;

  /// Indica si no se está cargando
  bool get isNotLoading => !_isLoading;

  // ==========================================
  // MÉTODOS DE CONTROL DE LOADING
  // ==========================================

  /// Inicia el estado de loading
  void startLoading([String? message]) {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadingMessage = message;
      });
    }
  }

  /// Detiene el estado de loading
  void stopLoading() {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
    }
  }

  /// Actualiza el mensaje de loading sin cambiar el estado
  void updateLoadingMessage(String? message) {
    if (mounted && _isLoading) {
      setState(() {
        _loadingMessage = message;
      });
    }
  }

  /// Alterna el estado de loading
  void toggleLoading([String? message]) {
    if (_isLoading) {
      stopLoading();
    } else {
      startLoading(message);
    }
  }

  // ==========================================
  // MÉTODOS DE EJECUCIÓN CON LOADING
  // ==========================================

  /// Ejecuta una función asíncrona con loading automático
  Future<R> executeWithLoading<R>(
    Future<R> Function() action, {
    String? loadingMessage,
    bool showErrorSnackBar = true,
    String? errorMessage,
  }) async {
    try {
      startLoading(loadingMessage);
      final result = await action();
      return result;
    } catch (error) {
      if (showErrorSnackBar && mounted) {
        final message = errorMessage ?? 'Ha ocurrido un error: $error';
        _showErrorSnackBar(message);
      }
      rethrow;
    } finally {
      stopLoading();
    }
  }

  /// Ejecuta múltiples acciones en secuencia con loading
  Future<void> executeSequentialActions(
    List<SequentialAction> actions, {
    bool stopOnError = true,
    bool showErrorSnackBar = true,
  }) async {
    for (int i = 0; i < actions.length; i++) {
      final action = actions[i];

      try {
        startLoading(action.loadingMessage ?? 'Ejecutando acción ${i + 1}...');
        await action.action();

        if (action.successMessage != null && mounted) {
          _showSuccessSnackBar(action.successMessage!);
        }
      } catch (error) {
        if (showErrorSnackBar && mounted) {
          final message =
              action.errorMessage ?? 'Error en acción ${i + 1}: $error';
          _showErrorSnackBar(message);
        }

        if (stopOnError) {
          stopLoading();
          rethrow;
        }
      }
    }

    stopLoading();
  }

  /// Ejecuta acciones en paralelo con loading
  Future<List<R>> executeParallelActions<R>(
    List<Future<R> Function()> actions, {
    String? loadingMessage,
    bool showErrorSnackBar = true,
  }) async {
    try {
      startLoading(loadingMessage ?? 'Ejecutando acciones...');
      final results = await Future.wait(actions.map((action) => action()));
      return results;
    } catch (error) {
      if (showErrorSnackBar && mounted) {
        _showErrorSnackBar('Error ejecutando acciones: $error');
      }
      rethrow;
    } finally {
      stopLoading();
    }
  }

  // ==========================================
  // WIDGETS DE LOADING
  // ==========================================

  /// Widget que muestra el indicador de loading por defecto
  Widget buildLoadingIndicator({
    String? message,
    Color? color,
    double? size,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? 40,
            height: size ?? 40,
            child: CircularProgressIndicator(
              color: color,
              strokeWidth: 3,
            ),
          ),
          if (message != null || _loadingMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              message ?? _loadingMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color ?? Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Widget que muestra loading en línea (horizontal)
  Widget buildInlineLoadingIndicator({
    String? message,
    Color? color,
    double? size,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size ?? 20,
          height: size ?? 20,
          child: CircularProgressIndicator(
            color: color,
            strokeWidth: 2,
          ),
        ),
        if (message != null || _loadingMessage != null) ...[
          const SizedBox(width: 12),
          Text(
            message ?? _loadingMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color ?? Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ],
    );
  }

  /// Widget overlay que muestra loading sobre el contenido existente
  Widget buildLoadingOverlay({
    required Widget child,
    String? message,
    Color? overlayColor,
    bool showSpinner = true,
  }) {
    return Stack(
      children: [
        child,
        if (_isLoading)
          Container(
            color: overlayColor ?? Colors.black54,
            child: showSpinner
                ? buildLoadingIndicator(
                    message: message,
                    color: Colors.white,
                  )
                : const SizedBox.expand(),
          ),
      ],
    );
  }

  /// Widget que condicionalemente muestra loading o contenido
  Widget buildConditionalContent({
    required Widget content,
    Widget? loadingWidget,
    String? loadingMessage,
  }) {
    if (_isLoading) {
      return loadingWidget ?? buildLoadingIndicator(message: loadingMessage);
    }
    return content;
  }

  // ==========================================
  // MÉTODOS DE VALIDACIÓN
  // ==========================================

  /// Verifica si se puede ejecutar una acción (no está loading)
  bool canExecuteAction() {
    if (_isLoading) {
      _showInfoSnackBar('Por favor espera a que termine la operación actual');
      return false;
    }
    return true;
  }

  /// Ejecuta una acción solo si no está loading
  Future<R?> executeIfNotLoading<R>(
    Future<R> Function() action, {
    String? loadingMessage,
    String? busyMessage,
  }) async {
    if (!canExecuteAction()) {
      if (busyMessage != null) {
        _showInfoSnackBar(busyMessage);
      }
      return null;
    }

    return executeWithLoading(action, loadingMessage: loadingMessage);
  }

  // ==========================================
  // MÉTODOS HELPER PRIVADOS
  // ==========================================

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Cerrar',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==========================================
  // LIFECYCLE OVERRIDES
  // ==========================================

  @override
  void dispose() {
    // Limpiar estado de loading al destruir el widget
    _isLoading = false;
    _loadingMessage = null;
    super.dispose();
  }
}

/// Clase helper para acciones secuenciales
class SequentialAction {
  final Future<void> Function() action;
  final String? loadingMessage;
  final String? successMessage;
  final String? errorMessage;

  const SequentialAction({
    required this.action,
    this.loadingMessage,
    this.successMessage,
    this.errorMessage,
  });
}

/// Mixin especializado para loading en forms
mixin FormLoadingMixin<T extends StatefulWidget> on State<T> {
  final Map<String, bool> _fieldLoadingStates = {};

  /// Verifica si un campo específico está loading
  bool isFieldLoading(String fieldKey) =>
      _fieldLoadingStates[fieldKey] ?? false;

  /// Inicia loading para un campo específico
  void startFieldLoading(String fieldKey) {
    if (mounted) {
      setState(() {
        _fieldLoadingStates[fieldKey] = true;
      });
    }
  }

  /// Detiene loading para un campo específico
  void stopFieldLoading(String fieldKey) {
    if (mounted) {
      setState(() {
        _fieldLoadingStates[fieldKey] = false;
      });
    }
  }

  /// Ejecuta una acción con loading para un campo específico
  Future<R> executeFieldAction<R>(
    String fieldKey,
    Future<R> Function() action,
  ) async {
    try {
      startFieldLoading(fieldKey);
      return await action();
    } finally {
      stopFieldLoading(fieldKey);
    }
  }

  /// Verifica si algún campo está loading
  bool get hasAnyFieldLoading =>
      _fieldLoadingStates.values.any((loading) => loading);

  /// Detiene loading para todos los campos
  void stopAllFieldLoading() {
    if (mounted) {
      setState(() {
        _fieldLoadingStates.clear();
      });
    }
  }

  @override
  void dispose() {
    _fieldLoadingStates.clear();
    super.dispose();
  }
}

/// Mixin para loading con debounce (evita llamadas múltiples)
mixin DebouncedLoadingMixin<T extends StatefulWidget> on State<T> {
  final Map<String, DateTime> _lastExecutionTimes = {};
  final Duration _defaultDebounceTime = const Duration(milliseconds: 500);

  /// Ejecuta una acción con debounce
  Future<R?> executeWithDebounce<R>(
    String actionKey,
    Future<R> Function() action, {
    Duration? debounceTime,
    String? loadingMessage,
  }) async {
    final now = DateTime.now();
    final lastExecution = _lastExecutionTimes[actionKey];
    final debounce = debounceTime ?? _defaultDebounceTime;

    if (lastExecution != null && now.difference(lastExecution) < debounce) {
      return null; // Ignorar ejecución por debounce
    }

    _lastExecutionTimes[actionKey] = now;

    try {
      if (mounted) {
        setState(() {
          // Lógica de loading si se requiere
        });
      }
      return await action();
    } catch (error) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _lastExecutionTimes.clear();
    super.dispose();
  }
}
