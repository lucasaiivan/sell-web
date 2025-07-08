import 'package:flutter/material.dart';

/// Barra de progreso lineal personalizada para la aplicación
class AppLinearProgressBar extends StatelessWidget
    implements PreferredSizeWidget {
  final Color? color;
  final Color? backgroundColor;
  final double minHeight;
  final double? value;

  const AppLinearProgressBar({
    super.key,
    this.color,
    this.backgroundColor,
    this.minHeight = 6.0,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LinearProgressIndicator(
      minHeight: minHeight,
      value: value,
      backgroundColor:
          backgroundColor ?? colorScheme.surface.withValues(alpha: 0.3),
      valueColor: AlwaysStoppedAnimation<Color>(
        color ?? colorScheme.primary,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(minHeight);
}
