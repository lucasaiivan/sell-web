import 'package:flutter/material.dart';

/// Diálogo base que implementa Material Design 3 con apariencia consistente
///
/// Proporciona una estructura estándar para todos los diálogos de la aplicación
/// siguiendo las especificaciones de Material Design 3
class BaseDialog extends StatelessWidget {
  const BaseDialog({
    super.key,
    required this.title,
    required this.content,
    this.icon,
    this.actions,
    this.width,
    this.maxHeight = 600,
    this.headerColor,
    this.showCloseButton = true,
    this.scrollable = true,
  });

  /// Título del diálogo que aparece en el header
  final String title;

  /// Contenido principal del diálogo
  final Widget content;

  /// Icono opcional que aparece junto al título
  final IconData? icon;

  /// Lista de acciones/botones en la parte inferior
  final List<Widget>? actions;

  /// Ancho específico del diálogo (por defecto se adapta al contenido)
  final double? width;

  /// Altura máxima del diálogo antes de hacerlo scrollable
  final double maxHeight;

  /// Color de fondo del header (por defecto usa primaryContainer)
  final Color? headerColor;

  /// Mostrar botón de cerrar en el header
  final bool showCloseButton;

  /// Hacer el contenido scrollable
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: width,
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: 600, // Máximo para desktop
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header del diálogo
            _buildHeader(context, theme),

            // Contenido principal
            Flexible(
              child: scrollable
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      child: content,
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      child: content,
                    ),
            ),

            // Acciones/botones
            if (actions != null && actions!.isNotEmpty)
              _buildActions(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final effectiveHeaderColor =
        headerColor ?? theme.colorScheme.primaryContainer;
    final textColor = theme.colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
      decoration: BoxDecoration(
        color: effectiveHeaderColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: textColor,
              size: 28,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (showCloseButton)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.close_rounded,
                color: textColor,
              ),
              tooltip: 'Cerrar',
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: textColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ...actions!.map((action) {
            // Agregar espaciado entre botones
            final index = actions!.indexOf(action);
            return Padding(
              padding: EdgeInsets.only(
                left: index > 0 ? 12 : 0,
              ),
              child: action,
            );
          }),
        ],
      ),
    );
  }
}

/// Helper function para mostrar un diálogo base
Future<T?> showBaseDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  IconData? icon,
  List<Widget>? actions,
  double? width,
  double maxHeight = 600,
  Color? headerColor,
  bool showCloseButton = true,
  bool scrollable = true,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => BaseDialog(
      title: title,
      content: content,
      icon: icon,
      actions: actions,
      width: width,
      maxHeight: maxHeight,
      headerColor: headerColor,
      showCloseButton: showCloseButton,
      scrollable: scrollable,
    ),
  );
}
