import 'package:flutter/material.dart';

/// Diálogo base que implementa Material Design 3 con apariencia consistente
///
/// Proporciona una estructura estándar para todos los diálogos de la aplicación
/// siguiendo las especificaciones de Material Design 3
class BaseDialog extends StatelessWidget {
  const BaseDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.icon,
    this.actions,
    this.width=400,
    this.maxHeight = 600,
    this.headerColor,
    this.showCloseButton = true,
    this.scrollable = true,
  });

  /// Título del diálogo que aparece en el header
  final String title;

  /// Subtítulo opcional que aparece debajo del título en el header
  final String? subtitle;

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
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Container(
        width: width,
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: 500, // Máximo para desktop
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

            // Contenido principal con gradiente difuminado
            _buildContentWithGradient(context, theme),

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
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

  /// Construye el contenido con efecto de gradiente difuminado al final
  Widget _buildContentWithGradient(BuildContext context, ThemeData theme) {
    final hasActions = actions != null && actions!.isNotEmpty;

    if (!scrollable) {
      // Si no es scrollable, solo agregar padding normal
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: content,
      );
    }

    // Usar Flexible con shrinkWrap para ajustarse al contenido
    return Flexible(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Contenido scrollable que se ajusta al tamaño real
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  hasActions ? 32 : 16, // Padding inferior para el gradiente
                ),
                child: content,
              ),

              // Gradiente difuminado al final (solo si hay acciones)
              if (hasActions)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.surface.withValues(alpha: 0.0),
                            theme.colorScheme.surface.withValues(alpha: 0.5),
                            theme.colorScheme.surface.withValues(alpha: 0.9),
                            theme.colorScheme.surface,
                          ],
                          stops: const [0.0, 0.4, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActions(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.max,
        children: [
          for (int i = 0; i < actions!.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Flexible(
              child: actions![i],
            ),
          ],
        ],
      ),
    );
  }
}

/// Helper function para mostrar un diálogo base
Future<T?> showBaseDialog<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required Widget content,
  IconData? icon,
  List<Widget>? actions,
  double? width,
  double maxHeight = 600,
  Color? headerColor,
  bool showCloseButton = true,
  bool scrollable = true,
  bool barrierDismissible =
      false, // Por defecto no se cierra al hacer click fuera
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => BaseDialog(
      title: title,
      subtitle: subtitle,
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
