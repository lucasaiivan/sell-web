import 'package:flutter/material.dart';

/// Botón para AppBar con diseño personalizado
/// Soporta iconos leading/trailing y texto configurable
class AppBarButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color? colorBackground;
  final Color? colorAccent;
  final IconData? iconLeading;
  final IconData? iconTrailing;
  final EdgeInsetsGeometry padding;
  final bool textOpacity;

  const AppBarButton({
    super.key,
    required this.text,
    this.onTap,
    this.colorBackground,
    this.colorAccent,
    this.iconLeading,
    this.iconTrailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    this.textOpacity = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color effectiveBackground =
        colorBackground ?? (isDark ? Colors.white : Colors.black);
    final Color effectiveAccent =
        colorAccent ?? (isDark ? Colors.black : Colors.white);

    return Padding(
      padding: padding,
      child: _buildButton(effectiveBackground, effectiveAccent),
    );
  }

  Widget _buildButton(Color backgroundColor, Color accentColor) {
    final bool hasLeadingIcon = iconLeading != null;
    final bool hasTrailingIcon = iconTrailing != null;

    if (hasLeadingIcon || hasTrailingIcon) {
      return ElevatedButton.icon(
        onPressed: onTap,
        style: _buildButtonStyle(backgroundColor, accentColor),
        icon: hasLeadingIcon
            ? Icon(iconLeading, color: accentColor, size: 24)
            : const SizedBox.shrink(),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Opacity(
                opacity: textOpacity ? 0.5 : 1,
                child: Text(
                  text,
                  style: TextStyle(color: accentColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (hasTrailingIcon) ...[
              const SizedBox(width: 8),
              Icon(iconTrailing, color: accentColor, size: 24),
            ],
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: onTap,
      style: _buildButtonStyle(backgroundColor, accentColor),
      child: Opacity(
        opacity: textOpacity ? 0.5 : 1,
        child: Text(
          text,
          style: TextStyle(color: accentColor),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  ButtonStyle _buildButtonStyle(Color backgroundColor, Color accentColor) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: accentColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      elevation: 0,
      padding: const EdgeInsets.only(left: 14, right: 20, top: 8, bottom: 8),
    );
  }
}

/// Un botón circular para el AppBar, personalizable y reutilizable.
/// Puede mostrar solo un icono o un icono con texto.
class AppBarButtonCircle extends StatelessWidget {
  const AppBarButtonCircle({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.backgroundColor,
    this.iconColor,
    this.text,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor =
        backgroundColor ?? theme.colorScheme.primaryContainer.withOpacity(0.1);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    final bool hasText = text != null && text!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: Tooltip(
        message: tooltip,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: effectiveBackgroundColor,
            shape: hasText ? const StadiumBorder() : const CircleBorder(),
            padding: const EdgeInsets.all(12.0),
            minimumSize: const Size(48, 48),
            maximumSize: hasText ? Size.infinite : const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: effectiveIconColor,
                size: 20,
              ),
              if (hasText) ...[
                const SizedBox(width: 6.0),
                Flexible(
                  child: Text(
                    text!,
                    style: TextStyle(
                      color: effectiveIconColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
