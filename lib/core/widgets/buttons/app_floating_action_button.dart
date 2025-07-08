import 'package:flutter/material.dart';

/// FloatingActionButton personalizado con soporte para texto, icono o ambos
/// Implementa Material 3 con colores configurables
class AppFloatingActionButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? buttonColor;
  final Color? foregroundColor;
  final double? size;
  final bool extended;

  const AppFloatingActionButton({
    super.key,
    this.text,
    this.icon,
    this.onTap,
    this.buttonColor,
    this.foregroundColor,
    this.size,
    this.extended = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool hasIcon = icon != null;
    final bool hasText = text != null && text!.isNotEmpty;
    final double buttonSize = size ?? 56.0;

    // Colores efectivos con fallback a Material 3
    final Color effectiveButtonColor = buttonColor ?? colorScheme.primary;
    final Color effectiveForegroundColor =
        foregroundColor ?? colorScheme.onPrimary;

    if (hasText && (extended || hasIcon)) {
      // FloatingActionButton.extended para texto o icono+texto
      return FloatingActionButton.extended(
        onPressed: onTap,
        backgroundColor: effectiveButtonColor,
        foregroundColor: effectiveForegroundColor,
        icon: hasIcon ? Icon(icon, size: buttonSize * 0.45) : null,
        label: Text(
          text!,
          style: TextStyle(
            fontSize: buttonSize * 0.28,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (hasIcon) {
      // Solo icono
      return FloatingActionButton(
        onPressed: onTap,
        backgroundColor: effectiveButtonColor,
        foregroundColor: effectiveForegroundColor,
        child: Icon(icon, size: buttonSize * 0.5),
      );
    } else {
      // Widget vacío si no hay contenido
      return const SizedBox.shrink();
    }
  }
}
