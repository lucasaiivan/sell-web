import 'package:flutter/material.dart';

/// Enumeración para definir tipos de botones unificados
enum ButtonAppType {
  elevated, // ElevatedButton - botón primario con elevación
  filled, // FilledButton - botón secundario relleno
  outlined, // OutlinedButton - botón con borde
  text, // TextButton - botón de texto
  fab, // FloatingActionButton - botón flotante
}

/// Botón unificado de la aplicación con diseño Material 3
/// Combina todas las funcionalidades de botones en un solo widget:
/// - ButtonApp (elevated)
/// - ButtonAppText (text)
/// - ButtonAppFab (fab)
/// - ButtonAppOutlined (outlined)
/// - ButtonAppFilled (filled)
class ButtonApp extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final ButtonAppType type;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? iconSize;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double elevation;
  final bool disable;
  final bool defaultStyle;
  final Size? minimumSize;
  final bool isLoading;
  final Color? loadingColor;
  final double loadingSize;
  final double borderRadius;
  final BorderRadius? customBorderRadius;
  final bool extended; // Para FAB extendido
  final Object? heroTag; // Para FAB héroe tag

  const ButtonApp({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.type = ButtonAppType.elevated,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.fontSize = 14,
    this.fontWeight,
    this.iconSize,
    this.padding,
    this.margin,
    this.width,
    this.elevation = 0,
    this.disable = false,
    this.defaultStyle = false,
    this.minimumSize,
    this.isLoading = false,
    this.loadingColor,
    this.loadingSize = 20,
    this.borderRadius = 20,
    this.customBorderRadius,
    this.extended = false,
    this.heroTag,
  });

  /// Constructor factory para botón primario elevado (compatibilidad)
  factory ButtonApp.primary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Color? backgroundColor,
    Color? textColor,
    double borderRadius = 16,
    Widget? icon,
  }) {
    return ButtonApp(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      type: ButtonAppType.elevated,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      borderRadius: borderRadius,
      icon: icon,
    );
  }

  /// Constructor factory para botón de texto
  factory ButtonApp.text({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    Widget? icon,
    Color? foregroundColor,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    bool isLoading = false,
    double loadingSize = 16,
  }) {
    return ButtonApp(
      key: key,
      text: text,
      onPressed: onPressed,
      icon: icon,
      type: ButtonAppType.text,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      customBorderRadius: borderRadius,
      isLoading: isLoading,
      loadingSize: loadingSize,
    );
  }

  /// Constructor factory para botón outlined
  factory ButtonApp.outlined({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    Widget? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    double? fontSize,
    EdgeInsets? padding,
    bool isLoading = false,
    double borderRadius = 20,
  }) {
    return ButtonApp(
      key: key,
      text: text,
      onPressed: onPressed,
      icon: icon,
      type: ButtonAppType.outlined,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      borderColor: borderColor,
      fontSize: fontSize,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      isLoading: isLoading,
      borderRadius: borderRadius,
    );
  }

  /// Constructor factory para botón filled
  factory ButtonApp.filled({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    Widget? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    double? fontSize,
    EdgeInsets? padding,
    bool isLoading = false,
    double borderRadius = 20,
  }) {
    return ButtonApp(
      key: key,
      text: text,
      onPressed: onPressed,
      icon: icon,
      type: ButtonAppType.filled,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      fontSize: fontSize,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      isLoading: isLoading,
      borderRadius: borderRadius,
    );
  }

  /// Constructor factory para FloatingActionButton
  factory ButtonApp.fab({
    Key? key,
    String? text,
    IconData? icon,
    VoidCallback? onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
    double? size,
    bool extended = false,
    Object? heroTag,
  }) {
    return ButtonApp(
      key: key,
      text: text ?? '',
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : null,
      type: ButtonAppType.fab,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      width: size,
      extended: extended,
      heroTag: heroTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: width,
      margin: margin,
      child: _buildButtonByType(context, colorScheme),
    );
  }

  Widget _buildButtonByType(BuildContext context, ColorScheme colorScheme) {
    switch (type) {
      case ButtonAppType.elevated:
        return _buildElevatedButton(colorScheme);
      case ButtonAppType.filled:
        return _buildFilledButton(colorScheme);
      case ButtonAppType.outlined:
        return _buildOutlinedButton(colorScheme);
      case ButtonAppType.text:
        return _buildTextButton(context, colorScheme);
      case ButtonAppType.fab:
        return _buildFloatingActionButton(colorScheme);
    }
  }

  Widget _buildElevatedButton(ColorScheme colorScheme) {
    final bool isDisabled = disable || isLoading;

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: isDisabled ? null : onPressed,
        style: _buildElevatedButtonStyle(colorScheme),
        icon: _buildButtonIcon(),
        label: _buildButtonContent(),
      );
    } else {
      return ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: _buildElevatedButtonStyle(colorScheme),
        child: _buildButtonContent(),
      );
    }
  }

  Widget _buildFilledButton(ColorScheme colorScheme) {
    final bool isDisabled = disable || isLoading;

    if (icon != null) {
      return FilledButton.icon(
        onPressed: isDisabled ? null : onPressed,
        style: _buildFilledButtonStyle(colorScheme),
        icon: _buildButtonIcon(),
        label: _buildButtonContent(),
      );
    } else {
      return FilledButton(
        onPressed: isDisabled ? null : onPressed,
        style: _buildFilledButtonStyle(colorScheme),
        child: _buildButtonContent(),
      );
    }
  }

  Widget _buildOutlinedButton(ColorScheme colorScheme) {
    final bool isDisabled = disable || isLoading;

    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: isDisabled ? null : onPressed,
        style: _buildOutlinedButtonStyle(colorScheme),
        icon: _buildButtonIcon(),
        label: _buildButtonContent(),
      );
    } else {
      return OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        style: _buildOutlinedButtonStyle(colorScheme),
        child: _buildButtonContent(),
      );
    }
  }

  Widget _buildTextButton(BuildContext context, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final effectiveForegroundColor = foregroundColor ?? colorScheme.primary;
    final effectiveBackgroundColor = backgroundColor ?? Colors.transparent;

    final buttonStyle = TextButton.styleFrom(
      foregroundColor: effectiveForegroundColor,
      backgroundColor: effectiveBackgroundColor,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: customBorderRadius ?? BorderRadius.circular(borderRadius),
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

  Widget _buildFloatingActionButton(ColorScheme colorScheme) {
    final bool hasIcon = icon != null;
    final bool hasText = text.isNotEmpty;
    final double buttonSize = width ?? 56.0;

    // Colores efectivos con fallback a Material 3
    final Color effectiveButtonColor = backgroundColor ?? colorScheme.primary;
    final Color effectiveForegroundColor =
        foregroundColor ?? colorScheme.onPrimary;

    if (hasText && (extended || hasIcon)) {
      // FloatingActionButton.extended para texto o icono+texto
      return FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: effectiveButtonColor,
        foregroundColor: effectiveForegroundColor,
        icon: hasIcon
            ? IconTheme(
                data: IconThemeData(size: buttonSize * 0.45),
                child: icon!,
              )
            : null,
        label: Text(
          text,
          style: TextStyle(
            fontSize: fontSize ?? buttonSize * 0.28,
            fontWeight: fontWeight ?? FontWeight.w600,
          ),
        ),
      );
    } else if (hasIcon) {
      // Solo icono
      return FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: effectiveButtonColor,
        foregroundColor: effectiveForegroundColor,
        child: IconTheme(
          data: IconThemeData(size: buttonSize * 0.5),
          child: icon!,
        ),
      );
    } else {
      // Widget vacío si no hay contenido
      return const SizedBox.shrink();
    }
  }

  Widget _buildButtonIcon() {
    if (isLoading) {
      return SizedBox(
        width: loadingSize,
        height: loadingSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            loadingColor ?? foregroundColor ?? Colors.white,
          ),
        ),
      );
    }

    return iconSize != null
        ? IconTheme(
            data: IconThemeData(size: iconSize),
            child: icon!,
          )
        : icon!;
  }

  Widget _buildButtonContent() {
    if (isLoading && icon == null) {
      return SizedBox(
        width: loadingSize,
        height: loadingSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            loadingColor ?? foregroundColor ?? Colors.white,
          ),
        ),
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
      textAlign: TextAlign.center,
    );
  }

  ButtonStyle _buildElevatedButtonStyle(ColorScheme colorScheme) {
    return ElevatedButton.styleFrom(
      elevation: defaultStyle ? 0 : elevation,
      shape: RoundedRectangleBorder(
        borderRadius: customBorderRadius ?? BorderRadius.circular(borderRadius),
      ),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      textStyle: TextStyle(
        color: foregroundColor,
        fontWeight: fontWeight ?? FontWeight.w700,
      ),
      minimumSize: minimumSize,
    );
  }

  ButtonStyle _buildFilledButtonStyle(ColorScheme colorScheme) {
    return FilledButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: customBorderRadius ?? BorderRadius.circular(borderRadius),
      ),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      textStyle: TextStyle(
        fontWeight: fontWeight ?? FontWeight.w600,
      ),
      minimumSize: minimumSize,
    );
  }

  ButtonStyle _buildOutlinedButtonStyle(ColorScheme colorScheme) {
    return OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: customBorderRadius ?? BorderRadius.circular(borderRadius),
      ),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor ?? colorScheme.primary,
      side: BorderSide(
        color: borderColor ?? foregroundColor ?? colorScheme.primary,
      ),
      textStyle: TextStyle(
        fontWeight: fontWeight ?? FontWeight.w600,
      ),
      minimumSize: minimumSize,
    );
  }
}

// ============================================================================
// FIN DEL ARCHIVO - ButtonApp es el único componente de botón necesario
// ============================================================================
