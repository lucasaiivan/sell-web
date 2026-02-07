
import 'package:flutter/material.dart';

// avatar circular con imagen o texto por defecto de las primeras letras del nombre 
// util para mostrar avatares en items generales de nombres con o sin imagen

class AvatarItem extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const AvatarItem({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 24.0,
    this.backgroundColor,
    this.textStyle,
  });

  String get _initials {
    if (name == null || name!.trim().isEmpty) return '?';
    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? theme.colorScheme.primaryContainer,
      backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
          ? NetworkImage(imageUrl!)
          : null,
      child: (imageUrl == null || imageUrl!.isEmpty)
          ? Text(
              _initials,
              style: textStyle ??
                  TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: radius * 0.8,
                  ),
            )
          : null,
    );
  }
}
