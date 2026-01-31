import 'package:flutter/material.dart';
import 'package:sellweb/core/presentation/widgets/dialog/base/base_dialog.dart';
import 'package:sellweb/core/presentation/widgets/dialog/base/dialog_components.dart';

/// Diálogo de confirmación para descartar un ticket
class DiscardTicketDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const DiscardTicketDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseDialog(
      title: 'Descartar Ticket',
      icon: Icons.delete_outline_rounded,
      width: 400,
      headerColor: theme.colorScheme.errorContainer,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DialogComponents.infoSection(
            context: context,
            title: '¿Estás seguro?',
            icon: Icons.warning_amber_rounded,
            backgroundColor: theme.colorScheme.errorContainer,
            content: Text(
              'Esta acción eliminará todos los productos del ticket actual.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DialogComponents.primaryActionButton(
          context: context,
          text: 'Descartar',
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
        ),
      ],
    );
  }
}

/// Helper function para mostrar el diálogo de descartar ticket
Future<void> showDiscardTicketDialog(
  BuildContext context, {
  required VoidCallback onConfirm,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => DiscardTicketDialog(
      onConfirm: onConfirm,
    ),
  );
}
