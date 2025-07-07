import 'package:flutter/material.dart';

/// Divisor estándar de la aplicación con grosor configurable
class AppDivider extends StatelessWidget {
  final double thickness;
  final Color? color;
  final double? height;
  final double? indent;
  final double? endIndent;

  const AppDivider({
    super.key,
    this.thickness = 0.3,
    this.color,
    this.height = 0,
    this.indent,
    this.endIndent,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      thickness: thickness,
      height: height,
      color: color,
      indent: indent,
      endIndent: endIndent,
    );
  }
}

/// Divisor con punto circular para separar elementos
class DotDivider extends StatelessWidget {
  final double size;
  final Color? color;
  final EdgeInsetsGeometry padding;

  const DotDivider({
    super.key,
    this.size = 4.0,
    this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 3),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.black;
    
    return Padding(
      padding: padding,
      child: Icon(
        Icons.circle,
        size: size,
        color: effectiveColor.withValues(alpha: 0.4),
      ),
    );
  }
}
