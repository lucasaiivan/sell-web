import 'package:flutter/material.dart';

/// TextButton reutilizable de la aplicación con diseño Material 3
/// Proporciona un botón de texto consistente siguiendo el estilo de la app
class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final bool isLoading;
  final double loadingSize;

  const AppTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.foregroundColor,
    this.backgroundColor,
    this.fontSize,
    this.fontWeight,
    this.padding,
    this.borderRadius,
    this.isLoading = false,
    this.loadingSize = 16,
  });

  /// Constructor factory para botón con icono
  factory AppTextButton.icon({
    Key? key,
    required String text,
    required Widget icon,
    VoidCallback? onPressed,
    Color? foregroundColor,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    bool isLoading = false,
    double loadingSize = 16,
  }) {
    return AppTextButton(
      key: key,
      text: text,
      onPressed: onPressed,
      icon: icon,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      padding: padding,
      borderRadius: borderRadius,
      isLoading: isLoading,
      loadingSize: loadingSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Colores por defecto
    final effectiveForegroundColor = foregroundColor ?? colorScheme.primary;
    final effectiveBackgroundColor = backgroundColor ?? Colors.transparent;

    final buttonStyle = TextButton.styleFrom(
      foregroundColor: effectiveForegroundColor,
      backgroundColor: effectiveBackgroundColor,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontSize: fontSize ?? 14,
        fontWeight: fontWeight ?? FontWeight.w500,
      ),
    );

    Widget buttonChild;

    if (isLoading) {
      buttonChild = SizedBox(
        width: loadingSize,
        height: loadingSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: effectiveForegroundColor,
        ),
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    } else {
      buttonChild = Text(text);
    }

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: buttonChild,
    );
  }
}
