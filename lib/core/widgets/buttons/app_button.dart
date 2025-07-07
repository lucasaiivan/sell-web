import 'package:flutter/material.dart';

/// Botón principal de la aplicación con diseño Material 3
/// Soporta iconos, textos y configuraciones personalizadas
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? fontSize;
  final double? iconSize;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double elevation;
  final bool disable;
  final bool defaultStyle;
  final Size? minimumSize;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize = 14,
    this.iconSize,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    this.width = double.infinity,
    this.elevation = 0,
    this.disable = false,
    this.defaultStyle = false,
    this.minimumSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Padding(
        key: ValueKey(disable),
        padding: margin!,
        child: SizedBox(
          width: width,
          child: icon != null
              ? ElevatedButton.icon(
                  onPressed: disable ? null : onPressed,
                  style: _buildButtonStyle(colorScheme),
                  icon: iconSize != null
                      ? IconTheme(
                          data: IconThemeData(size: iconSize),
                          child: icon!,
                        )
                      : icon!,
                  label: Text(
                    text,
                    style: TextStyle(
                      color: foregroundColor ?? Colors.white,
                      fontSize: fontSize,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : ElevatedButton(
                  onPressed: disable ? null : onPressed,
                  style: _buildButtonStyle(colorScheme),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: foregroundColor ?? Colors.white,
                      fontSize: fontSize,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
      ),
    );
  }

  ButtonStyle _buildButtonStyle(ColorScheme colorScheme) {
    return ElevatedButton.styleFrom(
      elevation: defaultStyle ? 0 : elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      padding: padding,
      backgroundColor: backgroundColor ?? colorScheme.primary,
      foregroundColor: foregroundColor ?? colorScheme.onPrimary,
      textStyle: TextStyle(
        color: foregroundColor ?? Colors.white,
        fontWeight: FontWeight.w700,
      ),
      minimumSize: minimumSize,
    );
  }
}
