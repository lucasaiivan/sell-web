
import 'package:flutter/material.dart';

// avatar circular con imagen o texto por defecto de 
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
    final hasImageUrl = imageUrl != null && imageUrl!.isNotEmpty;

    // Si no hay URL, mostrar directamente las iniciales
    if (!hasImageUrl) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? theme.colorScheme.primaryContainer,
        child: Text(
          _initials,
          style: textStyle ??
              TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
        ),
      );
    }

    // Si hay URL, intentar cargar la imagen con manejo de errores
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? theme.colorScheme.primaryContainer,
      child: Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            // Imagen cargada exitosamente
            return ClipOval(child: child);
          }
          // Mientras carga, mostrar un indicador o las iniciales
          return Text(
            _initials,
            style: textStyle ??
                TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.8,
                ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Si falla la carga, mostrar las iniciales
          return Text(
            _initials,
            style: textStyle ??
                TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.8,
                ),
          );
        },
      ),
    );
  }
}
