import 'package:flutter/material.dart';

/// Botón para AppBar con diseño personalizado
/// Soporta iconos leading/trailing y contenido widget configurable
class AppBarButton extends StatelessWidget {
  final Widget text;
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
            if (hasTrailingIcon) ...[
              Icon(iconTrailing, color: accentColor, size: 24),
            ],
            text,
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: onTap,
      style: _buildButtonStyle(backgroundColor, accentColor),
      child: text,
    );
  }

  ButtonStyle _buildButtonStyle(Color backgroundColor, Color accentColor) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: accentColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      elevation: 0,
    );
  }
}

/// Un botón circular para el AppBar, personalizable y reutilizable.
/// Puede mostrar solo un icono o un icono con texto.
/// Incluye soporte para estado de carga con CircularProgressIndicator.
class AppBarButtonCircle extends StatelessWidget {
  const AppBarButtonCircle({
    super.key,
    this.icon,
    required this.onPressed,
    required this.tooltip,
    this.backgroundColor,
    this.colorAccent,
    this.text,
    this.isLoading = false,
  });

  final IconData? icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? backgroundColor;
  final Color? colorAccent;
  final String? text;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDisabled = onPressed == null && !isLoading;

    // Colores efectivos basados en el estado del botón
    final effectiveBackgroundColor = isDisabled
        ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
        : (backgroundColor ??
            theme.colorScheme.primaryContainer.withValues(alpha: 0.5));

    final effectiveIconColor = isDisabled
        ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
        : (colorAccent ?? theme.colorScheme.primary);

    final bool hasText = text != null && text!.isNotEmpty;
    final bool hasIcon = icon != null;

    // Si no hay icono ni texto, no mostrar nada
    if (!hasIcon && !hasText) {
      return const SizedBox.shrink();
    }

    // Calcular tamaño del icono basado en el tamaño del botón (40% del área)
    const double buttonSize = 48.0;
    const double iconSize = buttonSize * 0.4; // 19.2 ≈ 20

    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: Tooltip(
        message: tooltip,
        child: TextButton(
          onPressed:
              isLoading ? null : onPressed, // Deshabilitar durante loading
          style: TextButton.styleFrom(
            backgroundColor: effectiveBackgroundColor,
            shape: hasText ? const StadiumBorder() : const CircleBorder(),
            padding: hasText
                ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0)
                : EdgeInsets
                    .zero, // Sin padding para botón circular - centrado perfecto
            minimumSize: const Size(buttonSize, buttonSize),
            maximumSize:
                hasText ? Size.infinite : const Size(buttonSize, buttonSize),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: hasText
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Contenido con icono (si existe)
                    if (hasIcon) ...[
                      isLoading
                          ? SizedBox(
                              width: iconSize,
                              height: iconSize,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  effectiveIconColor,
                                ),
                              ),
                            )
                          : Icon(
                              icon!,
                              color: effectiveIconColor,
                              size: iconSize,
                            ),
                      if (hasText) const SizedBox(width: 6.0),
                    ],
                    // Contenido con texto (si existe)
                    if (hasText)
                      Flexible(
                        child: Text(
                          text!,
                          style: TextStyle(
                            color: effectiveIconColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                )
              : Center(
                  // Centrado perfecto para botón solo con icono o texto
                  child: hasIcon
                      ? (isLoading
                          ? SizedBox(
                              width: iconSize,
                              height: iconSize,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  effectiveIconColor,
                                ),
                              ),
                            )
                          : Icon(
                              icon!,
                              color: effectiveIconColor,
                              size: iconSize,
                            ))
                      : hasText
                          ? Text(
                              text!,
                              style: TextStyle(
                                color: effectiveIconColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            )
                          : const SizedBox.shrink(),
                ),
        ),
      ),
    );
  }
}
