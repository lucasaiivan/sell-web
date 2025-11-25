import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Widget especializado para mostrar feedback de autenticación
/// Maneja errores, estados de carga y mensajes informativos
class AuthFeedbackWidget extends StatelessWidget {
  final String? error;
  final VoidCallback? onDismissError;
  final bool showLoading;
  final String? loadingMessage;
  final String? successMessage;

  const AuthFeedbackWidget({
    super.key,
    this.error,
    this.onDismissError,
    this.showLoading = false,
    this.loadingMessage,
    this.successMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return _ErrorWidget(
        error: error!,
        onDismiss: onDismissError,
      );
    }

    if (showLoading) {
      return _LoadingWidget(
        message: loadingMessage ?? 'Procesando...',
      );
    }

    if (successMessage != null) {
      return _SuccessWidget(
        message: successMessage!,
      );
    }

    return const SizedBox.shrink();
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onDismiss;

  const _ErrorWidget({
    required this.error,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, color: Colors.red.shade600),
              onPressed: onDismiss,
              iconSize: 20,
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }
}

class _LoadingWidget extends StatelessWidget {
  final String message;

  const _LoadingWidget({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator()
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 1200.ms),
        const SizedBox(height: 16),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.7),
              ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }
}

class _SuccessWidget extends StatelessWidget {
  final String message;

  const _SuccessWidget({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }
}
