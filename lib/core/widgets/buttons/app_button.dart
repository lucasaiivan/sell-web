import 'package:flutter/material.dart';

/// Botón principal unificado de la aplicación con diseño Material 3
/// Soporta iconos, textos, estado de carga y configuraciones personalizadas
///
/// Combina las funcionalidades de AppButton y PrimaryButton en un solo widget
/// optimizado para uso en toda la aplicación
// button primario
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
  final bool isLoading;
  final Color? loadingColor;
  final double loadingSize;
  final double borderRadius;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize = 14,
    this.iconSize,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    this.width,
    this.elevation = 0,
    this.disable = false,
    this.defaultStyle = false,
    this.minimumSize,
    this.isLoading = false,
    this.loadingColor,
    this.loadingSize = 20,
    this.borderRadius = 20,
  });

  /// Constructor factory para botón primario (compatibilidad con PrimaryButton)
  factory AppButton.primary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Color? backgroundColor,
    Color? textColor,
    double borderRadius = 16,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      borderRadius: borderRadius,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: width,
      child: _buildButton(colorScheme),
    );
  }

  Widget _buildButton(ColorScheme colorScheme) {
    // Determinar si el botón debe estar deshabilitado
    final bool isDisabled = disable || isLoading;

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: isDisabled ? null : onPressed,
        style: _buildButtonStyle(colorScheme),
        icon: _buildButtonIcon(),
        label: _buildButtonContent(),
      );
    } else {
      return ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: _buildButtonStyle(colorScheme),
        child: _buildButtonContent(),
      );
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
      ),
      textAlign: TextAlign.center,
    );
  }

  ButtonStyle _buildButtonStyle(ColorScheme colorScheme) {
    return ElevatedButton.styleFrom(
      elevation: defaultStyle ? 0 : elevation,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius)),
      padding: padding,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      textStyle: TextStyle(
        color: foregroundColor,
        fontWeight: FontWeight.w700,
      ),
      minimumSize: minimumSize,
    );
  }
}

/// Botón outlined unificado de la aplicación con diseño Material 3
/// Mismas funcionalidades que AppButton pero con estilo outlined
/// button secundario
class AppOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double? fontSize;
  final double? iconSize;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final bool disable;
  final Size? minimumSize;
  final bool isLoading;
  final Color? loadingColor;
  final double loadingSize;
  final double borderRadius;

  const AppOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.fontSize = 14,
    this.iconSize,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    this.width,
    this.disable = false,
    this.minimumSize,
    this.isLoading = false,
    this.loadingColor,
    this.loadingSize = 20,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: width,
      child: _buildButton(colorScheme),
    );
  }

  Widget _buildButton(ColorScheme colorScheme) {
    final bool isDisabled = disable || isLoading;

    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: isDisabled ? null : onPressed,
        style: _buildButtonStyle(colorScheme),
        icon: _buildButtonIcon(),
        label: _buildButtonContent(),
      );
    } else {
      return OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        style: _buildButtonStyle(colorScheme),
        child: _buildButtonContent(),
      );
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
            loadingColor ?? foregroundColor ?? Colors.blue,
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
            loadingColor ?? foregroundColor ?? Colors.blue,
          ),
        ),
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
      ),
      textAlign: TextAlign.center,
    );
  }

  ButtonStyle _buildButtonStyle(ColorScheme colorScheme) {
    return OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius)),
      padding: padding,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor ?? colorScheme.primary,
      side: BorderSide(
        color: borderColor ?? foregroundColor ?? colorScheme.primary,
      ),
      minimumSize: minimumSize,
    );
  }
}

/// Botón filled unificado de la aplicación con diseño Material 3
/// Mismas funcionalidades que AppButton pero con estilo filled
// button secundario
class AppFilledButton extends StatelessWidget {
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
  final bool disable;
  final Size? minimumSize;
  final bool isLoading;
  final Color? loadingColor;
  final double loadingSize;
  final double borderRadius;

  const AppFilledButton({
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
    this.width,
    this.disable = false,
    this.minimumSize,
    this.isLoading = false,
    this.loadingColor,
    this.loadingSize = 20,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: width,
      child: _buildButton(colorScheme),
    );
  }

  Widget _buildButton(ColorScheme colorScheme) {
    final bool isDisabled = disable || isLoading;

    if (icon != null) {
      return FilledButton.icon(
        onPressed: isDisabled ? null : onPressed,
        style: _buildButtonStyle(colorScheme),
        icon: _buildButtonIcon(),
        label: _buildButtonContent(),
      );
    } else {
      return FilledButton(
        onPressed: isDisabled ? null : onPressed,
        style: _buildButtonStyle(colorScheme),
        child: _buildButtonContent(),
      );
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
      ),
      textAlign: TextAlign.center,
    );
  }

  ButtonStyle _buildButtonStyle(ColorScheme colorScheme) {
    return FilledButton.styleFrom(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius)),
      padding: padding,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      minimumSize: minimumSize,
    );
  }
}
