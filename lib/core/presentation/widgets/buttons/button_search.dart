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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final double effectiveHeight = height ?? 44.0;
    final double adaptiveFontSize = fontSize ?? 14.0;
    final double adaptiveIconSize = iconSize ?? 20.0;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width ?? double.infinity,
        height: effectiveHeight,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.3 : 0.5),
          borderRadius: BorderRadius.circular(effectiveHeight / 2),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.05),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(effectiveHeight / 2),
            splashColor: colorScheme.primary.withValues(alpha: 0.05),
            highlightColor: colorScheme.primary.withValues(alpha: 0.02),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconTheme(
                    data: IconThemeData(
                      size: adaptiveIconSize,
                      color: iconColor ?? colorScheme.onSurfaceVariant,
                    ),
                    child: icon,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: adaptiveFontSize,
                        color: textColor ?? colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  // Opcional: Icono final para dar balance
                  Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
