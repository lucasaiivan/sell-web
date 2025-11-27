import 'package:flutter/material.dart';

/// Sistema de mensajes y alertas de la aplicación
class AppFeedback {
  /// Muestra un SnackBar con título y mensaje personalizados
  static void showMessage(
    BuildContext context, {
    required String title,
    required String message,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Limpiar SnackBars existentes para evitar Hero tag duplicados
    ScaffoldMessenger.of(context).clearSnackBars();

    final uniqueKey = UniqueKey();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: uniqueKey,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: backgroundColor ??
            (theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surface),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: duration,
      ),
    );
  }

  /// Muestra un mensaje de éxito
  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showMessage(
      context,
      title: title,
      message: message,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  /// Muestra un mensaje de error
  static void showError(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showMessage(
      context,
      title: title,
      message: message,
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
    );
  }

  /// Muestra un mensaje de advertencia
  static void showWarning(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showMessage(
      context,
      title: title,
      message: message,
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
    );
  }
}
