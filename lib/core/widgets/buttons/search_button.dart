import 'package:flutter/material.dart';

/// Botón de búsqueda para AppBar con diseño adaptativo
/// Configurable con icono, colores y dimensiones responsivas
class SearchButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Widget icon;
  final Color? color;
  final Color? textColor;
  final Color? iconColor;
  final double? fontSize;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const SearchButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = const Icon(Icons.search),
    this.color,
    this.textColor,
    this.iconColor,
    this.fontSize,
    this.iconSize,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    // Calcular tamaños adaptativos basados en las dimensiones
    final double effectiveHeight = height ?? 40.0;
    final double adaptiveFontSize = fontSize ?? (effectiveHeight * 0.33);
    final double adaptiveIconSize = iconSize ?? (effectiveHeight * 0.5);
    final double adaptivePaddingHorizontal = effectiveHeight * 0.33;
    final double adaptivePaddingVertical = effectiveHeight * 0.25;
    final double adaptiveSpacing = effectiveHeight * 0.15;
    
    Widget button = ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(
          (color ?? colorScheme.primaryContainer).withValues(alpha: 0.5),
        ),
        foregroundColor: WidgetStateProperty.all(
          textColor ?? colorScheme.onPrimaryContainer,
        ),
        padding: WidgetStateProperty.all(
          padding ?? EdgeInsets.symmetric(
            horizontal: adaptivePaddingHorizontal, 
            vertical: adaptivePaddingVertical,
          ),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effectiveHeight * 0.25),
          ),
        ),
        elevation: WidgetStateProperty.all(0),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme(
            data: IconThemeData(
              size: adaptiveIconSize,
              color: iconColor ?? textColor ?? colorScheme.onPrimaryContainer,
            ),
            child: icon,
          ),
          SizedBox(width: adaptiveSpacing),
          Flexible(
            child: Opacity(
              opacity: 0.6,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: adaptiveFontSize,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? colorScheme.onPrimaryContainer,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );

    // Aplicar dimensiones con contenedor fijo
    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: button,
      );
    }
    
    return button;
  }
}
