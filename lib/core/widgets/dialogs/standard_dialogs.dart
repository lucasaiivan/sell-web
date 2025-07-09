import 'package:flutter/material.dart';
import 'base_dialog.dart';

/// Diálogo de confirmación estandarizado con Material Design 3
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
    this.icon = Icons.help_outline_rounded,
    this.isDestructive = false,
    this.onConfirm,
    this.onCancel,
  });

  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final IconData icon;
  final bool isDestructive;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BaseDialog(
      title: title,
      icon: icon,
      width: 400,
      headerColor: isDestructive 
          ? theme.colorScheme.errorContainer 
          : null,
      content: Text(
        message,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                )
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }
}

/// Helper function para mostrar diálogo de confirmación
Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Confirmar',
  String cancelText = 'Cancelar',
  IconData icon = Icons.help_outline_rounded,
  bool isDestructive = false,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ConfirmationDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: icon,
      isDestructive: isDestructive,
      onConfirm: onConfirm,
      onCancel: onCancel,
    ),
  );
}

/// Diálogo de información simple
class InfoDialog extends StatelessWidget {
  const InfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'Entendido',
    this.icon = Icons.info_outline_rounded,
  });

  final String title;
  final String message;
  final String buttonText;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: title,
      icon: icon,
      width: 400,
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText),
        ),
      ],
    );
  }
}

/// Helper function para mostrar diálogo de información
Future<void> showInfoDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'Entendido',
  IconData icon = Icons.info_outline_rounded,
}) {
  return showDialog(
    context: context,
    builder: (context) => InfoDialog(
      title: title,
      message: message,
      buttonText: buttonText,
      icon: icon,
    ),
  );
}

/// Diálogo de error estandarizado
class ErrorDialog extends StatelessWidget {
  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'Cerrar',
    this.details,
  });

  final String title;
  final String message;
  final String buttonText;
  final String? details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BaseDialog(
      title: title,
      icon: Icons.error_outline_rounded,
      width: 450,
      headerColor: theme.colorScheme.errorContainer,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyLarge,
          ),
          if (details != null) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Detalles técnicos'),
              tilePadding: EdgeInsets.zero,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    details!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: Text(buttonText),
        ),
      ],
    );
  }
}

/// Helper function para mostrar diálogo de error
Future<void> showErrorDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'Cerrar',
  String? details,
}) {
  return showDialog(
    context: context,
    builder: (context) => ErrorDialog(
      title: title,
      message: message,
      buttonText: buttonText,
      details: details,
    ),
  );
}

/// Diálogo de carga con indicador de progreso
class LoadingDialog extends StatelessWidget {
  const LoadingDialog({
    super.key,
    required this.message,
    this.title = 'Cargando...',
    this.progress,
  });

  final String title;
  final String message;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: title,
      icon: Icons.hourglass_empty_rounded,
      width: 350,
      showCloseButton: false,
      scrollable: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          if (progress != null)
            LinearProgressIndicator(value: progress)
          else
            const LinearProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Helper function para mostrar diálogo de carga
Future<void> showLoadingDialog({
  required BuildContext context,
  required String message,
  String title = 'Cargando...',
  double? progress,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => LoadingDialog(
      title: title,
      message: message,
      progress: progress,
    ),
  );
}
