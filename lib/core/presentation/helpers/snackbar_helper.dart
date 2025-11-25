// ==========================================
// SNACKBAR HELPER
// ==========================================
// Helper para mostrar SnackBars sin conflictos de Hero tags

import 'package:flutter/material.dart';

extension SnackBarHelper on BuildContext {
  /// Muestra un SnackBar de éxito
  void showSuccessSnackBar(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      icon: Icons.check_circle,
      backgroundColor: Colors.green,
      duration: duration ?? const Duration(seconds: 2),
    );
  }

  /// Muestra un SnackBar de error
  void showErrorSnackBar(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      icon: Icons.error_outline,
      backgroundColor: Colors.red,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Muestra un SnackBar de información
  void showInfoSnackBar(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      icon: Icons.info_outline,
      backgroundColor: Colors.blue,
      duration: duration ?? const Duration(seconds: 2),
    );
  }

  /// Muestra un SnackBar de advertencia
  void showWarningSnackBar(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      icon: Icons.warning_amber,
      backgroundColor: Colors.orange,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Muestra un SnackBar personalizado
  ///
  /// IMPORTANTE: Limpia los SnackBars anteriores para evitar
  /// conflictos de Hero tags duplicados
  void _showSnackBar({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
  }) {
    // Limpiar SnackBars existentes para evitar Hero tag duplicados
    ScaffoldMessenger.of(this).clearSnackBars();

    // Generar un tag único para evitar conflictos de Hero
    final uniqueKey = UniqueKey();

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        key: uniqueKey,
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Limpia todos los SnackBars activos
  void clearSnackBars() {
    ScaffoldMessenger.of(this).clearSnackBars();
  }
}
